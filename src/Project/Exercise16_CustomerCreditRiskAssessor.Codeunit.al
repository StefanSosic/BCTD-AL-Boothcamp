codeunit 80125 "Customer Credit Risk Assessor"
{
    trigger OnRun()
    var
        HighRiskCustomers: List of [Text];
        ReviewCount: Integer;
        CreditReport: Text;
    begin
        IdentifyHighRiskCustomers(HighRiskCustomers, ReviewCount);
        CreditReport := BuildCreditRiskReport(HighRiskCustomers);
        StampCreditRiskAudit(ReviewCount);
    end;

    internal procedure IdentifyHighRiskCustomers(var HighRiskList: List of [Text]; var ReviewCount: Integer)
    var
        Customer: Record Customer;
        RiskCategory: Text;
        CreditUtilisation: Decimal;
    begin
        // Credit risk assessment: identify customers at HIGH or CRITICAL risk
        // Run daily by the credit control team. Slow on databases with 50 000+ customers
        // because of the FlowField filter.
        Customer.SetLoadFields("No.", Name, "Credit Limit (LCY)", Balance,
            "Customer Posting Group", Blocked, "Salesperson Code", "Country/Region Code");
        Customer.SetFilter("Customer Posting Group", '<>%1', '');
        Customer.SetRange(Blocked, Customer.Blocked::" ");

        Customer.SetFilter(Balance, '>%1', 0);

        if Customer.FindSet() then
            repeat
                if Customer."Credit Limit (LCY)" > 0 then begin
                    CreditUtilisation := Customer.Balance / Customer."Credit Limit (LCY)" * 100;
                    RiskCategory := ClassifyRisk(CreditUtilisation);
                    if RiskCategory in ['HIGH', 'CRITICAL'] then begin
                        HighRiskList.Add(
                            Customer."No." + '|' +
                            Customer.Name + '|' +
                            RiskCategory + '|' +
                            Format(Customer.Balance, 0, '<Precision,2:2><Standard Format,0>') + '|' +
                            Format(Round(CreditUtilisation, 0.1)) + '%'
                        );
                        ReviewCount += 1;
                    end;
                end;
            until Customer.Next() = 0;
    end;

    local procedure ClassifyRisk(UtilisationPct: Decimal): Text
    begin
        // Credit utilisation thresholds agreed with CFO (Q1 policy review)
        if UtilisationPct >= 100 then
            exit('CRITICAL')    // Over limit — block further sales
        else
            if UtilisationPct >= 85 then
                exit('HIGH')    // Alert credit controller
            else
                if UtilisationPct >= 65 then
                    exit('MEDIUM')  // Watch list
                else
                    exit('LOW');
    end;

    local procedure GetRiskActionRequired(RiskCategory: Text): Text
    begin
        case RiskCategory of
            'CRITICAL':
                exit('Block new orders. Immediate CFO approval required.');
            'HIGH':
                exit('Notify credit controller. Restrict order value to €500.');
            'MEDIUM':
                exit('Monitor weekly. Salesperson informed.');
            else
                exit('No action required.');
        end;
    end;

    local procedure StampCreditRiskAudit(HighRiskCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'CREDIT-RISK-AUDIT';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Credit risk assessment — ' + Format(HighRiskCount) + ' high/critical';
        WorkshopData."Text Field 1" := Format(HighRiskCount);
        WorkshopData."Text Field 2" := Format(Today());
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

    internal procedure BuildCreditRiskReport(HighRiskList: List of [Text]): Text
    var
        Builder: TextBuilder;
        Line: Text;
        Parts: List of [Text];
    begin
        Builder.Append('=== Customer Credit Risk Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('High/Critical risk customers: ' + Format(HighRiskList.Count()));
        Builder.AppendLine();
        foreach Line in HighRiskList do begin
            Parts := Line.Split('|');
            Builder.Append('  ' + Parts.Get(1) + '  ' + Parts.Get(2) +
                           '  Balance: ' + Parts.Get(4) +
                           '  Utilisation: ' + Parts.Get(5) +
                           '  Risk: ' + Parts.Get(3));
            Builder.AppendLine();
            Builder.Append('    → ' + GetRiskActionRequired(Parts.Get(3)));
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;
}
