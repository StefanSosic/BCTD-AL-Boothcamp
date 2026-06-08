codeunit 80116 "Vendor Contract Mass Updater"
{
    trigger OnRun()
    var
        UpdatedCount: Integer;
        RevisionNo: Code[10];
    begin
        RevisionNo := 'REV-2026Q2';
        ApplyNewContractTerms(RevisionNo, UpdatedCount);
    end;

    internal procedure ApplyNewContractTerms(RevisionNo: Code[10]; var UpdatedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        AffectedCustomers: List of [Code[20]];
        EffectiveDate: Date;
    begin
        EffectiveDate := CalcDate('<-CM>', Today());  // First of current month

        // Scope: all active records assigned to customer 10000
        // where the contract code starts with 'VEND-' and hasn't been revised
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetRange("Customer No.", '10000');
        WorkshopData.SetFilter(Code, 'VEND-*');
        WorkshopData.SetFilter("Posting Date", '<=%1', EffectiveDate);

        if WorkshopData.FindSet() then
            repeat
                if NeedsContractRevision(WorkshopData, RevisionNo) then begin
                    WorkshopData.Description := BuildContractDescription(
                        WorkshopData.Code, WorkshopData."Document No.", RevisionNo);
                    WorkshopData."Text Field 1" := RevisionNo;
                    WorkshopData."Text Field 2" := Format(Today());
                    WorkshopData.Modify(false);
                    UpdatedCount += 1;
                    if not AffectedCustomers.Contains(WorkshopData."Customer No.") then
                        AffectedCustomers.Add(WorkshopData."Customer No.");
                end;
            until WorkshopData.Next() = 0;

        RecordRevisionAudit(RevisionNo, UpdatedCount, AffectedCustomers);
    end;

    local procedure NeedsContractRevision(var WorkshopData: Record "Workshop Data"; RevisionNo: Code[10]): Boolean
    begin
        // Only update records that have not already been stamped with this revision
        if WorkshopData."Text Field 1" = RevisionNo then
            exit(false);
        // Skip records with zero amount (they are framework placeholders, not real contracts)
        if WorkshopData.Amount = 0 then
            exit(false);
        // Skip records that have already expired (location code = 'EXPIRED')
        if WorkshopData."Location Code" = 'EXPIRED' then
            exit(false);
        exit(true);
    end;

    local procedure BuildContractDescription(ContractCode: Code[20]; DocumentNo: Code[20]; RevisionNo: Code[10]): Text[100]
    begin
        exit(CopyStr(
            'CONTRACT ' + RevisionNo + ' | ' + ContractCode + ' | REF: ' + DocumentNo +
            ' | Effective: ' + Format(CalcDate('<-CM>', Today())),
            1, 100
        ));
    end;

    local procedure RecordRevisionAudit(RevisionNo: Code[10]; UpdatedCount: Integer; AffectedCustomers: List of [Code[20]])
    var
        WorkshopData: Record "Workshop Data";
        EntryNo: Integer;
    begin
        WorkshopData.SetRange("Location Code", 'AUDIT');
        if WorkshopData.FindLast() then
            EntryNo := WorkshopData."Entry No." + 1
        else
            EntryNo := 10000;

        WorkshopData.Init();
        WorkshopData."Entry No." := EntryNo;
        WorkshopData."Location Code" := 'AUDIT';
        WorkshopData.Code := 'CONTRACT-UPD';
        WorkshopData.Description := 'Revision ' + RevisionNo + ' applied to ' + Format(UpdatedCount) + ' contracts';
        WorkshopData.Amount := UpdatedCount;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Active := true;
        WorkshopData."Text Field 1" := RevisionNo;
        WorkshopData."Text Field 2" := Format(AffectedCustomers.Count()) + ' customers affected';
        if not WorkshopData.Insert(false) then;
    end;
}
