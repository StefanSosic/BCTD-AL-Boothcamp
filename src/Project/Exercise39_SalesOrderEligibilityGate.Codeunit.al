codeunit 80149 "Sales Order Eligibility Gate"
{
    trigger OnRun()
    var
        WorkshopData: Record "Workshop Data";
        CustomerNos: List of [Code[20]];
        CustomerNo: Code[20];
        Approved: Integer;
        Rejected: Integer;
        SkippedBlank: Integer;
    begin
        // Eligibility gate for a batch of pending sales orders.
        CollectPendingOrderCustomers(WorkshopData, CustomerNos);

        foreach CustomerNo in CustomerNos do begin
            if CustomerNo = '' then begin
                SkippedBlank += 1;
                continue;
            end;
            if EvaluateOrderEligibility(CustomerNo) then
                Approved += 1
            else
                Rejected += 1;
        end;

        WriteEligibilityReport(Approved, Rejected, SkippedBlank);
    end;

    internal procedure EvaluateOrderEligibility(CustomerNo: Code[20]): Boolean
    var
        OrderBlockedErr: Label 'Sales order for customer %1 is blocked: credit limit, item holds, or overdue invoices detected.', Comment = '%1 = customer number';
    begin
        if IsOverCreditLimit(CustomerNo) or HasBlockedItems(CustomerNo) or HasOverdueInvoices(CustomerNo) then begin
            LogRejection(CustomerNo, 'Eligibility check failed');
            exit(false);
        end;

        exit(true);
    end;

    internal procedure IsOverCreditLimit(CustomerNo: Code[20]): Boolean
    var
        WorkshopData: Record "Workshop Data";
        TotalOutstanding: Decimal;
        CreditThreshold: Decimal;
    begin
        // Simulates credit limit check: sums all open sales lines for customer.
        CreditThreshold := 50000;

        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Amount, '>%1', 0);
        WorkshopData.CalcSums(Amount);
        TotalOutstanding := WorkshopData.Amount;

        exit(TotalOutstanding > CreditThreshold);
    end;

    internal procedure HasBlockedItems(CustomerNo: Code[20]): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        // Simulates blocked-item check: scans pending lines for items
        // that are on hold in this customer's last 90 days of orders.
        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetFilter("Posting Date", '>=%1', CalcDate('<-90D>', Today()));
        WorkshopData.SetFilter("Item No.", '<>%1', '');
        WorkshopData.SetFilter("Text Field 1", '%1', 'BLOCKED');  // Item hold flag

        exit(not WorkshopData.IsEmpty());
    end;

    internal procedure HasOverdueInvoices(CustomerNo: Code[20]): Boolean
    var
        WorkshopData: Record "Workshop Data";
        OverdueCount: Integer;
        OverdueThreshold: Integer;
    begin
        // Simulates overdue invoice check: counts unpaid invoices past due date.
        OverdueThreshold := 3;

        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Posting Date", '<=%1', CalcDate('<-30D>', Today()));
        WorkshopData.SetFilter("Document No.", '<>%1', '');
        OverdueCount := WorkshopData.Count();

        exit(OverdueCount >= OverdueThreshold);
    end;

    local procedure CollectPendingOrderCustomers(var WorkshopData: Record "Workshop Data"; var CustomerNos: List of [Code[20]])
    begin
        WorkshopData.Reset();
        WorkshopData.SetFilter("Customer No.", '<>%1', '');
        WorkshopData.SetRange(Active, true);
        if WorkshopData.FindSet() then
            repeat
                if not CustomerNos.Contains(WorkshopData."Customer No.") then
                    CustomerNos.Add(WorkshopData."Customer No.");
            until WorkshopData.Next() = 0;
    end;

    local procedure LogRejection(CustomerNo: Code[20]; Reason: Text)
    var
        WorkshopData: Record "Workshop Data";
        LastEntry: Integer;
    begin
        if WorkshopData.FindLast() then
            LastEntry := WorkshopData."Entry No.";
        WorkshopData.Init();
        WorkshopData."Entry No." := LastEntry + 1;
        WorkshopData."Customer No." := CustomerNo;
        WorkshopData.Description := CopyStr('REJECT: ' + Reason, 1, 100);
        WorkshopData."Posting Date" := Today();
        WorkshopData.Active := false;
        WorkshopData.Insert(false);
    end;

    local procedure WriteEligibilityReport(Approved: Integer; Rejected: Integer; Skipped: Integer)
    var
        WorkshopData: Record "Workshop Data";
        LastEntry: Integer;
    begin
        if WorkshopData.FindLast() then
            LastEntry := WorkshopData."Entry No.";
        WorkshopData.Init();
        WorkshopData."Entry No." := LastEntry + 1;
        WorkshopData.Description := CopyStr(
            'ELIGIBILITY|Approved:' + Format(Approved) +
            '|Rejected:' + Format(Rejected) +
            '|Skipped:' + Format(Skipped), 1, 100);
        WorkshopData."Posting Date" := Today();
        WorkshopData.Active := true;
        WorkshopData.Insert(false);
    end;
}
