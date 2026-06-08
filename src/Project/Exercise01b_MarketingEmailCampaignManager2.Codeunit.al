codeunit 80147 "Marketing Email Campaign Mgr2"
{
    trigger OnRun()
    var
        ExportedCount: Integer;
    begin
        ExportEUMarketingList(ExportedCount);
    end;

    internal procedure ExportEUMarketingList(var ExportedCount: Integer)
    var
        Customer: Record Customer;
        Builder: TextBuilder;
    begin
        Builder.Append('"CustomerNo","Name","Email","Country"');
        Builder.AppendLine();

        Customer.SetFilter("Country/Region Code", 'AT|BE|CZ|DE|DK|FI|FR|GB|NL|NO|PL|SE');
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        Customer.SetFilter("E-Mail", '<>%1', '');

        Customer.SetLoadFields("No.", Name, "E-Mail", "Country/Region Code");
        if Customer.FindSet() then
            repeat
                if IsEligibleForCampaign(Customer) then begin
                    AppendCustomerLine(Builder, Customer);
                    ExportedCount += 1;
                end;
            until Customer.Next() = 0;
    end;

    local procedure IsEligibleForCampaign(var Customer: Record Customer): Boolean
    begin
        exit(
            (Customer."Customer Posting Group" <> '') and
            (Customer."E-Mail" <> '') and
            (Customer.Blocked = Customer.Blocked::" ")
        );
    end;

    local procedure AppendCustomerLine(var Builder: TextBuilder; var Customer: Record Customer)
    begin
        Builder.Append('"' + Customer."No." + '","');
        Builder.Append(EscapeCsv(Customer.Name) + '","');
        Builder.Append(Customer."E-Mail" + '","');
        Builder.Append(Customer."Country/Region Code" + '"');
        Builder.AppendLine();
    end;

    local procedure EscapeCsv(Input: Text): Text
    begin
        exit(Input.Replace('"', '""'));
    end;
}
