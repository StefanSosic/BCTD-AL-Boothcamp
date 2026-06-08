codeunit 80141 "Item Qty Replenishment Monitor"
{
    trigger OnRun()
    var
        LowStockList: List of [Text];
        CheckedCount: Integer;
        MonitorReport: Text;
    begin
        FindLowStockItems(LowStockList, CheckedCount);
        MonitorReport := BuildMonitorReport(LowStockList, CheckedCount);
        StampMonitorAudit(CheckedCount, LowStockList.Count());
    end;

    internal procedure FindLowStockItems(var LowStockList: List of [Text]; var CheckedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        ReorderPoint: Decimal;
    begin
        // Replenishment monitor: scans all active workshop items to identify those
        // below their reorder point. Called daily by the scheduler at 03:00.
        // This query only reads Item No. and Quantity — yet every row requires a
        // key lookup because Quantity is not in the "Item No." index leaf pages.

        WorkshopData.SetCurrentKey("Item No.");
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Item No.", '<>%1', '');
        WorkshopData.SetLoadFields("Item No.", Quantity, "Customer No.", "Location Code");

        if WorkshopData.FindSet() then
            repeat
                CheckedCount += 1;
                ReorderPoint := GetReorderPoint(WorkshopData);
                if WorkshopData.Quantity < ReorderPoint then
                    LowStockList.Add(
                        WorkshopData."Item No." + ' | ' +
                        'Qty: ' + Format(WorkshopData.Quantity) + ' | ' +
                        'Reorder at: ' + Format(ReorderPoint) + ' | ' +
                        'Deficit: ' + Format(ReorderPoint - WorkshopData.Quantity) + ' | ' +
                        'Loc: ' + WorkshopData."Location Code"
                    );
            until WorkshopData.Next() = 0;
    end;

    local procedure GetReorderPoint(var WorkshopData: Record "Workshop Data"): Decimal
    begin
        // Reorder policy: premium customers get tighter stock buffer
        if WorkshopData."Customer No." <> '' then
            exit(25);

        case WorkshopData."Item No."[1] of
            'S':
                exit(5);   // Service items — low buffer
            'C':
                exit(30);  // Consumables — higher buffer
            else
                exit(20);  // Standard items
        end;
    end;

    local procedure ClassifyUrgency(Deficit: Decimal): Text
    begin
        if Deficit > 100 then exit('CRITICAL');
        if Deficit > 50 then exit('HIGH');
        if Deficit > 20 then exit('MEDIUM');
        exit('LOW');
    end;

    local procedure StampMonitorAudit(CheckedCount: Integer; LowStockCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'REPLENISHMENT';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Replenishment check — ' + Format(CheckedCount) + ' items, ' + Format(LowStockCount) + ' low';
        WorkshopData."Text Field 1" := Format(CheckedCount);
        WorkshopData."Text Field 2" := Format(LowStockCount);
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

    internal procedure BuildMonitorReport(LowStockList: List of [Text]; CheckedCount: Integer): Text
    var
        Builder: TextBuilder;
        Line: Text;
        Deficit: Decimal;
        CriticalCount: Integer;
    begin
        foreach Line in LowStockList do begin
            if Evaluate(Deficit, SelectStr(4, Line.Replace(' | ', ',').Replace('Deficit: ', ''))) then
                if ClassifyUrgency(Deficit) = 'CRITICAL' then
                    CriticalCount += 1;
        end;

        Builder.Append('=== Inventory Replenishment Monitor — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Items checked: ' + Format(CheckedCount));
        Builder.AppendLine();
        Builder.Append('Items below reorder point: ' + Format(LowStockList.Count()));
        Builder.AppendLine();
        Builder.Append('Critical shortages: ' + Format(CriticalCount));
        Builder.AppendLine();
        Builder.Append('--- Low stock items ---');
        Builder.AppendLine();
        foreach Line in LowStockList do begin
            Builder.Append('  ' + Line);
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;
}
