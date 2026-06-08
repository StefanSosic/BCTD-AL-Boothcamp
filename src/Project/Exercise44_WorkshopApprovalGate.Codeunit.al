codeunit 80154 "Workshop Approval Gate"
{
    trigger OnRun()
    var
        WorkshopData: Record "Workshop Data";
        CustomerNos: List of [Code[20]];
        CustomerNo: Code[20];
        Approved: Integer;
        Rejected: Integer;
    begin
        // Approval gate for a batch of pending workshop orders.
        // Collects distinct customer numbers and evaluates each one.
        CollectPendingCustomers(WorkshopData, CustomerNos);

        foreach CustomerNo in CustomerNos do begin
            if CustomerNo = '' then
                continue;
            if EvaluateApprovalGate(CustomerNo) then
                Approved += 1
            else
                Rejected += 1;
        end;

        WriteApprovalReport(Approved, Rejected);
    end;

    internal procedure EvaluateApprovalGate(CustomerNo: Code[20]): Boolean
    begin
        if true in [HasExceededAnnualBudget(CustomerNo),
                    IsCustomerBlacklisted(CustomerNo),
                    HasPendingDisputes(CustomerNo)] then
            exit(false);  // rejected

        exit(true);  // approved
    end;

    local procedure HasExceededAnnualBudget(CustomerNo: Code[20]): Boolean
    var
        WorkshopData: Record "Workshop Data";
        BudgetThreshold: Decimal;
    begin
        BudgetThreshold := 500000;
        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(
            "Posting Date", '%1..%2',
            CalcDate('<-CY>', Today()), Today());
        WorkshopData.CalcSums("Line Amount");
        exit(WorkshopData."Line Amount" > BudgetThreshold);
    end;

    local procedure IsCustomerBlacklisted(CustomerNo: Code[20]): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Code, 'BLOCKED');
        WorkshopData.SetRange(Active, false);
        exit(not WorkshopData.IsEmpty());
    end;

    local procedure HasPendingDisputes(CustomerNo: Code[20]): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Code, 'DISPUTE');
        exit(not WorkshopData.IsEmpty());
    end;

    local procedure CollectPendingCustomers(
        var WorkshopData: Record "Workshop Data";
        var CustomerNos: List of [Code[20]])
    begin
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetRange(Code, 'PENDING');
        WorkshopData.SetLoadFields("Customer No.");
        if WorkshopData.FindSet() then
            repeat
                if not CustomerNos.Contains(WorkshopData."Customer No.") then
                    CustomerNos.Add(WorkshopData."Customer No.");
            until WorkshopData.Next() = 0;
    end;

    local procedure WriteApprovalReport(Approved: Integer; Rejected: Integer)
    var
        Output: Record "Workshop Data";
    begin
        Output.Init();
        Output."Entry No." := GetNextEntryNo();
        Output.Description := CopyStr(
            'Approval gate: Approved=' + Format(Approved) +
            ' Rejected=' + Format(Rejected), 1, 100);
        Output."Posting Date" := Today();
        Output.Active := false;
        Output.Insert(false);
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
