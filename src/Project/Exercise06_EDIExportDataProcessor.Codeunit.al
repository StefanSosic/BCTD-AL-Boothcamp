codeunit 80115 "EDI Export Data Processor"
{
    trigger OnRun()
    var
        FileContent: Text;
        LineCount: Integer;
    begin
        FileContent := GenerateEDIFile();
        LineCount := CountExportedLines(FileContent);
    end;

    internal procedure GenerateEDIFile(): Text
    var
        WorkshopData: Record "Workshop Data";
        CsvContent: Text;
        LineCount: Integer;
        BatchRef: Code[20];
        ExportDate: Text;
    begin
        BatchRef := CopyStr('EDI-' + Format(Today(), 0, '<Year4><Month,2><Day,2>'), 1, 20);
        ExportDate := Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>');

        // Write EDI ISA + file header
        CsvContent := BuildISASegment(BatchRef);

        // Column headers
        CsvContent += BuildColumnHeaders();

        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Document No.", '<>%1', '');

        if WorkshopData.FindSet() then
            repeat
                if IsExportEligible(WorkshopData) then begin
                    CsvContent += BuildDetailLine(WorkshopData, ExportDate);
                    LineCount += 1;
                end;
            until WorkshopData.Next() = 0;

        // EDI trailer and transmission checksum
        CsvContent += BuildIEASegment(LineCount, BatchRef);
        exit(CsvContent);
    end;

    local procedure IsExportEligible(var WorkshopData: Record "Workshop Data"): Boolean
    begin
        // Exclude config and audit records; only ship real inventory/sales entries
        if WorkshopData."Location Code" in ['CONFIG', 'AUDIT', 'STAGING'] then
            exit(false);
        if WorkshopData.Quantity <= 0 then
            exit(false);
        if WorkshopData."Customer No." = '' then
            exit(false);
        exit(true);
    end;

    local procedure BuildISASegment(BatchRef: Code[20]): Text
    begin
        exit(
            'ISA*00*          *00*          *ZZ*BCTECHDAYS     *ZZ*EDIPARTNER     *' +
            Format(Today(), 0, '<Year,2><Month,2><Day,2>') + '*0001*^*00501*' +
            Format(BatchRef) + '*0*P*>' + Format(13) + Format(10)
        );
    end;

    local procedure BuildColumnHeaders(): Text
    begin
        exit(
            '"BatchRef","EntryNo","Description","Amount","Code","PostingDate",' +
            '"DocumentNo","CustomerNo","ItemNo","Qty","UnitPrice","LineAmount",' +
            '"LocationCode","Active"' + Format(13) + Format(10)
        );
    end;

    local procedure BuildDetailLine(var WorkshopData: Record "Workshop Data"; ExportDate: Text): Text
    begin
        exit(
            '"' + ExportDate + '",' +
            Format(WorkshopData."Entry No.") + ',"' +
            WorkshopData.Description.Replace('"', '""') + '",' +
            Format(WorkshopData.Amount, 0, '<Precision,2><Standard Format,0>') + ',' +
            WorkshopData.Code + ',' +
            Format(WorkshopData."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>') + ',' +
            WorkshopData."Document No." + ',' +
            WorkshopData."Customer No." + ',' +
            WorkshopData."Item No." + ',' +
            Format(WorkshopData.Quantity, 0, '<Precision,3><Standard Format,0>') + ',' +
            Format(WorkshopData."Unit Price", 0, '<Precision,2><Standard Format,0>') + ',' +
            Format(WorkshopData."Line Amount", 0, '<Precision,2><Standard Format,0>') + ',' +
            WorkshopData."Location Code" + ',' +
            Format(WorkshopData.Active) +
            Format(13) + Format(10)
        );
    end;

    local procedure BuildIEASegment(LineCount: Integer; BatchRef: Code[20]): Text
    begin
        exit(
            'IEA*1*' + Format(BatchRef) + '*LINES=' + Format(LineCount) +
            '*GENERATED=' + Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24>:<Minutes,2>:<Seconds,2>') +
            Format(13) + Format(10)
        );
    end;

    local procedure CountExportedLines(FileContent: Text): Integer
    var
        LineBreak: Text;
        Pos: Integer;
        Count: Integer;
    begin
        LineBreak := Format(10);
        Pos := 1;
        repeat
            Pos := StrPos(CopyStr(FileContent, Pos), LineBreak);
            if Pos > 0 then begin
                Count += 1;
                Pos += 1;
            end;
        until Pos = 0;
        exit(Count);
    end;
}
