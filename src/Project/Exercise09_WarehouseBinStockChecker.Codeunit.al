codeunit 80118 "Warehouse Bin Stock Checker"
{
    trigger OnRun()
    var
        ItemNos: List of [Code[20]];
        Locations: List of [Code[10]];
        StockFound: Boolean;
        CheckReport: Text;
    begin
        BuildItemAndLocationLists(ItemNos, Locations);
        CheckAllBinsForStock(ItemNos, Locations, StockFound);
        CheckReport := BuildStockCheckReport(ItemNos, Locations);
    end;

    internal procedure CheckAllBinsForStock(ItemNos: List of [Code[20]]; Locations: List of [Code[10]]; var AnyFound: Boolean)
    var
        ItemNo: Code[20];
        LocationCode: Code[10];
        CheckCount: Integer;
    begin
        AnyFound := false;
        foreach ItemNo in ItemNos do
            foreach LocationCode in Locations do begin
                CheckCount += 1;
                if HasStockInBin(ItemNo, LocationCode) then begin
                    AnyFound := true;
                    exit;
                end;
            end;
    end;

    internal procedure HasStockInBin(ItemNo: Code[20]; LocationCode: Code[10]): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Item No.", ItemNo);
        WorkshopData.SetRange("Location Code", LocationCode);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Quantity, '>%1', 0);

        exit(WorkshopData.Count() > 0);
    end;

    internal procedure GetStockCountByBin(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Item No.", ItemNo);
        WorkshopData.SetRange("Location Code", LocationCode);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Quantity, '>%1', 0);
        WorkshopData.CalcSums(Quantity);
        exit(WorkshopData.Quantity);
    end;

    local procedure BuildItemAndLocationLists(var ItemNos: List of [Code[20]]; var Locations: List of [Code[10]])
    begin
        ItemNos.Add('ITEM-1000');
        ItemNos.Add('ITEM-1100');
        ItemNos.Add('ITEM-1200');
        ItemNos.Add('ITEM-2000');
        ItemNos.Add('ITEM-2100');
        Locations.Add('BLUE');
        Locations.Add('RED');
        Locations.Add('GREEN');
        Locations.Add('SILVER');
    end;

    local procedure BuildStockCheckReport(ItemNos: List of [Code[20]]; Locations: List of [Code[10]]): Text
    var
        Builder: TextBuilder;
        ItemNo: Code[20];
        LocationCode: Code[10];
        StockQty: Decimal;
    begin
        Builder.Append('=== Warehouse Bin Stock Check — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append(PadRight('Item', 12) + PadRight('Location', 10) + PadRight('HasStock', 10) + 'Qty');
        Builder.AppendLine();
        foreach ItemNo in ItemNos do
            foreach LocationCode in Locations do begin
                StockQty := GetStockCountByBin(ItemNo, LocationCode);
                Builder.Append(
                    PadRight(ItemNo, 12) +
                    PadRight(LocationCode, 10) +
                    PadRight(Format(StockQty > 0), 10) +
                    Format(StockQty)
                );
                Builder.AppendLine();
            end;
        exit(Builder.ToText());
    end;

    local procedure PadRight(Value: Text; Width: Integer): Text
    begin
        while StrLen(Value) < Width do
            Value += ' ';
        exit(Value);
    end;
}
