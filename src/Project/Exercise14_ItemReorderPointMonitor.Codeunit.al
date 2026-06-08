codeunit 80123 "Item Reorder Point Monitor"
{
    trigger OnRun()
    var
        BelowReorderCount: Integer;
        CriticalItems: List of [Text];
        ReplenishReport: Text;
    begin
        ScanReorderPoints(BelowReorderCount, CriticalItems);
        ReplenishReport := GetCriticalItemsSummary();
    end;

    internal procedure ScanReorderPoints(var BelowReorderCount: Integer; var CriticalItems: List of [Text])
    var
        WorkshopData: Record "Workshop Data";
        ReorderThreshold: Integer;
        CriticalThreshold: Integer;
        WarningThreshold: Integer;
    begin
        ReorderThreshold := 10;    // Items with qty < 10 need to be reordered
        CriticalThreshold := 3;    // Items with qty ≤ 3 are critically low
        WarningThreshold := 7;     // Items with qty 4–7 are at warning level

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Quantity, '<%1', ReorderThreshold);
        WorkshopData.SetFilter("Item No.", '<>%1', '');
        WorkshopData.SetFilter("Location Code", '<>CONFIG&<>AUDIT&<>STAGING');

        if WorkshopData.FindFirst() then
            repeat
                BelowReorderCount += 1;

                if WorkshopData.Quantity <= CriticalThreshold then
                    CriticalItems.Add(
                        BuildReplenishmentLine(WorkshopData, 'CRITICAL')
                    )
                else
                    if WorkshopData.Quantity <= WarningThreshold then
                        CriticalItems.Add(
                            BuildReplenishmentLine(WorkshopData, 'WARNING')
                        );
            until WorkshopData.Next() = 0;
    end;

    local procedure BuildReplenishmentLine(var WorkshopData: Record "Workshop Data"; Severity: Text): Text
    var
        SuggestedOrderQty: Decimal;
    begin
        SuggestedOrderQty := CalculateSuggestedOrderQuantity(WorkshopData);
        exit(
            '[' + Severity + '] ' +
            WorkshopData."Item No." + ' @ ' +
            WorkshopData."Location Code" + ' — ' +
            'Stock: ' + Format(WorkshopData.Quantity) +
            ' | Suggest reorder: ' + Format(SuggestedOrderQty) +
            ' | Last doc: ' + WorkshopData."Document No."
        );
    end;

    local procedure CalculateSuggestedOrderQuantity(var WorkshopData: Record "Workshop Data"): Decimal
    var
        HistoricalAvgQty: Decimal;
        LeadTimeDays: Integer;
        SafetyStock: Decimal;
    begin
        // Simplified EOQ/safety-stock calculation for demo purposes
        // In production this would reference an Item card and planning parameters
        LeadTimeDays := 14;  // Assumed vendor lead time

        // Historical average based on unit price as proxy (lower-priced = higher volume)
        if WorkshopData."Unit Price" > 100 then
            HistoricalAvgQty := 5
        else
            if WorkshopData."Unit Price" > 20 then
                HistoricalAvgQty := 20
            else
                HistoricalAvgQty := 50;

        SafetyStock := Round(HistoricalAvgQty * LeadTimeDays / 30, 1);  // 14-day safety stock
        exit(SafetyStock * 2);  // Order 2× safety stock to avoid immediate reorder
    end;

    internal procedure GetCriticalItemsSummary(): Text
    var
        Count: Integer;
        Items: List of [Text];
        Builder: TextBuilder;
        Item: Text;
    begin
        ScanReorderPoints(Count, Items);
        Builder.Append('=== Replenishment Alert Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Items below reorder point: ' + Format(Count));
        Builder.AppendLine();
        Builder.Append('Critical / Warning items requiring action:');
        Builder.AppendLine();
        foreach Item in Items do begin
            Builder.Append('  ' + Item);
            Builder.AppendLine();
        end;
        if Items.Count() = 0 then
            Builder.Append('  (none — all stock levels satisfactory)');
        exit(Builder.ToText());
    end;
}
