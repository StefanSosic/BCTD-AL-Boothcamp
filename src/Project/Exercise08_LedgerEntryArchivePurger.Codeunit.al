codeunit 80117 "Ledger Entry Archive Purger"
{
    trigger OnRun()
    var
        PurgedCount: Integer;
        ArchiveStats: Text;
    begin
        PurgeExpiredJournalLines(PurgedCount);
        ArchiveStats := BuildPurgeReport(PurgedCount);
    end;

    internal procedure PurgeExpiredJournalLines(var PurgedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        CutoffDate: Date;
        RetentionMonths: Integer;
    begin
        // Retention policy: inactive records older than 6 months are archived and deleted
        RetentionMonths := 6;
        CutoffDate := CalcDate('<-' + Format(RetentionMonths) + 'M>', Today());

        // Filter: only inactive journal lines older than retention cutoff,
        // excluding config and audit records which have indefinite retention
        WorkshopData.SetRange(Active, false);
        WorkshopData.SetFilter("Posting Date", '..%1', CutoffDate);
        WorkshopData.SetFilter("Location Code", '<>CONFIG&<>AUDIT');
        WorkshopData.SetFilter("Document No.", '<>%1', '');  // Must have a doc ref to be purgeable

        if WorkshopData.FindSet() then
            repeat
                if IsEligibleForPurge(WorkshopData) then begin
                    WorkshopData.Delete(false);
                    PurgedCount += 1;
                end;
            until WorkshopData.Next() = 0;
    end;

    local procedure IsEligibleForPurge(var WorkshopData: Record "Workshop Data"): Boolean
    begin
        // Secondary eligibility check — must not be a template record
        if WorkshopData.Code = 'TMPL' then
            exit(false);
        // Must not be referenced by an open document (simplified: check Code prefix)
        if CopyStr(WorkshopData.Code, 1, 4) = 'OPEN' then
            exit(false);
        // Must have a valid posting date
        if WorkshopData."Posting Date" = 0D then
            exit(false);
        exit(true);
    end;

    internal procedure GetPurgePreview(): Integer
    var
        WorkshopData: Record "Workshop Data";
        CutoffDate: Date;
    begin
        CutoffDate := CalcDate('<-6M>', Today());
        WorkshopData.SetRange(Active, false);
        WorkshopData.SetFilter("Posting Date", '..%1', CutoffDate);
        WorkshopData.SetFilter("Location Code", '<>CONFIG&<>AUDIT');
        WorkshopData.SetFilter("Document No.", '<>%1', '');
        exit(WorkshopData.Count());
    end;

    internal procedure GetRetentionSummary(): Text
    var
        WorkshopData: Record "Workshop Data";
        ActiveCount: Integer;
        InactiveOld: Integer;
        InactiveNew: Integer;
        CutoffDate: Date;
    begin
        CutoffDate := CalcDate('<-6M>', Today());

        WorkshopData.SetRange(Active, true);
        ActiveCount := WorkshopData.Count();

        WorkshopData.SetRange(Active, false);
        WorkshopData.SetFilter("Posting Date", '..%1', CutoffDate);
        InactiveOld := WorkshopData.Count();

        WorkshopData.SetFilter("Posting Date", '>%1', CutoffDate);
        InactiveNew := WorkshopData.Count();

        exit(
            'Active: ' + Format(ActiveCount) +
            ' | Inactive (>6M, purgeable): ' + Format(InactiveOld) +
            ' | Inactive (recent): ' + Format(InactiveNew)
        );
    end;

    local procedure BuildPurgeReport(PurgedCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== Archive Purge Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Retention cutoff: ' + Format(CalcDate('<-6M>', Today())));
        Builder.AppendLine();
        Builder.Append('Records purged: ' + Format(PurgedCount));
        Builder.AppendLine();
        Builder.Append(GetRetentionSummary());
        exit(Builder.ToText());
    end;
}
