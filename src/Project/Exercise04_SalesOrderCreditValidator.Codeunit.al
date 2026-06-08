codeunit 80113 "Sales Order Credit Validator"
{
    trigger OnRun()
    var
        OverLimitCount: Integer;
        RiskReport: Text;
    begin
        ValidateAllCustomerCreditLimits(OverLimitCount);
        RiskReport := BuildRiskReport(OverLimitCount);
    end;

    internal procedure ValidateAllCustomerCreditLimits(var OverLimitCount: Integer)
    var
        Customer: Record Customer;
        RiskScore: Decimal;
        TotalRiskScore: Decimal;
        CustomerCount: Integer;
    begin
        Customer.SetFilter("Credit Limit (LCY)", '>%1', 0);
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        Customer.SetFilter("Customer Posting Group", '<>%1', '');

        if Customer.FindSet() then
            repeat
                CustomerCount += 1;
                if IsCreditLimitExceeded(Customer) then begin
                    OverLimitCount += 1;
                    RiskScore := CalculateRiskScore(Customer);
                    TotalRiskScore += RiskScore;
                    LogCreditViolation(Customer, RiskScore);
                end;
            until Customer.Next() = 0;
    end;

    local procedure IsCreditLimitExceeded(Customer: Record Customer): Boolean
    begin
        Customer.CalcFields("Balance (LCY)");
        exit(Customer."Balance (LCY)" > Customer."Credit Limit (LCY)");
    end;

    local procedure CalculateRiskScore(var Customer: Record Customer): Decimal
    var
        UtilizationPct: Decimal;
        Score: Decimal;
    begin
        // Risk scoring: utilisation over limit, weighted by credit limit size
        if Customer."Credit Limit (LCY)" <= 0 then
            exit(0);

        UtilizationPct := Customer."Balance (LCY)" / Customer."Credit Limit (LCY)" * 100;

        // Higher limits = higher risk weight
        if Customer."Credit Limit (LCY)" > 500000 then
            Score := UtilizationPct * 1.5
        else
            if Customer."Credit Limit (LCY)" > 100000 then
                Score := UtilizationPct * 1.2
            else
                Score := UtilizationPct;

        exit(Round(Score, 0.01));
    end;

    local procedure LogCreditViolation(var Customer: Record Customer; RiskScore: Decimal)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextAuditEntryNo();
        WorkshopData."Customer No." := Customer."No.";
        WorkshopData.Description := 'Credit limit exceeded — Risk: ' + Format(Round(RiskScore, 0.1));
        WorkshopData.Amount := Customer."Balance (LCY)" - Customer."Credit Limit (LCY)";
        WorkshopData.Code := 'CREDIT-VIOL';
        WorkshopData."Location Code" := 'AUDIT';
        WorkshopData."Posting Date" := Today();
        WorkshopData.Active := true;
        if not WorkshopData.Insert(false) then;
    end;

    local procedure GetNextAuditEntryNo(): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Location Code", 'AUDIT');
        if WorkshopData.FindLast() then
            exit(WorkshopData."Entry No." + 1);
        exit(1);
    end;

    local procedure BuildRiskReport(OverLimitCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('Credit Risk Validation — ' + Format(Today()));
        Builder.AppendLine();
        Builder.Append('Customers over credit limit: ' + Format(OverLimitCount));
        Builder.AppendLine();
        if OverLimitCount > 0 then
            Builder.Append('Action required: Review credit holds with AR team.');
        exit(Builder.ToText());
    end;
}
