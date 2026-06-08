codeunit 80151 "Inventory Cost Summary Builder"
{
    trigger OnRun()
    var
        Locations: List of [Code[10]];
        LocationCode: Code[10];
        SummaryLines: Integer;
    begin
        // Inventory cost summary builder for period-end reporting.
        // Collects all active inventory lines from WorkshopData,
        // groups by Location Code, and produces a cost rollup per location.
        // Runs nightly as a job queue entry — must produce accurate totals.
        CollectActiveLocations(Locations);

        foreach LocationCode in Locations do begin
            SummaryLines += BuildLocationCostSummary(LocationCode);
        end;

        WriteGrandTotalEntry(SummaryLines);
    end;

    internal procedure BuildLocationCostSummary(LocationCode: Code[10]): Integer
    var
        WorkshopData: Record "Workshop Data";
        CostHelper: Codeunit "WS Cost Format Helper";
        SummaryText: Text;
        LineCount: Integer;
    begin
        // Reset accumulator for this location's run.
        CostHelper.ResetAccumulator();

        WorkshopData.SetRange("Location Code", LocationCode);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Amount, '>%1', 0);
        WorkshopData.SetLoadFields("Entry No.", "Item No.", Amount, "Unit Price", Quantity, "Location Code");

        if WorkshopData.FindSet() then
            repeat
                ProcessInventoryLine(WorkshopData);
                LineCount += 1;
            until WorkshopData.Next() = 0;

        SummaryText := CostHelper.FormatCostSummary(LocationCode);
        WriteSummaryEntry(LocationCode, SummaryText, CostHelper.GetAccumulatedCost());

        exit(LineCount);
    end;

    internal procedure ProcessInventoryLine(WorkshopData: Record "Workshop Data")
    var
        CostHelper: Codeunit "WS Cost Format Helper";
        LineCost: Decimal;
        LineCategory: Text[20];
    begin
        // Calculates the effective line cost and accumulates it.

        LineCost := WorkshopData.Amount * WorkshopData.Quantity;
        LineCategory := DetermineCategory(WorkshopData."Unit Price");

        CostHelper.AccumulateCost(LineCost, LineCategory);
    end;

    local procedure DetermineCategory(UnitPrice: Decimal): Text[20]
    begin
        // Classify the line by price band for cost analysis.
        case true of
            UnitPrice < 50:
                exit('LOW');
            UnitPrice < 200:
                exit('MID');
            UnitPrice < 1000:
                exit('HIGH');
            else
                exit('PREMIUM');
        end;
    end;

    local procedure CollectActiveLocations(var Locations: List of [Code[10]])
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Location Code", '<>%1', '');
        if WorkshopData.FindSet() then
            repeat
                if not Locations.Contains(WorkshopData."Location Code") then
                    Locations.Add(WorkshopData."Location Code");
            until WorkshopData.Next() = 0;
    end;

    local procedure WriteSummaryEntry(LocationCode: Code[10]; SummaryText: Text; TotalCost: Decimal)
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then;
        WorkshopData.Init();
        WorkshopData."Entry No." := WorkshopData."Entry No." + 1;
        WorkshopData."Location Code" := LocationCode;
        WorkshopData.Description := CopyStr('COST_SUMMARY|' + SummaryText, 1, 100);
        WorkshopData.Amount := TotalCost;  // Will be 0 without SingleInstance!
        WorkshopData."Posting Date" := Today();
        WorkshopData.Active := false;  // Summary markers are inactive
        WorkshopData.Insert(false);
    end;

    local procedure WriteGrandTotalEntry(TotalLines: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then;
        WorkshopData.Init();
        WorkshopData."Entry No." := WorkshopData."Entry No." + 1;
        WorkshopData.Description := CopyStr(
            'GRAND_TOTAL|Lines:' + Format(TotalLines) + '|Run:' + Format(Today()),
            1, 100);
        WorkshopData.Quantity := TotalLines;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Active := false;
        WorkshopData.Insert(false);
    end;
}
