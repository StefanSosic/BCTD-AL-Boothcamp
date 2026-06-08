codeunit 80110 "Marketing Email Campaign Mgr"
{
    trigger OnRun()
    begin
        ExportEUMarketingList();
    end;

    internal procedure ExportEUMarketingList(): Text
    var
        Customer: Record Customer;
        Builder: TextBuilder;
        ExportedCount: Integer;
        SkippedBlocked: Integer;
        SkippedNoEmail: Integer;
        SkippedNoGroup: Integer;
        CampaignRef: Text;
    begin
        CampaignRef := 'EU-SPRING-' + Format(Date2DMY(Today(), 3));

        // CSV header with campaign metadata
        Builder.Append('# EU Marketing Campaign Export — ' + CampaignRef);
        Builder.AppendLine();
        Builder.Append('"CustomerNo","Name","Email","Country","PostingGroup","Tier","CampaignRef"');
        Builder.AppendLine();

        // Segment: EU/EEA countries, active, with valid e-mail
        Customer.SetFilter("Country/Region Code", 'AT|BE|CZ|DE|DK|FI|FR|GB|NL|NO|PL|SE|ES|IT|PT|CH|HU|RO');
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        Customer.SetFilter("E-Mail", '<>%1', '');

        if Customer.FindSet() then
            repeat
                if not IsEligibleForCampaign(Customer) then begin
                    if Customer.Blocked <> Customer.Blocked::" " then
                        SkippedBlocked += 1
                    else
                        if Customer."E-Mail" = '' then
                            SkippedNoEmail += 1
                        else
                            SkippedNoGroup += 1;
                end else begin
                    AppendCustomerLine(Builder, Customer, CampaignRef);
                    ExportedCount += 1;
                end;
            until Customer.Next() = 0;

        // Append export summary footer
        Builder.AppendLine();
        Builder.Append('# Summary: Exported=' + Format(ExportedCount));
        Builder.Append(', SkippedBlocked=' + Format(SkippedBlocked));
        Builder.Append(', SkippedNoEmail=' + Format(SkippedNoEmail));
        Builder.Append(', SkippedNoGroup=' + Format(SkippedNoGroup));
        Builder.AppendLine();
        exit(Builder.ToText());
    end;

    local procedure IsEligibleForCampaign(var Customer: Record Customer): Boolean
    begin
        // Must have a valid posting group (assigned sales area), unblocked, and a reachable e-mail
        if Customer.Blocked <> Customer.Blocked::" " then
            exit(false);
        if Customer."E-Mail" = '' then
            exit(false);
        if Customer."Customer Posting Group" = '' then
            exit(false);
        // Exclude internal test accounts (code starts with 'T-')
        if CopyStr(Customer."No.", 1, 2) = 'T-' then
            exit(false);
        exit(true);
    end;

    local procedure AppendCustomerLine(var Builder: TextBuilder; var Customer: Record Customer; CampaignRef: Text)
    var
        Tier: Text;
    begin
        Tier := DetermineMarketingTier(Customer."Country/Region Code", Customer."Customer Posting Group");
        Builder.Append('"' + Customer."No." + '","');
        Builder.Append(EscapeCsv(Customer.Name) + '","');
        Builder.Append(EscapeCsv(Customer."E-Mail") + '","');
        Builder.Append(Customer."Country/Region Code" + '","');
        Builder.Append(Customer."Customer Posting Group" + '","');
        Builder.Append(Tier + '","');
        Builder.Append(CampaignRef + '"');
        Builder.AppendLine();
    end;

    local procedure DetermineMarketingTier(CountryCode: Code[10]; PostingGroup: Code[20]): Text
    begin
        // Tier assignment drives email template selection in the campaign tool
        if CountryCode in ['DE', 'FR', 'GB', 'NL'] then begin
            if PostingGroup in ['DOMESTIC', 'EU-PREM'] then
                exit('PLATINUM');
            exit('GOLD');
        end;
        if CountryCode in ['AT', 'BE', 'DK', 'SE', 'FI', 'NO', 'CH'] then
            exit('SILVER');
        exit('STANDARD');
    end;

    local procedure EscapeCsv(Input: Text): Text
    begin
        exit(Input.Replace('"', '""'));
    end;
}
