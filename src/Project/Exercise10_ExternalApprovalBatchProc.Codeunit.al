codeunit 80119 "External Approval Batch Proc"
{
    trigger OnRun()
    var
        ProcessedCount: Integer;
        RejectedCount: Integer;
        BatchReport: Text;
    begin
        ProcessPendingExternalApprovals(ProcessedCount, RejectedCount);
        BatchReport := BuildBatchReport(ProcessedCount, RejectedCount);
    end;

    internal procedure ProcessPendingExternalApprovals(var ProcessedCount: Integer; var RejectedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
        ValidationErrors: List of [Text];
    begin
        // External approval system posts records with Code = 'EXT-APPROVAL-QUEUE'
        // when documents need sign-off. The queue is empty ~95% of the time —
        // this proc runs on a 30-second job schedule.
        WorkshopData.SetRange(Code, 'EXT-APPROVAL-QUEUE');
        WorkshopData.SetRange(Active, false);
        WorkshopData.SetFilter(Amount, '>%1', 0);
        WorkshopData.SetFilter("Customer No.", '<>%1', '');

        if WorkshopData.IsEmpty() then
            exit;
        if WorkshopData.FindSet() then
            repeat
                if ValidateApprovalRequest(WorkshopData, ValidationErrors) then begin
                    ProcessApprovalLine(WorkshopData);
                    ProcessedCount += 1;
                end else
                    RejectedCount += 1;
            until WorkshopData.Next() = 0;
    end;

    local procedure ValidateApprovalRequest(var WorkshopData: Record "Workshop Data"; var Errors: List of [Text]): Boolean
    var
        Customer: Record Customer;
        IsValid: Boolean;
    begin
        IsValid := true;

        // Rule 1: Amount must be within allowed range
        if (WorkshopData.Amount < 100) or (WorkshopData.Amount > 1000000) then begin
            Errors.Add('Amount out of range: ' + Format(WorkshopData.Amount));
            IsValid := false;
        end;

        // Rule 2: Customer must exist and be unblocked
        if Customer.Get(WorkshopData."Customer No.") then begin
            if Customer.Blocked <> Customer.Blocked::" " then begin
                Errors.Add('Customer ' + WorkshopData."Customer No." + ' is blocked');
                IsValid := false;
            end;
        end else begin
            Errors.Add('Customer not found: ' + WorkshopData."Customer No.");
            IsValid := false;
        end;

        // Rule 3: Document No must follow required format (EXT-XXXXX)
        if CopyStr(WorkshopData."Document No.", 1, 4) <> 'EXT-' then begin
            Errors.Add('Invalid document format: ' + WorkshopData."Document No.");
            IsValid := false;
        end;

        exit(IsValid);
    end;

    local procedure ProcessApprovalLine(var WorkshopData: Record "Workshop Data")
    begin
        // Approve: mark active, stamp approval date and approver code
        WorkshopData.Active := true;
        WorkshopData."Text Field 1" := 'APPROVED';
        WorkshopData."Text Field 2" := Format(Today());
        WorkshopData."Text Field 3" := 'AUTO-BATCH';
        WorkshopData.Modify(false);
    end;

    local procedure BuildBatchReport(ProcessedCount: Integer; RejectedCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== External Approval Batch — ' + Format(CurrentDateTime()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Approved: ' + Format(ProcessedCount));
        Builder.AppendLine();
        Builder.Append('Rejected: ' + Format(RejectedCount));
        Builder.AppendLine();
        if ProcessedCount + RejectedCount = 0 then
            Builder.Append('Queue was empty — no action taken.');
        exit(Builder.ToText());
    end;
}
