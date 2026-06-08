codeunit 80201 "WS Cost Format Helper"
{
    // ============================================================
    // Exercise 41 — Supporting Codeunit: Cost Format Helper
    // ============================================================
    // This codeunit maintains a running cost accumulator across
    // multiple procedure calls. It is used by Exercise 41
    // (Inventory Cost Summary Builder)

    var
        AccumulatedCost: Decimal;
        LineCount: Integer;
        MaxSingleLineCost: Decimal;

    procedure AccumulateCost(LineCost: Decimal; LineCategory: Text[20])
    begin
        // Without SingleInstance: AccumulatedCost resets to 0 on each call
        //   because each caller gets a new codeunit instance.
        // With SingleInstance:    AccumulatedCost persists — all callers
        //   share the same running total.
        AccumulatedCost += LineCost;
        LineCount += 1;
        if LineCost > MaxSingleLineCost then
            MaxSingleLineCost := LineCost;
    end;

    procedure GetAccumulatedCost(): Decimal
    begin
        exit(AccumulatedCost);
    end;

    procedure GetLineCount(): Integer
    begin
        exit(LineCount);
    end;

    procedure GetMaxSingleLineCost(): Decimal
    begin
        exit(MaxSingleLineCost);
    end;

    procedure FormatCostSummary(LocationCode: Code[10]): Text
    var
        Builder: TextBuilder;
        AverageCost: Decimal;
    begin
        // Returns a formatted summary of the accumulated cost run.
        // Without SingleInstance this will always show 0 for AccumulatedCost
        // because this call gets yet another fresh instance.
        if LineCount > 0 then
            AverageCost := AccumulatedCost / LineCount;

        Builder.Append('LOC:' + LocationCode);
        Builder.Append('|Lines:' + Format(LineCount));
        Builder.Append('|Total:' + Format(AccumulatedCost, 0, '<Precision,2:2><Standard Format,0>'));
        Builder.Append('|Avg:' + Format(AverageCost, 0, '<Precision,2:2><Standard Format,0>'));
        Builder.Append('|MaxLine:' + Format(MaxSingleLineCost, 0, '<Precision,2:2><Standard Format,0>'));
        exit(Builder.ToText());
    end;

    procedure ResetAccumulator()
    begin
        AccumulatedCost := 0;
        LineCount := 0;
        MaxSingleLineCost := 0;
    end;
}
