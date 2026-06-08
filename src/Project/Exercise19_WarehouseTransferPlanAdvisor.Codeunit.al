codeunit 80128 "Whse Transfer Plan Advisor"
{
    trigger OnRun()
    var
        TransferCount: Integer;
        HighValueCount: Integer;
        TransferReport: Text;
    begin
        AdviseBinTransfers('BLUE', TransferCount, HighValueCount);
        TransferReport := BuildTransferPlanReport('BLUE', TransferCount, HighValueCount);
    end;

    internal procedure AdviseBinTransfers(SourceLocation: Code[10]; var TransferCount: Integer; var HighValueTransferCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        // Transfer planning: scan BLUE location for items that need to be
        // redistributed to overflow locations based on quantity thresholds.
        // High-value items (Amount > 500) require additional consolidation analysis.
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetRange("Location Code", SourceLocation);
        WorkshopData.SetFilter(Quantity, '>%1', 0);
        WorkshopData.SetFilter("Item No.", '<>%1', '');

        if WorkshopData.FindSet() then
            repeat
                TransferCount += 1;

                if WorkshopData.Amount > 500 then begin
                    WorkshopData.SetRange("Item No.", WorkshopData."Item No.");
                    HighValueTransferCount += 1;
                end;
            until WorkshopData.Next() = 0;
    end;

    local procedure ClassifyTransferUrgency(var WorkshopData: Record "Workshop Data"): Text
    begin
        // Urgency based on quantity vs. amount ratio (proxy for stock velocity)
        if WorkshopData.Quantity = 0 then
            exit('EMPTY');
        if WorkshopData.Amount / WorkshopData.Quantity > 200 then
            exit('HIGH-VALUE');
        if WorkshopData.Quantity > 50 then
            exit('OVERFLOW');
        if WorkshopData.Quantity < 5 then
            exit('LOW-STOCK');
        exit('NORMAL');
    end;

    local procedure GetTargetLocation(Urgency: Text; ItemNo: Code[20]): Code[10]
    begin
        // Route to appropriate overflow/staging location based on urgency class
        case Urgency of
            'HIGH-VALUE':
                exit('VAULT');      // Secure storage for expensive items
            'OVERFLOW':
                exit('WAREHOUSE2'); // Secondary warehouse for bulk overflow
            'LOW-STOCK':
                exit('RESERVE');    // Reserve location — triggers replenishment
            'EMPTY':
                exit('');           // No transfer needed
            else
                exit('MAIN');       // Default redistribution bin
        end;
    end;

    local procedure ValidateTransferEligibility(var WorkshopData: Record "Workshop Data"): Boolean
    begin
        // Items are transfer-eligible if:
        // 1. Not flagged as non-transferable (Text Field 1 <> 'NO-MOVE')
        // 2. Quantity is above zero
        // 3. Document No. exists (linked to a source document)
        if WorkshopData."Text Field 1" = 'NO-MOVE' then
            exit(false);
        if WorkshopData.Quantity <= 0 then
            exit(false);
        if WorkshopData."Document No." = '' then
            exit(false);
        exit(true);
    end;

    internal procedure BuildTransferPlanReport(SourceLocation: Code[10]; TransferCount: Integer; HighValueCount: Integer): Text
    var
        Builder: TextBuilder;
        NormalCount: Integer;
    begin
        NormalCount := TransferCount - HighValueCount;
        Builder.Append('=== Warehouse Transfer Plan — ' + SourceLocation + ' — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Total transfer candidates: ' + Format(TransferCount));
        Builder.AppendLine();
        Builder.Append('  High-value (>500): ' + Format(HighValueCount) + ' → routed to VAULT');
        Builder.AppendLine();
        Builder.Append('  Standard: ' + Format(NormalCount) + ' → routed to WAREHOUSE2/MAIN');
        Builder.AppendLine();
        if HighValueCount > 50 then
            Builder.Append('⚠ High-value volume exceeds VAULT capacity — escalate to warehouse manager.');
        exit(Builder.ToText());
    end;
}
