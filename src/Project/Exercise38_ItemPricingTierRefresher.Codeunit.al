codeunit 80148 "Item Pricing Tier Refresher"
{
    trigger OnRun()
    var
        PricingResult: Text;
        TierCount: Integer;
        AuditLog: Text;
    begin
        // Multi-step pricing refresh: runs once per hour via job queue.
        // Applies 10 tiered pricing rules over the same WorkshopData set.
        // Each pass re-reads the same active rows and classifies them into a
        // price band. No cross-session freshness is required within a run.
        TierCount := RunPricingTierPipeline(PricingResult);
        AuditLog := BuildPricingAuditLog(PricingResult, TierCount);
        WritePricingResult(AuditLog, TierCount);
    end;

    internal procedure RunPricingTierPipeline(var PipelineResult: Text): Integer
    var
        Builder: TextBuilder;
        Tier: Integer;
        TierMin: Decimal;
        TierMax: Decimal;
        TierLabel: Text;
        TierTotal: Decimal;
        TierLines: Integer;
        GrandTotal: Integer;
    begin
        Builder.Append('PRICING_PIPELINE|Run:' + Format(CurrentDateTime()));
        Builder.AppendLine();

        for Tier := 1 to 10 do begin
            TierMin := (Tier - 1) * 100;
            TierMax := Tier * 100;
            TierLabel := 'TIER_' + Format(Tier);

            Database.SelectLatestVersion();

            RefreshTierPricing(TierMin, TierMax, TierLabel, TierTotal, TierLines);

            Builder.Append(
                TierLabel + '|Min:' + Format(TierMin, 0, '<Precision,2:2><Standard Format,0>') +
                '|Max:' + Format(TierMax, 0, '<Precision,2:2><Standard Format,0>') +
                '|Lines:' + Format(TierLines) +
                '|Total:' + Format(TierTotal, 0, '<Precision,2:2><Standard Format,0>'));
            Builder.AppendLine();
            GrandTotal += TierLines;
        end;

        PipelineResult := Builder.ToText();
        exit(GrandTotal);
    end;

    internal procedure RefreshTierPricing(
        MinUnitPrice: Decimal; MaxUnitPrice: Decimal;
        TierCode: Text;
        var TierTotal: Decimal; var TierLines: Integer)
    var
        WorkshopData: Record "Workshop Data";
        AdjustedPrice: Decimal;
    begin
        TierTotal := 0;
        TierLines := 0;

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetLoadFields("Item No.", "Unit Price", Quantity, "Line Amount", "Customer No.");

        if WorkshopData.FindSet() then
            repeat
                if (WorkshopData."Unit Price" >= MinUnitPrice) and (WorkshopData."Unit Price" <= MaxUnitPrice) then begin
                    AdjustedPrice := ApplyTierDiscount(WorkshopData."Unit Price", TierCode);
                    TierTotal += AdjustedPrice * WorkshopData.Quantity;
                    TierLines += 1;
                end;
            until WorkshopData.Next() = 0;
    end;

    local procedure ApplyTierDiscount(UnitPrice: Decimal; TierCode: Text): Decimal
    var
        DiscountPct: Decimal;
    begin
        // Tier-based discount schedule:
        // TIER_1–3:  5% discount (entry-level pricing)
        // TIER_4–7: 10% discount (volume pricing)
        // TIER_8–10: 15% discount (strategic account pricing)
        case true of
            TierCode in ['TIER_1', 'TIER_2', 'TIER_3']:
                DiscountPct := 0.05;
            TierCode in ['TIER_4', 'TIER_5', 'TIER_6', 'TIER_7']:
                DiscountPct := 0.10;
            else
                DiscountPct := 0.15;
        end;
        exit(UnitPrice * (1 - DiscountPct));
    end;

    local procedure BuildPricingAuditLog(PipelineResult: Text; TierCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== PRICING TIER AUDIT LOG ===');
        Builder.AppendLine();
        Builder.Append('Timestamp: ' + Format(CurrentDateTime()));
        Builder.AppendLine();
        Builder.Append('Total Lines Processed: ' + Format(TierCount));
        Builder.AppendLine();
        Builder.Append('Pipeline Output:');
        Builder.AppendLine();
        Builder.Append(PipelineResult);
        exit(Builder.ToText());
    end;

    local procedure WritePricingResult(AuditLog: Text; TierCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        ResultEntry: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then;
        ResultEntry.Init();
        ResultEntry."Entry No." := WorkshopData."Entry No." + 1;
        ResultEntry.Description := CopyStr('PRICING_PIPELINE_RESULT', 1, 50);
        ResultEntry.Amount := TierCount;
        ResultEntry."Document No." := CopyStr(Format(Today()), 1, 20);
        ResultEntry.Active := true;
        ResultEntry.Insert(false);
    end;
}
