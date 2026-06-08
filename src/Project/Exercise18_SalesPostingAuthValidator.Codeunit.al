codeunit 80127 "Sales Posting Auth Validator"
{
    trigger OnRun()
    var
        CanPost: Boolean;
        ValidationReport: Text;
        BatchCount: Integer;
    begin
        BatchCount := ValidatePostingBatch(CanPost);
        ValidationReport := BuildValidationReport(CanPost, BatchCount);
    end;

    internal procedure ValidatePostingAuthorization(BatchNo: Code[20]; PostingType: Text): Boolean
    var
        CanPost: Boolean;
    begin
        CanPost := HasPostingPermission(PostingType) and IsOpenPostingPeriod(BatchNo);
        exit(CanPost);
    end;

    local procedure ValidatePostingBatch(var CanPost: Boolean): Integer
    var
        WorkshopData: Record "Workshop Data";
        BatchesChecked: Integer;
        BatchNo: Code[20];
    begin
        // Simulate the daily batch posting validation — checks all pending
        // PURCHASE-type batches (which will all fail permission check)
        WorkshopData.SetRange(Code, 'BATCH-POST');
        WorkshopData.SetRange(Active, false);
        WorkshopData.SetFilter("Document No.", '<>%1', '');
        if WorkshopData.FindSet() then
            repeat
                BatchNo := CopyStr(WorkshopData."Document No.", 1, 20);
                CanPost := ValidatePostingAuthorization(BatchNo, 'PURCHASE');
                BatchesChecked += 1;
            until WorkshopData.Next() = 0;

        // Also check the primary batch
        CanPost := ValidatePostingAuthorization('BATCH-2026-04', 'PURCHASE');
        exit(BatchesChecked + 1);
    end;

    local procedure HasPostingPermission(PostingType: Text): Boolean
    begin
        // Quick permission check — returns false for PURCHASE (only SALES is open this period)
        exit(PostingType = 'SALES');  // Only SALES posting allowed (not PURCHASE)
    end;

    local procedure IsOpenPostingPeriod(BatchNo: Code[20]): Boolean
    var
        WorkshopSalesData: Record "Workshop Sales Data";
        EarliestDate: Date;
        LatestDate: Date;
        DateCount: Integer;
    begin
        if WorkshopSalesData.FindSet() then
            repeat
                if (EarliestDate = 0D) or (WorkshopSalesData."Posting Date" < EarliestDate) then
                    EarliestDate := WorkshopSalesData."Posting Date";
                if WorkshopSalesData."Posting Date" > LatestDate then
                    LatestDate := WorkshopSalesData."Posting Date";
                DateCount += 1;
            until WorkshopSalesData.Next() = 0;

        exit((DateCount > 0) and (BatchNo <> '') and (Today() >= EarliestDate) and (Today() <= LatestDate));
    end;

    local procedure GetPostingDenialReason(PostingType: Text): Text
    begin
        if PostingType = 'PURCHASE' then
            exit('Purchase posting is closed for this period (approval pending CFO sign-off).');
        if PostingType = 'ADJUSTMENT' then
            exit('Adjustment posting requires controller review. Submit via workflow.');
        exit('Posting type not recognized. Contact system administrator.');
    end;

    internal procedure BuildValidationReport(CanPost: Boolean; BatchCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== Posting Authorization Validation — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Batches checked: ' + Format(BatchCount));
        Builder.AppendLine();
        if CanPost then
            Builder.Append('Result: AUTHORIZED — posting may proceed.')
        else begin
            Builder.Append('Result: DENIED');
            Builder.AppendLine();
            Builder.Append('Reason: ' + GetPostingDenialReason('PURCHASE'));
        end;
        exit(Builder.ToText());
    end;
}
