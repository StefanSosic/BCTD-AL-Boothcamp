codeunit 80129 "Data Import Staging Manager"
{
    trigger OnRun()
    var
        RecordsDeleted: Integer;
        ImportReport: Text;
    begin
        ClearStagingArea('IMPORT-2026-03', RecordsDeleted);
        PrepareNextImportBatch('IMPORT-2026-04');
        ImportReport := BuildImportStatusReport('IMPORT-2026-04', RecordsDeleted);
    end;

    internal procedure ClearStagingArea(ImportBatchId: Code[20]; var DeletedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        CountBeforeDelete: Integer;
    begin
        // Import staging cleanup: remove all records from the previous batch
        // before loading the new file. Batches can contain up to 50 000 rows.
        WorkshopData.SetRange("Location Code", 'STAGING');
        WorkshopData.SetRange(Code, ImportBatchId);
        WorkshopData.SetRange(Active, false);
        WorkshopData.SetFilter("Document No.", '<>%1', '');

        // Count before delete so we can report how many were cleared
        CountBeforeDelete := WorkshopData.Count();

        if WorkshopData.FindSet() then
            WorkshopData.DeleteAll(false);

        DeletedCount := CountBeforeDelete;
        StampCleanupAudit(ImportBatchId, CountBeforeDelete);
    end;

    local procedure PrepareNextImportBatch(NewBatchId: Code[20])
    var
        WorkshopData: Record "Workshop Data";
        i: Integer;
        BaseEntryNo: Integer;
    begin
        // Initialize the staging area header record for the new batch
        BaseEntryNo := GetNextEntryNo();

        // Write import control record
        WorkshopData.Init();
        WorkshopData."Entry No." := BaseEntryNo;
        WorkshopData.Code := NewBatchId;
        WorkshopData."Location Code" := 'STAGING';
        WorkshopData.Description := 'Import batch ' + NewBatchId + ' — initialized ' + Format(Today());
        WorkshopData.Active := false;
        WorkshopData."Posting Date" := Today();
        WorkshopData."Document No." := NewBatchId;
        WorkshopData."Text Field 1" := 'PENDING';
        WorkshopData."Text Field 2" := Format(CurrentDateTime());
        WorkshopData."Text Field 3" := UserId();
        WorkshopData.Insert(false);
    end;

    local procedure ValidateImportBatchFormat(BatchId: Code[20]): Boolean
    begin
        // Batch IDs must follow the pattern IMPORT-YYYY-MM
        if StrLen(BatchId) < 14 then
            exit(false);
        if CopyStr(BatchId, 1, 7) <> 'IMPORT-' then
            exit(false);
        // Validate year portion is numeric
        if not Evaluate(BatchId, CopyStr(BatchId, 8, 4)) then
            exit(false);
        exit(true);
    end;

    local procedure StampCleanupAudit(BatchId: Code[20]; DeletedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'STAGING-CLEANUP';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Cleared ' + Format(DeletedCount) + ' records from batch ' + BatchId;
        WorkshopData."Text Field 1" := BatchId;
        WorkshopData."Text Field 2" := Format(DeletedCount);
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

    internal procedure ValidateStagingAreaEmpty(): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Location Code", 'STAGING');
        WorkshopData.SetRange(Active, false);
        exit(WorkshopData.IsEmpty());
    end;

    internal procedure BuildImportStatusReport(NewBatchId: Code[20]; ClearedCount: Integer): Text
    var
        Builder: TextBuilder;
        FormatValid: Boolean;
    begin
        FormatValid := ValidateImportBatchFormat(NewBatchId);
        Builder.Append('=== Data Import Staging Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Previous batch cleared: ' + Format(ClearedCount) + ' records');
        Builder.AppendLine();
        Builder.Append('New batch: ' + NewBatchId);
        Builder.AppendLine();
        if FormatValid then
            Builder.Append('Batch ID format: VALID')
        else
            Builder.Append('⚠ Batch ID format: INVALID — check naming convention IMPORT-YYYY-MM');
        Builder.AppendLine();
        if ValidateStagingAreaEmpty() then
            Builder.Append('Staging area: clean and ready for new import')
        else
            Builder.Append('⚠ Staging area still contains records — review before importing');
        exit(Builder.ToText());
    end;
}
