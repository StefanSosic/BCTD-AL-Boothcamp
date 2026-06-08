codeunit 80114 "Sales Budget Variance Analyzer"
{
    trigger OnRun()
    var
        SalespersonTotals: Dictionary of [Code[20], Decimal];
        BudgetVariances: Dictionary of [Code[20], Decimal];
        ReportText: Text;
    begin
        CalculateSalespersonTotals(SalespersonTotals);
        ComputeBudgetVariances(SalespersonTotals, BudgetVariances);
        ReportText := GetVarianceReport();
    end;

    internal procedure CalculateSalespersonTotals(var SalespersonTotals: Dictionary of [Code[20], Decimal])
    var
        WorkshopSalesData: Record "Workshop Sales Data";
        SalespersonCodes: List of [Code[20]];
        SalespersonCode: Code[20];
        PeriodTotal: Decimal;
        CurrentYear: Integer;
        PeriodStart: Date;
        PeriodEnd: Date;
    begin
        CurrentYear := Date2DMY(Today(), 3);
        PeriodStart := DMY2Date(1, 1, CurrentYear);
        PeriodEnd := DMY2Date(31, 12, CurrentYear);

        // Active salesperson roster for Q-review
        SalespersonCodes.Add('JR');
        SalespersonCodes.Add('PS');
        SalespersonCodes.Add('LM');
        SalespersonCodes.Add('DC');
        SalespersonCodes.Add('AB');
        SalespersonCodes.Add('MK');

        foreach SalespersonCode in SalespersonCodes do begin
            WorkshopSalesData.Reset();
            WorkshopSalesData.SetRange("Salesperson Code", SalespersonCode);
            WorkshopSalesData.SetRange("Posting Date", PeriodStart, PeriodEnd);
            WorkshopSalesData.SetFilter("Line Amount", '>%1', 0);

            PeriodTotal := 0;
            WorkshopSalesData.SetLoadFields("Line Amount");
            if WorkshopSalesData.FindSet() then
                repeat
                    PeriodTotal += WorkshopSalesData."Line Amount";
                until WorkshopSalesData.Next() = 0;

            SalespersonTotals.Set(SalespersonCode, PeriodTotal);
        end;
    end;

    local procedure ComputeBudgetVariances(SalespersonTotals: Dictionary of [Code[20], Decimal]; var BudgetVariances: Dictionary of [Code[20], Decimal])
    var
        Budgets: Dictionary of [Code[20], Decimal];
        SalespersonCode: Code[20];
        Actual: Decimal;
        Budget: Decimal;
    begin
        // Static annual budgets (in a real project these come from a budget table)
        Budgets.Set('JR', 350000);
        Budgets.Set('PS', 420000);
        Budgets.Set('LM', 300000);
        Budgets.Set('DC', 390000);
        Budgets.Set('AB', 280000);
        Budgets.Set('MK', 310000);

        foreach SalespersonCode in SalespersonTotals.Keys() do begin
            Actual := SalespersonTotals.Get(SalespersonCode);
            if Budgets.ContainsKey(SalespersonCode) then
                Budget := Budgets.Get(SalespersonCode)
            else
                Budget := 0;
            BudgetVariances.Set(SalespersonCode, Actual - Budget);
        end;
    end;

    internal procedure GetVarianceReport(): Text
    var
        SalespersonTotals: Dictionary of [Code[20], Decimal];
        BudgetVariances: Dictionary of [Code[20], Decimal];
        Builder: TextBuilder;
        SalespersonCode: Code[20];
        Actual: Decimal;
        Variance: Decimal;
        VariancePct: Decimal;
        Budget: Decimal;
    begin
        CalculateSalespersonTotals(SalespersonTotals);
        ComputeBudgetVariances(SalespersonTotals, BudgetVariances);

        Builder.Append('=== Sales Budget Variance Report — FY' + Format(Date2DMY(Today(), 3)) + ' ===');
        Builder.AppendLine();
        Builder.Append(PadRight('Salesperson', 14) + PadRight('Actual', 14) + PadRight('Variance', 14) + 'Status');
        Builder.AppendLine();

        foreach SalespersonCode in SalespersonTotals.Keys() do begin
            Actual := SalespersonTotals.Get(SalespersonCode);
            Variance := BudgetVariances.Get(SalespersonCode);
            Budget := Actual - Variance;
            if Budget > 0 then
                VariancePct := Round(Variance / Budget * 100, 0.1)
            else
                VariancePct := 0;

            Builder.Append(
                PadRight(SalespersonCode, 14) +
                PadRight(Format(Round(Actual, 1)), 14) +
                PadRight(Format(Round(Variance, 1)), 14) +
                ClassifyVariance(VariancePct)
            );
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;

    local procedure ClassifyVariance(VariancePct: Decimal): Text
    begin
        if VariancePct >= 5 then exit('ABOVE BUDGET');
        if VariancePct >= -2 then exit('ON TRACK');
        if VariancePct >= -10 then exit('BELOW TARGET');
        exit('CRITICAL SHORTFALL');
    end;

    local procedure PadRight(Value: Text; Width: Integer): Text
    begin
        while StrLen(Value) < Width do
            Value += ' ';
        exit(Value);
    end;

    local procedure NewLine(): Text
    begin
        exit(Format(10));
    end;
}
