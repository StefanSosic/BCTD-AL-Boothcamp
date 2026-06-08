codeunit 80120 "Payment Tolerance Auditor"
{
    trigger OnRun()
    var
        ViolationCount: Integer;
        TotalAmount: Decimal;
        AuditReport: Text;
    begin
        AuditPaymentTolerances(ViolationCount, TotalAmount);
        AuditReport := BuildAuditReport(ViolationCount, TotalAmount);
    end;

    internal procedure AuditPaymentTolerances(var ViolationCount: Integer; var TotalViolationAmount: Decimal)
    var
        WorkshopData: Record "Workshop Data";
        ToleranceLower: Decimal;
        ToleranceUpper: Decimal;
        MaxTolerancePct: Decimal;
        ViolationsByCategory: Dictionary of [Text, Integer];
    begin
        // Payment tolerance rules: flag entries between 50 and 500 LCY
        // that are within 5% of a round hundred (indicator of rounding manipulation)
        ToleranceLower := 50;
        ToleranceUpper := 500;
        MaxTolerancePct := 5;

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Amount, '%1..%2', ToleranceLower, ToleranceUpper);
        WorkshopData.SetFilter("Customer No.", '<>%1', '');
        WorkshopData.SetFilter("Document No.", '<>%1', '');
        WorkshopData.SetFilter("Posting Date", '>=%1', CalcDate('<-12M>', Today()));

        if not WorkshopData.IsEmpty() then
            if WorkshopData.FindSet() then
                repeat
                    if IsToleranceViolation(WorkshopData, MaxTolerancePct) then begin
                        ViolationCount += 1;
                        TotalViolationAmount += WorkshopData.Amount;
                        AccumulateViolationCategory(WorkshopData, ViolationsByCategory);
                    end;
                until WorkshopData.Next() = 0;
    end;

    local procedure IsToleranceViolation(var WorkshopData: Record "Workshop Data"; MaxPct: Decimal): Boolean
    var
        NearestHundred: Decimal;
        DeviationPct: Decimal;
    begin
        // A violation is when the amount is within MaxPct% of a round hundred
        // (e.g. 299.97 is within 0.01% of 300 — suspicious rounding)
        NearestHundred := Round(WorkshopData.Amount / 100, 1) * 100;
        if NearestHundred = 0 then
            exit(false);
        DeviationPct := Abs(WorkshopData.Amount - NearestHundred) / NearestHundred * 100;
        exit(DeviationPct < MaxPct);
    end;

    local procedure AccumulateViolationCategory(var WorkshopData: Record "Workshop Data"; var Categories: Dictionary of [Text, Integer])
    var
        Category: Text;
        CurrentCount: Integer;
    begin
        Category := GetViolationCategory(WorkshopData.Amount);
        if Categories.ContainsKey(Category) then begin
            CurrentCount := Categories.Get(Category);
            Categories.Set(Category, CurrentCount + 1);
        end else
            Categories.Add(Category, 1);
    end;

    local procedure GetViolationCategory(Amount: Decimal): Text
    begin
        if Amount < 100 then exit('MICRO');
        if Amount < 200 then exit('SMALL');
        if Amount < 400 then exit('MEDIUM');
        exit('LARGE');
    end;

    local procedure BuildAuditReport(ViolationCount: Integer; TotalAmount: Decimal): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== Payment Tolerance Audit — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Violations found: ' + Format(ViolationCount));
        Builder.AppendLine();
        Builder.Append('Total flagged amount: ' + Format(TotalAmount, 0, '<Precision,2:2><Standard Format,0>'));
        Builder.AppendLine();
        if ViolationCount > 10 then
            Builder.Append('⚠ High violation count — escalate to finance controller.');
        exit(Builder.ToText());
    end;
}
