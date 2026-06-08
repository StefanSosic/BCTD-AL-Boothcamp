codeunit 80150 "WS Compliance Validator"
{
    trigger OnRun()
    var
        ProcessedCount: Integer;
        AuditLog: Text;
    begin
        // Year-end regulatory compliance validation batch.
        // Processes all active high-value sales transactions posted
        // in the current year to ensure they meet regulatory exposure limits.
        // Compliance subscriber performs cumulative exposure cross-checks
        // per customer, querying the full year-to-date transaction history.

        ProcessedCount := ValidateComplianceBatch();
        AuditLog := BuildComplianceAuditLog(ProcessedCount);
        LogComplianceRun(AuditLog, ProcessedCount);
    end;

    internal procedure ValidateComplianceBatch(): Integer
    var
        WorkshopData: Record "Workshop Data";
        ComplianceSubs: Codeunit "WS Compliance Subscriber";
        ProcessedCount: Integer;
        ComplianceThreshold: Decimal;
    begin
        ComplianceThreshold := 10000;
        ProcessedCount := 0;

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Customer No.", '<>%1', '');
        WorkshopData.SetFilter("Posting Date",
            '>=%1&<=%2',
            CalcDate('<-CY>', Today()),
            Today());

        BindSubscription(ComplianceSubs);

        if WorkshopData.FindSet(true) then
            repeat
                WorkshopData."Text Field 3" := CopyStr('PROCESSED|' + Format(Today()), 1, 100);
                WorkshopData.Modify(true);  // Triggers OnBeforeModify — subscriber fires for ALL rows
                ProcessedCount += 1;
            until WorkshopData.Next() = 0;

        UnbindSubscription(ComplianceSubs);

        exit(ProcessedCount);
    end;

    local procedure BuildComplianceAuditLog(ProcessedCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== COMPLIANCE VALIDATION AUDIT ===');
        Builder.AppendLine();
        Builder.Append('Run: ' + Format(CurrentDateTime()));
        Builder.AppendLine();
        Builder.Append('Rows Processed: ' + Format(ProcessedCount));
        Builder.AppendLine();
        Builder.Append('Compliance Threshold: 10,000.00');
        Builder.AppendLine();
        Builder.Append('Pattern: ALWAYS-BOUND (anti-pattern)');
        Builder.AppendLine();
        Builder.Append('Impact: Subscriber fired for ALL rows, including non-qualifying ones.');
        exit(Builder.ToText());
    end;

    local procedure LogComplianceRun(AuditLog: Text; ProcessedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then;
        WorkshopData.Init();
        WorkshopData."Entry No." := WorkshopData."Entry No." + 1;
        WorkshopData.Description := CopyStr('COMPLIANCE_RUN|' + Format(Today()), 1, 100);
        WorkshopData.Amount := ProcessedCount;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Active := true;
        WorkshopData.Insert(false);
    end;
}
