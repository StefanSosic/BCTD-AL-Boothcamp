codeunit 80126 "Order Eligibility Handler"
{
    trigger OnRun()
    var
        EligibleCount: Integer;
        IneligibleCount: Integer;
        EligibilityReport: Text;
    begin
        ProcessIncomingOrderBatch(EligibleCount, IneligibleCount);
        EligibilityReport := BuildEligibilityReport(EligibleCount, IneligibleCount);
    end;

    internal procedure EvaluateExpressEligibility(CustomerNo: Code[20]; OrderAmount: Decimal): Boolean
    var
        IsEligible: Boolean;
    begin
        // Business rule: express delivery (same-day dispatch) is offered when
        // either the customer is in our Priority tier OR the order exceeds twice
        // the historical average order value.

        IsEligible := IsPriorityCustomer(CustomerNo) or IsHighValueOrder(OrderAmount);
        exit(IsEligible);
    end;

    local procedure ProcessIncomingOrderBatch(var EligibleCount: Integer; var IneligibleCount: Integer)
    var
        WorkshopSalesData: Record "Workshop Sales Data";
        IsEligible: Boolean;
        EnrichedAmount: Decimal;
    begin
        // Process all unconfirmed orders in the staging queue
        WorkshopSalesData.SetFilter("Customer No.", '<>%1', '');
        WorkshopSalesData.SetFilter("Line Amount", '>%1', 0);
        if WorkshopSalesData.FindSet() then
            repeat
                // Enriched amount = line amount adjusted for current discount tier
                EnrichedAmount := EnrichOrderAmount(WorkshopSalesData);
                IsEligible := EvaluateExpressEligibility(
                    WorkshopSalesData."Customer No.", EnrichedAmount);

                if IsEligible then begin
                    EligibleCount += 1;
                    MarkOrderExpressEligible(WorkshopSalesData."Entry No.");
                end else
                    IneligibleCount += 1;
            until WorkshopSalesData.Next() = 0;
    end;

    local procedure EnrichOrderAmount(var SalesData: Record "Workshop Sales Data"): Decimal
    var
        DiscountedAmount: Decimal;
    begin
        // Apply tier-based price enrichment for eligibility calculation
        // (wholesale vs retail pricing tiers — simplified for demo)
        DiscountedAmount := SalesData."Line Amount" * (1 - SalesData."Discount %" / 100);
        if SalesData.Quantity > 100 then
            DiscountedAmount *= 1.1;  // Volume surcharge for large orders
        exit(Round(DiscountedAmount, 0.01));
    end;

    local procedure IsPriorityCustomer(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        // Cheap check: single Get on primary key — fast index seek
        if Customer.Get(CustomerNo) then
            exit(
                (Customer."Customer Posting Group" <> '') and
                (Customer.Blocked = Customer.Blocked::" ") and
                (Customer."Credit Limit (LCY)" >= 10000)
            );
        exit(false);
    end;

    local procedure IsHighValueOrder(OrderAmount: Decimal): Boolean
    var
        WorkshopSalesData: Record "Workshop Sales Data";
        AverageOrderValue: Decimal;
        TotalAmount: Decimal;
        TotalCount: Integer;
    begin
        if WorkshopSalesData.FindSet() then
            repeat
                TotalAmount += WorkshopSalesData."Line Amount";
                TotalCount += 1;
            until WorkshopSalesData.Next() = 0;

        if TotalCount > 0 then
            AverageOrderValue := TotalAmount / TotalCount;

        exit(OrderAmount > AverageOrderValue * 2);
    end;

    local procedure MarkOrderExpressEligible(EntryNo: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        // Flag the corresponding staging record for express dispatch
        if WorkshopData.Get(EntryNo) then begin
            WorkshopData."Text Field 1" := 'EXPRESS-ELIGIBLE';
            WorkshopData."Text Field 2" := Format(CurrentDateTime());
            WorkshopData.Modify(false);
        end;
    end;

    internal procedure BuildEligibilityReport(EligibleCount: Integer; IneligibleCount: Integer): Text
    var
        Builder: TextBuilder;
        TotalProcessed: Integer;
        EligibilityRate: Decimal;
    begin
        TotalProcessed := EligibleCount + IneligibleCount;
        if TotalProcessed > 0 then
            EligibilityRate := Round(EligibleCount / TotalProcessed * 100, 0.1);

        Builder.Append('=== Express Order Eligibility Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Orders processed: ' + Format(TotalProcessed));
        Builder.AppendLine();
        Builder.Append('Express eligible: ' + Format(EligibleCount) +
                       ' (' + Format(EligibilityRate) + '%)');
        Builder.AppendLine();
        Builder.Append('Standard delivery: ' + Format(IneligibleCount));
        exit(Builder.ToText());
    end;
}
