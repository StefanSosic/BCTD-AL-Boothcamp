codeunit 80134 "Fiscal Period Date Collector"
{
    trigger OnRun()
    var
        PeriodsText: Text;
    begin
        PeriodsText := CollectOpenFiscalPeriodDates();
    end;

    internal procedure CollectOpenFiscalPeriodDates(): Text
    var
        WorkshopSalesData: Record "Workshop Sales Data";
        TempDateStore: Record "Workshop Data" temporary;
        Builder: TextBuilder;
        NextEntryNo: Integer;
        WindowStart: Date;
        WindowEnd: Date;
    begin
        // Collect all distinct posting dates from the last 3 months for open
        // fiscal period reporting, returned as a comma-separated list of dates.
        WindowStart := CalcDate('<-3M>', Today());
        WindowEnd := Today();

        WorkshopSalesData.SetFilter("Posting Date", '%1..%2', WindowStart, WindowEnd);
        WorkshopSalesData.SetFilter("Line Amount", '>%1', 0);
        WorkshopSalesData.SetCurrentKey("Posting Date");

        // Use a temporary table as a lookup to collect distinct posting dates
        if WorkshopSalesData.FindSet() then
            repeat
                TempDateStore.SetRange("Posting Date", WorkshopSalesData."Posting Date");
                if TempDateStore.IsEmpty() then begin
                    NextEntryNo += 1;
                    TempDateStore.Init();
                    TempDateStore."Entry No." := NextEntryNo;
                    TempDateStore."Posting Date" := WorkshopSalesData."Posting Date";
                    TempDateStore.Insert(false);
                end;
            until WorkshopSalesData.Next() = 0;

        // Build the comma-separated result from the temp store, in Posting Date order
        TempDateStore.Reset();
        TempDateStore.SetCurrentKey("Posting Date");
        if TempDateStore.FindSet() then
            repeat
                if Builder.Length() > 0 then
                    Builder.Append(',');
                Builder.Append(Format(TempDateStore."Posting Date"));
            until TempDateStore.Next() = 0;

        exit(Builder.ToText());
    end;
}
