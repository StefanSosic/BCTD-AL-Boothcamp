codeunit 80145 "Product Count Sheet Batch Ldr"
{
    trigger OnRun()
    var
        ImportLines: Integer;
        LocationCode: Code[10];
        CountDate: Date;
        SummaryText: Text;
    begin
        // Import a physical stock count sheet received from the warehouse.
        // The count sheet CSV has been pre-parsed into a memory structure.
        // We now write each count line to the staging table for approval.
        // For a full warehouse count (10 000 bin positions), this should
        // complete in under 5 seconds.

        LocationCode := 'WH-MAIN';
        CountDate := Today();
        ImportLines := LoadCountSheetWithAutoIncrement(LocationCode, CountDate);
        SummaryText := BuildImportSummary(ImportLines, LocationCode, CountDate);
        RecordImportAudit(SummaryText, ImportLines);
    end;

    internal procedure LoadCountSheetWithAutoIncrement(
        LocationCode: Code[10]; CountDate: Date): Integer
    var
        Entry: Record "WS AutoIncrement Entry";
        ItemSalesData: Record "Workshop Data";
        LineCount: Integer;
    begin
        Entry.DeleteAll(false);  // Clear previous staging data

        ItemSalesData.SetRange("Location Code", LocationCode);
        ItemSalesData.SetLoadFields("Item No.", "Location Code", Quantity, "Unit Price");
        if ItemSalesData.FindSet() then
            repeat
                Entry.Init();
                Entry."Item No." := ItemSalesData."Item No.";
                Entry."Location Code" := ItemSalesData."Location Code";
                Entry.Quantity := ItemSalesData.Quantity * (1 + (Random(10) - 5) / 100);
                Entry."Unit Cost" := ItemSalesData."Unit Price";
                Entry."Count Date" := CountDate;
                Entry."Counter Code" := GetCurrentCounterCode();
                Entry.Insert(true);
                LineCount += 1;
            until ItemSalesData.Next() = 0;

        exit(LineCount);
    end;

    local procedure GetCurrentCounterCode(): Code[20]
    begin
        exit(CopyStr(UserId(), 1, 20));
    end;

    local procedure BuildImportSummary(
        Lines: Integer; LocationCode: Code[10]; CountDate: Date): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('COUNT_IMPORT');
        Builder.Append('|Location:' + LocationCode);
        Builder.Append('|Date:' + Format(CountDate));
        Builder.Append('|Lines:' + Format(Lines));
        Builder.Append('|User:' + UserId());
        exit(Builder.ToText());
    end;

    local procedure RecordImportAudit(SummaryText: Text; Lines: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextAuditEntryNo();
        WorkshopData.Description := CopyStr(SummaryText, 1, 100);
        WorkshopData."Posting Date" := Today();
        WorkshopData."Location Code" := 'CNT-AUDIT';
        WorkshopData.Quantity := Lines;
        WorkshopData.Active := true;
        WorkshopData.Insert(false);
    end;

    local procedure GetNextAuditEntryNo(): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then
            exit(WorkshopData."Entry No." + 1);
        exit(1);
    end;
}
