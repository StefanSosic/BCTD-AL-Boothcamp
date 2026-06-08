codeunit 80132 "Customer Template Sync Manager"
{
    trigger OnRun()
    var
        SyncedCount: Integer;
        SkippedCount: Integer;
        SyncReport: Text;
    begin
        SynchronizeCustomerTemplates(SyncedCount, SkippedCount);
        SyncReport := BuildSyncReport(SyncedCount, SkippedCount);
    end;

    internal procedure SynchronizeCustomerTemplates(var SyncedCount: Integer; var SkippedCount: Integer)
    var
        InboundTemplates: List of [Integer];
        EntryNo: Integer;
        PostingGroup: Code[20];
        TemplateName: Text[100];
    begin
        // Sync receives a batch of template records from the CRM integration layer.
        // Templates with existing Entry No. must be updated; new ones must be created.
        // The batch is re-sent daily and typically 90% of records already exist.
        LoadInboundTemplateBatch(InboundTemplates);

        foreach EntryNo in InboundTemplates do begin
            PostingGroup := GetPostingGroup(EntryNo);
            TemplateName := BuildTemplateName(EntryNo, PostingGroup);
            if IsTemplateValidForSync(EntryNo, PostingGroup) then begin
                UpsertTemplate(EntryNo, TemplateName, PostingGroup);
                SyncedCount += 1;
            end else
                SkippedCount += 1;
        end;
    end;

    local procedure LoadInboundTemplateBatch(var Templates: List of [Integer])
    var
        i: Integer;
    begin
        // Simulate inbound batch from CRM — real integration would read from JSON/XML
        for i := 888001 to 888100 do
            Templates.Add(i);
        Templates.Add(888888);  // Special VIP template
        Templates.Add(999001);  // Config template (will fail validation)
    end;

    local procedure IsTemplateValidForSync(EntryNo: Integer; PostingGroup: Code[20]): Boolean
    begin
        // Exclude config-range entries (reserved for system use)
        if (EntryNo >= 999000) and (EntryNo <= 999999) then
            exit(false);
        // Posting group must be assigned
        if PostingGroup = '' then
            exit(false);
        exit(true);
    end;

    local procedure UpsertTemplate(EntryNo: Integer; TemplateName: Text[100]; PostingGroup: Code[20])
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := EntryNo;
        WorkshopData.Description := TemplateName;
        WorkshopData.Code := 'TMPL-' + Format(EntryNo);
        WorkshopData."Location Code" := 'TMPL';
        WorkshopData."Customer No." := PostingGroup;
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData."Text Field 1" := Format(Today());
        WorkshopData."Text Field 2" := 'CRM-SYNC';
        WorkshopData."Text Field 3" := UserId();

        if not WorkshopData.Insert(false) then
            WorkshopData.Modify(false);
    end;

    local procedure BuildTemplateName(EntryNo: Integer; PostingGroup: Code[20]): Text[100]
    var
        TemplateName: Text[100];
    begin
        TemplateName := 'Template-' + Format(EntryNo) + ' [' + PostingGroup + ']';
        if EntryNo = 888888 then
            TemplateName := 'VIP Customer Template [' + PostingGroup + ']';
        exit(CopyStr(TemplateName, 1, 100));
    end;

    local procedure GetPostingGroup(EntryNo: Integer): Code[20]
    begin
        case EntryNo mod 3 of
            0:
                exit('DOMESTIC');
            1:
                exit('EU');
            else
                exit('EXPORT');
        end;
    end;

    internal procedure BuildSyncReport(SyncedCount: Integer; SkippedCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== Customer Template Sync Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Templates synchronized: ' + Format(SyncedCount));
        Builder.AppendLine();
        Builder.Append('Templates skipped (validation failed): ' + Format(SkippedCount));
        Builder.AppendLine();
        if SkippedCount > 0 then
            Builder.Append('⚠ Review skipped templates — posting group or range validation failed.');
        exit(Builder.ToText());
    end;
}
