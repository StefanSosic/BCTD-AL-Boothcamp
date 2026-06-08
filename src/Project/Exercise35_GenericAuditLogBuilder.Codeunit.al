codeunit 80144 "Generic Audit Log Builder"
{
    trigger OnRun()
    var
        AuditReport: Text;
        EntryCount: Integer;
    begin
        // Build a full audit log of Workshop Data entries for the compliance
        // team. The report covers all entries for the current fiscal year,
        // extracting key fields into a structured audit text file.
        // Called nightly by a job queue entry — should complete in under 30s.
        BuildAuditReport(AuditReport, EntryCount);
        WriteAuditSummary(AuditReport, EntryCount);
    end;

    internal procedure BuildAuditReport(var AuditText: Text; var EntryCount: Integer)
    var
        RecRef: RecordRef;
        FldEntryNo: FieldRef;
        FldDescription: FieldRef;
        FldAmount: FieldRef;
        FldPostingDate: FieldRef;
        FldDocumentNo: FieldRef;
        FldCustomerNo: FieldRef;
        FldActive: FieldRef;
        Builder: TextBuilder;
    begin
        // Compliance audit export for "Workshop Data" table.
        RecRef.Open(Database::"Workshop Data");

        // Set date filter for current fiscal year
        FldPostingDate := RecRef.Field(5);  // "Posting Date" field
        FldPostingDate.SetRange(CalcDate('<-1Y>', Today()), Today());

        if RecRef.FindSet() then begin
            Builder.Append(BuildAuditHeader());
            Builder.AppendLine();
            repeat
                FldEntryNo := RecRef.Field(1);      // Entry No.
                FldDescription := RecRef.Field(2);  // Description
                FldAmount := RecRef.Field(3);        // Amount
                FldPostingDate := RecRef.Field(5);   // Posting Date
                FldDocumentNo := RecRef.Field(6);    // Document No.
                FldCustomerNo := RecRef.Field(8);    // Customer No.
                FldActive := RecRef.Field(7);        // Active

                Builder.Append(FormatAuditLineFromRef(
                    Format(FldEntryNo.Value),
                    Format(FldDescription.Value),
                    Format(FldAmount.Value),
                    Format(FldPostingDate.Value),
                    Format(FldDocumentNo.Value),
                    Format(FldCustomerNo.Value),
                    Format(FldActive.Value)));
                Builder.AppendLine();
                EntryCount += 1;
            until RecRef.Next() = 0;
        end;

        RecRef.Close();
        AuditText := Builder.ToText();
    end;

    local procedure BuildAuditHeader(): Text
    begin
        exit('EntryNo|Description|Amount|PostingDate|DocumentNo|CustomerNo|Active');
    end;

    local procedure FormatAuditLineFromRef(
        EntryNo: Text; Description: Text; Amount: Text;
        PostingDate: Text; DocumentNo: Text;
        CustomerNo: Text; Active: Text): Text
    begin
        exit(EntryNo + '|' + Description + '|' + Amount + '|' +
             PostingDate + '|' + DocumentNo + '|' + CustomerNo + '|' + Active);
    end;

    local procedure WriteAuditSummary(AuditText: Text; EntryCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        // Record the audit run summary
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Description :=
            CopyStr('AUDIT_RUN|Entries:' + Format(EntryCount), 1, 100);
        WorkshopData."Posting Date" := Today();
        WorkshopData."Location Code" := 'AUDIT';
        WorkshopData.Active := true;
        WorkshopData.Insert(false);
    end;

    local procedure GetNextEntryNo(): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then
            exit(WorkshopData."Entry No." + 1);
        exit(1);
    end;
}
