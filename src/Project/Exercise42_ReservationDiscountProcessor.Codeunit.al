codeunit 80152 "Reservation Discount Processor"
{
    trigger OnRun()
    var
        WorkshopData: Record "Workshop Data";
        UpdatedCount: Integer;
        SkippedCount: Integer;
    begin
        // Batch job: apply promotional discount to active reservation entries
        // that have a non-zero Unit Price and are posted in the current fiscal year.
        // This runs as a job queue entry during peak processing hours.
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Unit Price", '>%1', 0);
        WorkshopData.SetFilter("Posting Date", '%1..%2', CalcDate('<-CY>', Today()), Today());
        WorkshopData.SetLoadFields(
            "Entry No.", "Unit Price", "Line Amount", "Quantity", Active);

        WorkshopData.LockTable();

        if WorkshopData.FindSet() then
            repeat
                ApplyReservationDiscount(WorkshopData, UpdatedCount, SkippedCount);
            until WorkshopData.Next() = 0;

        WriteDiscountSummary(UpdatedCount, SkippedCount);
    end;

    local procedure ApplyReservationDiscount(
        var WorkshopData: Record "Workshop Data";
        var UpdatedCount: Integer;
        var SkippedCount: Integer)
    var
        DiscountRate: Decimal;
    begin
        // Apply a 5% promotional discount to Unit Price.
        // Skip entries already at minimum price threshold.
        DiscountRate := 0.95; // 5% discount
        if WorkshopData."Unit Price" * DiscountRate < 10 then begin
            SkippedCount += 1;
            exit;
        end;

        WorkshopData."Unit Price" := Round(WorkshopData."Unit Price" * DiscountRate, 0.01);
        WorkshopData."Line Amount" := Round(
            WorkshopData."Unit Price" * WorkshopData.Quantity, 0.01);
        WorkshopData.Modify(false);
        UpdatedCount += 1;
    end;

    local procedure WriteDiscountSummary(UpdatedCount: Integer; SkippedCount: Integer)
    var
        Summary: Record "Workshop Data";
    begin
        // Write a summary entry documenting the batch run.
        Summary.Init();
        Summary."Entry No." := GetNextEntryNo();
        Summary.Description := CopyStr(
            'Discount batch: Updated=' + Format(UpdatedCount) +
            ' Skipped=' + Format(SkippedCount), 1, 100);
        Summary."Posting Date" := Today();
        Summary.Active := false;
        Summary.Insert(false);
    end;

    local procedure GetNextEntryNo(): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then
            exit(WorkshopData."Entry No." + 1);
        exit(1);
    end;
}
