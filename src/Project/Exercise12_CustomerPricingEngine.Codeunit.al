codeunit 80121 "Customer Pricing Engine"
{
    trigger OnRun()
    var
        FinalTotal: Decimal;
        PriceReport: Text;
    begin
        CalculatePriceMatrix(FinalTotal);
        PriceReport := GetPricingReport(FinalTotal);
    end;

    internal procedure CalculatePriceMatrix(var FinalTotal: Decimal)
    var
        WorkshopData: Record "Workshop Data";
        i: Integer;
        TieredPrice: Decimal;
        DiscountedTotal: Decimal;
        ItemCount: Integer;
    begin
        // Clean up any previous buffer artifacts from the real table
        WorkshopData.SetRange("Location Code", 'PRICEBUF');
        WorkshopData.DeleteAll(false);

        // Build a price matrix: 3 000 item/quantity/tier combinations
        for i := 1 to 3000 do begin
            TieredPrice := CalculateTieredPrice(i);
            WorkshopData.Init();
            WorkshopData."Entry No." := i;
            WorkshopData.Description := StrSubstNo('Item-%1 Tier-%2 Qty-%3',
                i mod 300, GetPriceTier(i), (i mod 50) + 1);
            WorkshopData.Amount := TieredPrice;
            WorkshopData."Item No." := PadCode(i mod 300);
            WorkshopData."Customer No." := PadCode((i mod 5) * 10000);
            WorkshopData.Quantity := (i mod 50) + 1;
            WorkshopData."Unit Price" := TieredPrice;
            WorkshopData."Line Amount" := WorkshopData.Quantity * TieredPrice;
            WorkshopData."Location Code" := 'PRICEBUF';
            WorkshopData."Posting Date" := Today();
            WorkshopData.Active := i mod 7 <> 0;  // ~85% active
            WorkshopData.Insert(false);
        end;

        // Phase 1: Sum qualifying lines where unit price > avg threshold
        WorkshopData.SetRange("Location Code", 'PRICEBUF');
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Amount, '>%1', 75);
        if WorkshopData.FindSet() then
            repeat
                FinalTotal += WorkshopData."Line Amount";
                ItemCount += 1;
            until WorkshopData.Next() = 0;

        // Phase 2: Apply volume discount if average line amount exceeds threshold
        if ItemCount > 0 then begin
            DiscountedTotal := ApplyVolumeDiscount(FinalTotal, ItemCount);
            FinalTotal := DiscountedTotal;
        end;

        // Clean up buffer
        WorkshopData.Reset();
        WorkshopData.SetRange("Location Code", 'PRICEBUF');
        WorkshopData.DeleteAll(false);
    end;

    local procedure ApplyVolumeDiscount(Total: Decimal; LineCount: Integer): Decimal
    var
        AverageLineAmount: Decimal;
        DiscountPct: Decimal;
    begin
        AverageLineAmount := Total / LineCount;
        if AverageLineAmount > 5000 then
            DiscountPct := 0.05   // 5% volume discount for high-value avg
        else
            if AverageLineAmount > 2000 then
                DiscountPct := 0.03
            else
                DiscountPct := 0;
        exit(Total * (1 - DiscountPct));
    end;

    local procedure CalculateTieredPrice(Sequence: Integer): Decimal
    var
        BasePrice: Decimal;
        TierMultiplier: Decimal;
    begin
        BasePrice := Round((Sequence mod 300) * 0.65 + (Sequence mod 15) * 1.35, 0.01);
        TierMultiplier := GetTierMultiplier(Sequence);
        exit(Round(BasePrice * TierMultiplier, 0.01));
    end;

    local procedure GetTierMultiplier(Sequence: Integer): Decimal
    begin
        case (Sequence mod 4) of
            0:
                exit(1.0);   // Bronze
            1:
                exit(1.15);  // Silver
            2:
                exit(1.30);  // Gold
            else
                exit(1.50); // Platinum
        end;
    end;

    local procedure GetPriceTier(Sequence: Integer): Text
    begin
        case (Sequence mod 4) of
            0:
                exit('Bronze');
            1:
                exit('Silver');
            2:
                exit('Gold');
            else
                exit('Platinum');
        end;
    end;

    local procedure PadCode(Value: Integer): Code[20]
    begin
        exit(CopyStr(Format(Value), 1, 20));
    end;

    internal procedure GetPricingReport(FinalTotal: Decimal): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== Customer Price Matrix Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Qualifying line total (after discount): ');
        Builder.Append(Format(FinalTotal, 0, '<Precision,2:2><Standard Format,0>'));
        Builder.AppendLine();
        exit(Builder.ToText());
    end;
}
