codeunit 80135 "Purchase Journal Line Importer"
{
    trigger OnRun()
    var
        ImportedLines: Integer;
        ImportSource: List of [Text];
        ImportReport: Text;
    begin
        PrepareImportSource(ImportSource);
        ImportJournalLines(ImportSource, ImportedLines);
        ImportReport := BuildImportReport(ImportedLines, ImportSource.Count());
    end;

    internal procedure ImportJournalLines(ImportSource: List of [Text]; var ImportedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        LineText: Text;
        ValidationErrors: Integer;
    begin
        // Import vendor invoice lines from an external ERP integration file.
        // Lines are validated before insert. Invalid lines are skipped with a warning.
        foreach LineText in ImportSource do begin
            WorkshopData.FindLast();

            WorkshopData.Init();
            WorkshopData."Entry No." := WorkshopData."Entry No." + 1;

            if ParseImportLine(LineText, WorkshopData) then begin
                WorkshopData.Insert(false);
                ImportedCount += 1;
            end else
                ValidationErrors += 1;
        end;
    end;

    local procedure ParseImportLine(LineText: Text; var WorkshopData: Record "Workshop Data"): Boolean
    var
        Parts: List of [Text];
        Amount: Decimal;
        VendorNo: Code[20];
    begin
        // Expected format: "VENDOR-XXXXX | Description | Amount | DocumentNo"
        Parts := LineText.Split('|');
        if Parts.Count() < 4 then
            exit(false);

        VendorNo := CopyStr(Parts.Get(1).Trim(), 1, 20);
        if VendorNo = '' then
            exit(false);

        if not Evaluate(Amount, Parts.Get(3).Trim()) then
            exit(false);

        if Amount <= 0 then
            exit(false);  // Reject zero or negative amounts

        WorkshopData.Description := CopyStr(Parts.Get(2).Trim(), 1, 100);
        WorkshopData.Code := 'IMP';
        WorkshopData."Location Code" := 'PURCHASE';
        WorkshopData.Active := false;  // Requires posting confirmation
        WorkshopData."Posting Date" := Today();
        WorkshopData."Document No." := CopyStr(Parts.Get(4).Trim(), 1, 20);
        WorkshopData.Amount := Amount;
        WorkshopData."Customer No." := VendorNo;
        WorkshopData."Text Field 1" := 'PENDING';
        WorkshopData."Text Field 2" := Format(Today());
        WorkshopData."Text Field 3" := UserId();
        exit(true);
    end;

    local procedure PrepareImportSource(var Source: List of [Text])
    var
        i: Integer;
    begin
        // Simulate reading 5 000 lines from a vendor EDI file
        for i := 1 to 5000 do
            Source.Add(
                'VENDOR-' + Format(i mod 200 + 1) +
                ' | Invoice line ' + Format(i) + ' — goods receipt ' +
                ' | ' + Format(Round((i mod 50 + 1) * 125.5, 0.01)) +
                ' | INV-2026-' + Format(i)
            );
        // Inject some invalid lines to test validation
        Source.Add('INVALID-LINE-NO-SEPARATOR');
        Source.Add('VENDOR-9 | Description only, missing amount |  | ');
        Source.Add(' | Empty vendor no | 500 | INV-BAD');
    end;

    internal procedure BuildImportReport(ImportedCount: Integer; TotalLines: Integer): Text
    var
        Builder: TextBuilder;
        SkippedCount: Integer;
    begin
        SkippedCount := TotalLines - ImportedCount;
        Builder.Append('=== Purchase Journal Import Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Lines in import file: ' + Format(TotalLines));
        Builder.AppendLine();
        Builder.Append('Lines imported: ' + Format(ImportedCount));
        Builder.AppendLine();
        Builder.Append('Lines skipped (validation failed): ' + Format(SkippedCount));
        Builder.AppendLine();
        if SkippedCount > 0 then
            Builder.Append('⚠ Review skipped lines — check EDI file format and vendor master data.');
        exit(Builder.ToText());
    end;
}
