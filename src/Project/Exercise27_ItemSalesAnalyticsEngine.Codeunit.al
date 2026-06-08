codeunit 80136 "Item Sales Analytics Engine"
{
    trigger OnRun()
    var
        AnalyticsResult: List of [Text];
        AnalyticsReport: Text;
    begin
        BuildItemSalesAnalytics(AnalyticsResult);
        AnalyticsReport := FormatAnalyticsReport(AnalyticsResult);
        StampAnalyticsAudit(AnalyticsResult.Count());
    end;

    internal procedure BuildItemSalesAnalytics(var Results: List of [Text])
    var
        WorkshopData: Record "Workshop Data";
        WorkshopSalesData: Record "Workshop Sales Data";
        TotalSales: Decimal;
        TotalQty: Decimal;
        LineCount: Integer;
        ResultLine: Text;
        AvgSaleValue: Decimal;
    begin
        // Sales analytics: for each active item in Workshop Data, compute:
        // - total sales amount, total quantity, average line value
        // from Workshop Sales Data. Used by the sales controller for monthly
        // performance review (runs for all items on the first workday of each month).

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Item No.", '<>%1', '');
        if WorkshopData.FindSet() then
            repeat
                TotalSales := 0;
                TotalQty := 0;
                LineCount := 0;

                WorkshopSalesData.SetRange("Item No.", WorkshopData."Item No.");
                if WorkshopSalesData.FindSet() then
                    repeat
                        TotalSales += WorkshopSalesData."Line Amount";
                        TotalQty += WorkshopSalesData.Quantity;
                        LineCount += 1;
                    until WorkshopSalesData.Next() = 0;

                if LineCount > 0 then begin
                    AvgSaleValue := TotalSales / LineCount;
                    ResultLine :=
                        WorkshopData."Item No." + ' | ' +
                        'Sales: ' + Format(TotalSales, 0, '<Precision,2:2><Standard Format,0>') + ' | ' +
                        'Qty: ' + Format(TotalQty) + ' | ' +
                        'Tier: ' + GetItemPerformanceTier(TotalSales);
                    Results.Add(ResultLine);
                end;
            until WorkshopData.Next() = 0;
    end;

    local procedure GetItemPerformanceTier(TotalSales: Decimal): Text
    begin
        if TotalSales >= 100000 then exit('PLATINUM');
        if TotalSales >= 50000 then exit('GOLD');
        if TotalSales >= 20000 then exit('SILVER');
        if TotalSales >= 5000 then exit('BRONZE');
        exit('NONE');
    end;

    local procedure StampAnalyticsAudit(ItemCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'ANALYTICS-RUN';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Item analytics run — ' + Format(ItemCount) + ' items analysed';
        WorkshopData."Text Field 1" := Format(ItemCount);
        WorkshopData."Text Field 2" := Format(CurrentDateTime());
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

    internal procedure FormatAnalyticsReport(Results: List of [Text]): Text
    var
        Builder: TextBuilder;
        Line: Text;
        PlatinumCount: Integer;
        GoldCount: Integer;
    begin
        foreach Line in Results do begin
            if Line.Contains('PLATINUM') then PlatinumCount += 1;
            if Line.Contains('GOLD') then GoldCount += 1;
        end;

        Builder.Append('=== Item Sales Analytics Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Items with sales data: ' + Format(Results.Count()));
        Builder.AppendLine();
        Builder.Append('Platinum tier: ' + Format(PlatinumCount) + '  Gold tier: ' + Format(GoldCount));
        Builder.AppendLine();
        Builder.Append('Top item detail lines:');
        Builder.AppendLine();
        foreach Line in Results do begin
            Builder.Append('  ' + Line);
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;
}
