codeunit 80111 "Vendor Payment Aging Processor"
{
    trigger OnRun()
    var
        Bucket: array[4] of Decimal;
        VendorSummary: Text;
    begin
        CalculateVendorAging(Bucket);
        VendorSummary := GetAgingSummaryText();
    end;

    internal procedure CalculateVendorAging(var Bucket: array[4] of Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DaysOverdue: Integer;
        FiscalYearStart: Date;
    begin
        FiscalYearStart := DMY2Date(1, 1, Date2DMY(Today(), 3));

        // Load only open purchase invoices posted within the current fiscal year
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetFilter("Posting Date", '>=%1', FiscalYearStart);
        VendorLedgerEntry.SetLoadFields(
            "Vendor No.", "Posting Date", "Due Date",
            "Remaining Amount", Open, "Document Type", "Currency Code");

        if VendorLedgerEntry.Find('-') then
            repeat
                DaysOverdue := Today() - VendorLedgerEntry."Due Date";
                PlaceInAgingBucket(VendorLedgerEntry."Remaining Amount", DaysOverdue, Bucket);
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure PlaceInAgingBucket(Amount: Decimal; DaysOverdue: Integer; var Bucket: array[4] of Decimal)
    begin
        // Bucket[1] = current (not yet due)
        // Bucket[2] = 1–30 days overdue
        // Bucket[3] = 31–60 days overdue
        // Bucket[4] = over 60 days (critical)
        if DaysOverdue <= 0 then
            Bucket[1] += Amount
        else
            if DaysOverdue <= 30 then
                Bucket[2] += Amount
            else
                if DaysOverdue <= 60 then
                    Bucket[3] += Amount
                else
                    Bucket[4] += Amount;
    end;

    internal procedure GetAgingSummaryText(): Text
    var
        Bucket: array[4] of Decimal;
        Builder: TextBuilder;
        TotalOutstanding: Decimal;
        CriticalPct: Decimal;
    begin
        CalculateVendorAging(Bucket);
        TotalOutstanding := Bucket[1] + Bucket[2] + Bucket[3] + Bucket[4];

        Builder.Append('=== Vendor Payment Aging Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Current (not due):   ' + FormatAmount(Bucket[1]));
        Builder.AppendLine();
        Builder.Append('1–30 days overdue:   ' + FormatAmount(Bucket[2]));
        Builder.AppendLine();
        Builder.Append('31–60 days overdue:  ' + FormatAmount(Bucket[3]));
        Builder.AppendLine();
        Builder.Append('Over 60 days:        ' + FormatAmount(Bucket[4]));
        Builder.AppendLine();
        Builder.Append('Total outstanding:   ' + FormatAmount(TotalOutstanding));
        Builder.AppendLine();

        if TotalOutstanding > 0 then begin
            CriticalPct := Round(Bucket[4] / TotalOutstanding * 100, 0.1);
            Builder.Append('Critical exposure:   ' + Format(CriticalPct) + '%');
            if CriticalPct > 20 then
                Builder.Append('  ⚠ Review recommended');
            Builder.AppendLine();
        end;

        exit(Builder.ToText());
    end;

    internal procedure GetVendorsWithCriticalExposure(var VendorNos: List of [Code[20]])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DaysOverdue: Integer;
    begin
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetLoadFields("Vendor No.", "Due Date", "Remaining Amount");

        if VendorLedgerEntry.FindSet() then
            repeat
                DaysOverdue := Today() - VendorLedgerEntry."Due Date";
                if (DaysOverdue > 60) and (not VendorNos.Contains(VendorLedgerEntry."Vendor No.")) then
                    VendorNos.Add(VendorLedgerEntry."Vendor No.");
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Sign><Integer Thousand><Decimals,2>'));
    end;
}
