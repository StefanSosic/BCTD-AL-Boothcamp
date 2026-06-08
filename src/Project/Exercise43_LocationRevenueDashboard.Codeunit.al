codeunit 80153 "Location Revenue Dashboard"
{
    trigger OnRun()
    var
        SummaryResult: Record "Workshop Data" temporary;
        LocationCount: Integer;
    begin
        // Period-end revenue dashboard.
        // Aggregates total Line Amount per Location Code.
        // Must complete within 30 seconds for the scheduled job time window.
        BuildRevenueDashboard(SummaryResult, LocationCount);

        WriteDashboardResults(SummaryResult, LocationCount);
    end;

    internal procedure BuildRevenueDashboard(
        var SummaryResult: Record "Workshop Data" temporary;
        var LocationCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        CurrentLocation: Code[10];
        AccumulatedRevenue: Decimal;
        LineCount: Integer;
        EntrySeq: Integer;
    begin
        //    For 100,000 active entries: 100,000 SQL rows transferred to NST.
        WorkshopData.SetCurrentKey("Location Code");
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Line Amount", '>%1', 0);
        WorkshopData.SetLoadFields("Location Code", "Line Amount", "Entry No.");

        if WorkshopData.FindSet() then begin
            CurrentLocation := WorkshopData."Location Code";
            repeat
                if WorkshopData."Location Code" <> CurrentLocation then begin
                    // Location changed — flush accumulated totals
                    FlushLocationSummary(
                        SummaryResult, CurrentLocation,
                        AccumulatedRevenue, LineCount,
                        EntrySeq, LocationCount);
                    CurrentLocation := WorkshopData."Location Code";
                    AccumulatedRevenue := 0;
                    LineCount := 0;
                end;
                AccumulatedRevenue += WorkshopData."Line Amount";
                LineCount += 1;
            until WorkshopData.Next() = 0;

            // Flush last location
            if LineCount > 0 then
                FlushLocationSummary(
                    SummaryResult, CurrentLocation,
                    AccumulatedRevenue, LineCount,
                    EntrySeq, LocationCount);
        end;
    end;

    local procedure FlushLocationSummary(
        var SummaryResult: Record "Workshop Data" temporary;
        LocationCode: Code[10];
        Revenue: Decimal;
        LineCount: Integer;
        var EntrySeq: Integer;
        var LocationCount: Integer)
    begin
        EntrySeq += 1;
        SummaryResult.Init();
        SummaryResult."Entry No." := EntrySeq;
        SummaryResult."Location Code" := LocationCode;
        SummaryResult."Line Amount" := Revenue;
        SummaryResult.Quantity := LineCount;
        SummaryResult.Description := CopyStr('Revenue for ' + LocationCode, 1, 100);
        SummaryResult.Insert();
        LocationCount += 1;
    end;

    local procedure WriteDashboardResults(
            var SummaryResult: Record "Workshop Data" temporary;
            LocationCount: Integer)
    var
        Output: Record "Workshop Data";
    begin
        // Persist summary results to the real Workshop Data table for reporting.
        if SummaryResult.FindSet() then
            repeat
                Output.Init();
                Output."Entry No." := GetNextEntryNo();
                Output."Location Code" := SummaryResult."Location Code";
                Output."Line Amount" := SummaryResult."Line Amount";
                Output.Quantity := SummaryResult.Quantity;
                Output.Description := SummaryResult.Description;
                Output."Posting Date" := Today();
                Output.Active := false;
                Output.Insert(false);
            until SummaryResult.Next() = 0;
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
