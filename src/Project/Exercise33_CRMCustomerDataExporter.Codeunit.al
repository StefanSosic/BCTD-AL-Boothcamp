codeunit 80142 "CRM Customer Data Exporter"
{
    trigger OnRun()
    var
        ExportPayload: Text;
        ExportedRows: Integer;
        ExportStats: Text;
    begin
        BuildCRMExportPayload(ExportPayload, ExportedRows);
        ExportStats := BuildExportStatistics(ExportedRows);
        StampExportAudit(ExportedRows);
    end;

    internal procedure BuildCRMExportPayload(var Payload: Text; var ExportedRows: Integer)
    var
        Customer: Record Customer;
        Builder: TextBuilder;
    begin
        // Export active customers with e-mail to the CRM integration feed.

        Customer.SetLoadFields("No.", Name, "E-Mail", "Country/Region Code");

        Customer.SetRange(Blocked, Customer.Blocked::" ");
        Customer.SetFilter("E-Mail", '<>%1', '');

        Builder.Append(BuildCsvHeader());
        Builder.AppendLine();

        if Customer.FindSet() then
            repeat
                Builder.Append(BuildCsvRow(Customer));
                Builder.AppendLine();
                ExportedRows += 1;
            until Customer.Next() = 0;

        Payload := Builder.ToText();
    end;

    local procedure BuildCsvHeader(): Text
    begin
        exit('"CustomerNo","Name","Email","Country","WorkshopRating","Segment","ExportDate"');
    end;

    local procedure BuildCsvRow(var Customer: Record Customer): Text
    var
        Segment: Text;
        RatingLabel: Text;
    begin
        Segment := GetCustomerSegment(Customer);
        RatingLabel := GetRatingLabel(Customer."Workshop Rating");

        exit(
            '"' + Customer."No." + '",' +
            '"' + EscapeCsvField(Customer.Name) + '",' +
            '"' + EscapeCsvField(Customer."E-Mail") + '",' +
            '"' + Customer."Country/Region Code" + '",' +
            '"' + RatingLabel + '",' +
            '"' + Segment + '",' +
            '"' + Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>') + '"'
        );
    end;

    local procedure GetCustomerSegment(var Customer: Record Customer): Text
    begin
        case Customer."Customer Posting Group" of
            'DOMESTIC':
                exit('LOCAL');
            'EXPORT':
                exit('INTERNATIONAL');
            'EU':
                exit('EUROPEAN');
            else
                exit('OTHER');
        end;
    end;

    local procedure GetRatingLabel(Rating: Option): Text
    begin
        case Rating of
            0:
                exit('UNRATED');
            1:
                exit('BRONZE');
            2:
                exit('SILVER');
            3:
                exit('GOLD');
            4:
                exit('PLATINUM');
            else
                exit('UNKNOWN');
        end;
    end;

    local procedure EscapeCsvField(InputText: Text): Text
    begin
        exit(InputText.Replace('"', '""'));
    end;

    local procedure StampExportAudit(ExportedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'CRM-EXPORT';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'CRM export — ' + Format(ExportedCount) + ' customers exported';
        WorkshopData."Text Field 1" := Format(ExportedCount);
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

    internal procedure BuildExportStatistics(ExportedCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== CRM Customer Export Statistics — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Customers exported: ' + Format(ExportedCount));
        Builder.AppendLine();
        Builder.Append('Export file format: CSV (RFC 4180)');
        Builder.AppendLine();
        Builder.Append('Fields: CustomerNo, Name, Email, Country, WorkshopRating, Segment, ExportDate');
        Builder.AppendLine();
        Builder.Append('Run by: ' + UserId() + ' at ' + Format(CurrentDateTime()));
        exit(Builder.ToText());
    end;
}
