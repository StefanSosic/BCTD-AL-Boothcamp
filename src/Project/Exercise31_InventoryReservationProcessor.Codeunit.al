codeunit 80140 "Inventory Reservation Proc"
{
    trigger OnRun()
    var
        ReservationLog: List of [Text];
        ReportText: Text;
    begin
        ProcessReservations(ReservationLog);
        ReportText := BuildReservationReport(ReservationLog);
        StampReservationAudit(ReservationLog.Count());
    end;

    internal procedure ProcessReservations(var ReservationLog: List of [Text])
    var
        WorkshopData: Record "Workshop Data";
        EligibleEntries: List of [Integer];
        EligibleEntry: Integer;
        SkippedCount: Integer;
    begin
        // Step 1: Validation / read phase — identify eligible entries
        // This can process many thousands of rows (full warehouse dataset)
        // and may take seconds. Holding a table lock here is very expensive.

        WorkshopData.LockTable(true);

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Quantity, '>%1', 0);
        WorkshopData.SetFilter("Location Code", 'BLUE|RED|GREEN|SILVER');
        WorkshopData.SetFilter("Posting Date", '>=%1', CalcDate('<-CM>', Today()));

        if WorkshopData.FindSet() then
            repeat
                if IsReservationEligible(WorkshopData) then
                    EligibleEntries.Add(WorkshopData."Entry No.")
                else
                    SkippedCount += 1;
            until WorkshopData.Next() = 0;

        // Step 2: Apply reservations — the write phase
        ApplyReservations(EligibleEntries, ReservationLog);
    end;

    local procedure IsReservationEligible(var WorkshopData: Record "Workshop Data"): Boolean
    begin
        // Eligibility rules:
        // - Quantity must be positive (enough stock)
        // - Must be from current or previous month (no stale entries)
        // - Must have a valid customer assigned
        // - Item must be flagged as reservable (stored in Text Field 1 = 'Y')
        exit(
            (WorkshopData.Quantity >= 1) and
            (WorkshopData."Customer No." <> '') and
            (WorkshopData."Text Field 1" = 'Y') and
            (WorkshopData."Posting Date" >= CalcDate('<-1M>', WorkshopData."Posting Date"))
        );
    end;

    local procedure ApplyReservations(EntryNos: List of [Integer]; var ReservationLog: List of [Text])
    var
        WorkshopData: Record "Workshop Data";
        EntryNo: Integer;
        ReservedQty: Decimal;
    begin
        foreach EntryNo in EntryNos do begin
            if WorkshopData.Get(EntryNo) then begin
                ReservedQty := WorkshopData.Quantity;
                WorkshopData.Active := false;   // Mark as reserved
                WorkshopData.Code := 'RESERVED';
                WorkshopData."Text Field 2" := UserId();
                WorkshopData."Text Field 3" := Format(CurrentDateTime());
                WorkshopData.Modify(false);
                ReservationLog.Add(
                    'Reserved entry ' + Format(EntryNo) +
                    ' — item ' + WorkshopData."Item No." +
                    ' — qty ' + Format(ReservedQty)
                );
            end;
        end;
    end;

    local procedure StampReservationAudit(ReservedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'RESERVATION-RUN';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Reservation batch — ' + Format(ReservedCount) + ' entries reserved';
        WorkshopData."Text Field 1" := Format(ReservedCount);
        WorkshopData."Text Field 2" := Format(CurrentDateTime());
        WorkshopData."Text Field 3" := UserId();
        WorkshopData."Location Code" := 'AUDIT';
        WorkshopData.Insert(false);
    end;

    local procedure GetNextEntryNo(): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetLoadFields("Entry No.");
        if WorkshopData.FindLast() then
            exit(WorkshopData."Entry No." + 1);
        exit(1);
    end;

    internal procedure BuildReservationReport(ReservationLog: List of [Text]): Text
    var
        Builder: TextBuilder;
        Line: Text;
    begin
        Builder.Append('=== Inventory Reservation Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Total reservations applied: ' + Format(ReservationLog.Count()));
        Builder.AppendLine();
        foreach Line in ReservationLog do begin
            Builder.Append('  ' + Line);
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;
}
