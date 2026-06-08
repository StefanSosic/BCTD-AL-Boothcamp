codeunit 80139 "Whse Movement Entry Creator"
{
    trigger OnRun()
    var
        MovementCount: Integer;
        RunReport: Text;
    begin
        CreateBinMovements('BIN-A01', 'ITEM-1000', MovementCount);
        CreateBinMovements('BIN-B02', 'ITEM-2000', MovementCount);
        CreateBinMovements('BIN-C03', 'ITEM-3000', MovementCount);
        RunReport := BuildMovementReport(MovementCount);
    end;

    internal procedure CreateBinMovements(BinCode: Code[20]; ItemNo: Code[20]; var MovementCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        EntryNo: Integer;
        i: Integer;
    begin
        // For each bin transfer request, create one movement entry per
        // quantity unit-of-measure tier (small / medium / large pallet).
        // Entry No. must be unique — collision here is a data integrity bug.
        EntryNo := GetNextEntryNo();

        for i := 1 to 10 do begin
            WorkshopData.Init();
            WorkshopData."Entry No." := EntryNo;
            WorkshopData.Code := BinCode;
            WorkshopData."Item No." := ItemNo;
            WorkshopData."Location Code" := 'WAREHOUSE';
            WorkshopData."Document No." := BuildMovementDocNo(BinCode, EntryNo);
            WorkshopData.Quantity := GetTierQuantity(i);
            WorkshopData."Unit Price" := GetTierUnitPrice(ItemNo, i);
            WorkshopData."Line Amount" := WorkshopData.Quantity * WorkshopData."Unit Price";
            WorkshopData.Amount := WorkshopData."Line Amount";
            WorkshopData."Posting Date" := Today();
            WorkshopData.Active := true;
            WorkshopData.Description := 'Bin movement: ' + BinCode + ' tier ' + Format(i);
            WorkshopData."Text Field 1" := GetTierLabel(i);
            WorkshopData."Text Field 2" := UserId();
            WorkshopData."Text Field 3" := Format(CurrentDateTime());

            if WorkshopData.Insert(false) then
                MovementCount += 1;

            EntryNo += 1;
        end;
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

    local procedure BuildMovementDocNo(BinCode: Code[20]; EntryNo: Integer): Code[20]
    begin
        exit(CopyStr('MOV-' + BinCode + '-' + Format(EntryNo), 1, 20));
    end;

    local procedure GetTierQuantity(TierIndex: Integer): Decimal
    begin
        case TierIndex mod 3 of
            0:
                exit(100);  // Large pallet
            1:
                exit(50);   // Medium pallet
            else
                exit(10); // Small pallet / single pick
        end;
    end;

    local procedure GetTierUnitPrice(ItemNo: Code[20]; TierIndex: Integer): Decimal
    begin
        // Price tiers based on item category and quantity break
        exit(Round((StrLen(ItemNo) + TierIndex) * 12.5, 0.01));
    end;

    local procedure GetTierLabel(TierIndex: Integer): Text
    begin
        case TierIndex mod 3 of
            0:
                exit('LARGE');
            1:
                exit('MEDIUM');
            else
                exit('SMALL');
        end;
    end;

    internal procedure BuildMovementReport(MovementCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== Warehouse Movement Creation Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Entries created: ' + Format(MovementCount));
        Builder.AppendLine();
        Builder.Append('Operator: ' + UserId());
        Builder.AppendLine();
        exit(Builder.ToText());
    end;
}
