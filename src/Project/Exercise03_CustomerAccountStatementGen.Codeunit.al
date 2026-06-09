codeunit 80112 "Customer Account Statement Gen"
{
    trigger OnRun()
    var
        StatementLines: List of [Text];
        SummaryText: Text;
    begin
        GenerateStatements(StatementLines);
        SummaryText := BuildStatementSummary(StatementLines);
    end;

    internal procedure GenerateStatements(var StatementLines: List of [Text])
    var
        Customer: Record Customer;
        OverdueCount: Integer;
        TotalBalance: Decimal;
        TotalLCYBalance: Decimal;
        ProcessedCount: Integer;
        PostingGroup: Code[20];
    begin
        // Generate statements for all active non-blocked customers with a posting group
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        Customer.SetFilter("Customer Posting Group", '<>%1', '');
        Customer.SetFilter("Country/Region Code", '<>%1', '');

        if Customer.FindSet() then
            repeat
                Customer.CalcFields(Balance, "Balance (LCY)");
                ProcessedCount += 1;

                if Customer.Balance <> 0 then begin
                    PostingGroup := Customer."Customer Posting Group";
                    StatementLines.Add(BuildStatementLine(Customer, PostingGroup));
                    TotalBalance += Customer.Balance;
                    TotalLCYBalance += Customer."Balance (LCY)";
                    if IsOverdueBalance(Customer) then
                        OverdueCount += 1;
                end;
            until Customer.Next() = 0;

        // Append summary line
        StatementLines.Add(
            'TOTAL|ALL|' +
            FormatDecimal(TotalBalance) + '|' +
            FormatDecimal(TotalLCYBalance) + '|' +
            'Processed: ' + Format(ProcessedCount) + ' Overdue: ' + Format(OverdueCount)
        );
    end;

    local procedure BuildStatementLine(var Customer: Record Customer; PostingGroup: Code[20]): Text
    var
        Category: Text;
        CurrencyHint: Text;
    begin
        Category := GetBalanceCategory(Customer.Balance);
        if Customer."Currency Code" <> '' then
            CurrencyHint := ' [' + Customer."Currency Code" + ']'
        else
            CurrencyHint := ' [LCY]';

        exit(
            Customer."No." + '|' +
            Customer.Name + '|' +
            FormatDecimal(Customer.Balance) + CurrencyHint + '|' +
            FormatDecimal(Customer."Balance (LCY)") + '|' +
            Category + '|' +
            PostingGroup + '|' +
            Customer."Country/Region Code"
        );
    end;

    local procedure IsOverdueBalance(var Customer: Record Customer): Boolean
    begin
        if Customer.Balance <= 0 then
            exit(false);
        if Customer."Payment Terms Code" = '' then
            exit(true);
        if (Customer."Credit Limit (LCY)" > 0) and (Customer."Balance (LCY)" > Customer."Credit Limit (LCY)") then
            exit(true);
        exit(false);
    end;

    local procedure GetBalanceCategory(Balance: Decimal): Text
    begin
        if Balance > 500000 then
            exit('CRITICAL')
        else
            if Balance > 100000 then
                exit('HIGH')
            else
                if Balance > 10000 then
                    exit('MEDIUM')
                else
                    exit('LOW');
    end;

    local procedure BuildStatementSummary(StatementLines: List of [Text]): Text
    var
        Builder: TextBuilder;
        Line: Text;
    begin
        Builder.Append('=== Account Statement Export — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Lines generated: ' + Format(StatementLines.Count()));
        Builder.AppendLine();
        // Last line is always the TOTAL summary
        if StatementLines.Count() > 0 then begin
            StatementLines.Get(StatementLines.Count(), Line);
            Builder.Append(Line);
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;

    local procedure FormatDecimal(Value: Decimal): Text
    begin
        exit(Format(Value, 0, '<Precision,2:2><Standard Format,0>'));
    end;
}
