codeunit 80124 "Period Close Alloc Resetter"
{
    trigger OnRun()
    var
        ClosedCount: Integer;
        PeriodLabel: Text;
        CloseReport: Text;
    begin
        ResetLocationCodesAfterPeriodClose(ClosedCount);
        PeriodLabel := GetCurrentPeriodLabel();
        CloseReport := BuildPeriodCloseReport(ClosedCount, PeriodLabel);
    end;

    internal procedure ResetLocationCodesAfterPeriodClose(var UpdatedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        TargetLocation: Code[10];
        AllowedLocations: Text;
        PreviousPeriodStart: Date;
        PreviousPeriodEnd: Date;
    begin
        // Period-close routine: reset all unposted allocation entries from staging
        // locations back to the primary BLUE location so the new period starts clean.
        TargetLocation := 'BLUE';
        AllowedLocations := 'RED|YELLOW|GREEN';
        PreviousPeriodStart := CalcDate('<-CM>', Today());
        PreviousPeriodEnd := CalcDate('<CM>', PreviousPeriodStart);

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Location Code", AllowedLocations);
        WorkshopData.SetFilter("Posting Date", '%1..%2', PreviousPeriodStart, PreviousPeriodEnd);
        WorkshopData.SetFilter(Amount, '<>%1', 0);

        if WorkshopData.IsEmpty() then
            WorkshopData.ModifyAll("Location Code", TargetLocation, false);

        // Count what was updated for the period close audit log
        WorkshopData.Reset();
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetRange("Location Code", TargetLocation);
        WorkshopData.SetFilter("Posting Date", '%1..%2', PreviousPeriodStart, PreviousPeriodEnd);
        if WorkshopData.FindSet() then
            WorkshopData.ModifyAll("Location Code", TargetLocation, false);
        UpdatedCount := WorkshopData.Count();

        StampPeriodCloseAudit(UpdatedCount);
    end;

    local procedure GetCurrentPeriodLabel(): Text
    var
        PeriodStart: Date;
        PeriodEnd: Date;
    begin
        PeriodStart := CalcDate('<-CM>', Today());
        PeriodEnd := CalcDate('<CM>', PeriodStart);
        exit(Format(PeriodStart, 0, '<Day,2>.<Month,2>.<Year4>') +
             ' – ' +
             Format(PeriodEnd, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;

    local procedure ValidatePeriodClosePrerequisites(): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        // Verify there are no posted entries still flagged as unconfirmed
        WorkshopData.SetRange(Code, 'POSTED');
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Posting Date", '<=%1', CalcDate('<-CM>', Today()));
        exit(WorkshopData.IsEmpty());
    end;

    local procedure StampPeriodCloseAudit(UpdatedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'PERIOD-CLOSE-LOG';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Period close — ' + Format(UpdatedCount) + ' allocations reset';
        WorkshopData."Text Field 1" := Format(Today());
        WorkshopData."Text Field 2" := GetCurrentPeriodLabel();
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

    internal procedure BuildPeriodCloseReport(ResetCount: Integer; PeriodLabel: Text): Text
    var
        Builder: TextBuilder;
        PrereqOk: Boolean;
    begin
        PrereqOk := ValidatePeriodClosePrerequisites();
        Builder.Append('=== Period Close — Allocation Reset Report ===');
        Builder.AppendLine();
        Builder.Append('Period: ' + PeriodLabel);
        Builder.AppendLine();
        Builder.Append('Allocations reset to BLUE: ' + Format(ResetCount));
        Builder.AppendLine();
        if PrereqOk then
            Builder.Append('Pre-close validation: PASSED')
        else
            Builder.Append('⚠ Pre-close validation: FAILED — posted entries still unconfirmed');
        exit(Builder.ToText());
    end;
}
