codeunit 80143 "Inventory Stock Dashboard Rfsh"
{
    trigger OnRun()
    var
        Summary: Text;
        StockLines: Integer;
    begin
        // Dashboard refresh: aggregate stock levels per item and location
        // for the warehouse overview page. Called every 60 seconds by a
        // background session. Heavy concurrent write load from warehouse.
        BuildStockSummary(Summary, StockLines);
        PublishDashboardMetrics(Summary, StockLines);
    end;

    internal procedure BuildStockSummary(var Summary: Text; var StockLines: Integer)
    var
        WorkshopData: Record "Workshop Data";
        Builder: TextBuilder;
        TotalQty: Decimal;
        TotalValue: Decimal;
        ItemQty: Decimal;
        ItemValue: Decimal;
        CurrentItem: Code[20];
        CurrentLocation: Code[10];
    begin
        WorkshopData.SetCurrentKey("Item No.", "Location Code");
        WorkshopData.SetFilter(Quantity, '>%1', 0);
        WorkshopData.SetLoadFields("Item No.", "Location Code", Quantity, "Line Amount");

        if WorkshopData.FindSet() then begin
            CurrentItem := WorkshopData."Item No.";
            CurrentLocation := WorkshopData."Location Code";
            repeat
                if (WorkshopData."Item No." <> CurrentItem) or
                   (WorkshopData."Location Code" <> CurrentLocation) then begin
                    Builder.Append(
                        FormatStockLine(CurrentItem, CurrentLocation, ItemQty, ItemValue));
                    Builder.AppendLine();
                    StockLines += 1;
                    CurrentItem := WorkshopData."Item No.";
                    CurrentLocation := WorkshopData."Location Code";
                    ItemQty := 0;
                    ItemValue := 0;
                end;
                ItemQty += WorkshopData.Quantity;
                ItemValue += WorkshopData."Line Amount";
                TotalQty += WorkshopData.Quantity;
                TotalValue += WorkshopData."Line Amount";
            until WorkshopData.Next() = 0;

            // Flush last group
            if CurrentItem <> '' then begin
                Builder.Append(
                    FormatStockLine(CurrentItem, CurrentLocation, ItemQty, ItemValue));
                Builder.AppendLine();
                StockLines += 1;
            end;
        end;

        Builder.Append(BuildFooter(StockLines, TotalQty, TotalValue));
        Summary := Builder.ToText();
    end;

    local procedure FormatStockLine(
        ItemNo: Code[20]; LocationCode: Code[10];
        Qty: Decimal; Value: Decimal): Text
    begin
        exit(ItemNo + '|' + LocationCode + '|' +
             Format(Qty, 0, '<Integer>') + '|' +
             Format(Value, 0, '<Precision,2:2><Standard Format,0>'));
    end;

    local procedure BuildFooter(Lines: Integer; TotalQty: Decimal; TotalValue: Decimal): Text
    begin
        exit('TOTAL|' + Format(Lines) + ' items|Qty:' +
             Format(TotalQty) + '|Val:' + Format(TotalValue));
    end;

    local procedure PublishDashboardMetrics(Summary: Text; StockLines: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Description :=
            CopyStr('DASHBOARD_REFRESH|Lines:' + Format(StockLines), 1, 100);
        WorkshopData."Posting Date" := Today();
        WorkshopData."Location Code" := 'DASHBOARD';
        WorkshopData.Active := true;
        WorkshopData.Insert(false);
    end;

    local procedure GetNextEntryNo(): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then
            exit(WorkshopData."Entry No." + 1);
        exit(1);
    end;
}
