codeunit 80138 "Customer Quick Lookup Service"
{
    trigger OnRun()
    var
        CustomerNos: List of [Code[20]];
        LookupCount: Integer;
        DisplayReport: Text;
    begin
        PrepareCustomerNoList(CustomerNos);
        DisplayReport := BatchLookupCustomers(CustomerNos, LookupCount);
        StampLookupAudit(LookupCount);
    end;

    internal procedure LookupCustomerForDisplay(CustomerNo: Code[20]; var LookupCount: Integer): Text
    var
        Customer: Record Customer;
    begin
        // Called from report, document approval, and customer statement generation.
        // May be called thousands of times in a single request (e.g., per-line on a large sales report).

        Customer.SetRange("No.", CustomerNo);
        if Customer.FindFirst() then begin
            LookupCount += 1;
            exit(BuildCustomerDisplayText(Customer));
        end;
        exit('(Customer ' + CustomerNo + ' not found)');
    end;

    local procedure PrepareCustomerNoList(var CustomerNos: List of [Code[20]])
    var
        Customer: Record Customer;
        i: Integer;
    begin
        // Collect the first 200 customer numbers for the batch display
        Customer.SetLoadFields("No.");
        if Customer.FindSet() then
            repeat
                CustomerNos.Add(Customer."No.");
                i += 1;
            until (Customer.Next() = 0) or (i >= 200);
    end;

    local procedure BatchLookupCustomers(CustomerNos: List of [Code[20]]; var LookupCount: Integer): Text
    var
        Builder: TextBuilder;
        CustomerNo: Code[20];
        Line: Text;
    begin
        Builder.Append('=== Customer Display Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        foreach CustomerNo in CustomerNos do begin
            Line := LookupCustomerForDisplay(CustomerNo, LookupCount);
            Builder.Append(Line);
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;

    local procedure BuildCustomerDisplayText(var Customer: Record Customer): Text
    begin
        exit(
            Customer."No." + ' | ' +
            Customer.Name + ' | ' +
            Customer.City + ', ' + Customer."Country/Region Code" + ' | ' +
            'Posting Group: ' + Customer."Customer Posting Group" + ' | ' +
            'Credit Limit: ' + Format(Customer."Credit Limit (LCY)", 0, '<Precision,2:2><Standard Format,0>') + ' | ' +
            'Blocked: ' + Format(Customer.Blocked)
        );
    end;

    local procedure StampLookupAudit(LookupCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'CUST-LOOKUP';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Customer batch lookup — ' + Format(LookupCount) + ' successful lookups';
        WorkshopData."Text Field 1" := Format(LookupCount);
        WorkshopData."Text Field 2" := Format(CurrentDateTime());
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
}
