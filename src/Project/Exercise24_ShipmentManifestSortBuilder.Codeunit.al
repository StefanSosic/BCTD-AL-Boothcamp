codeunit 80133 "Shipment Manifest Sort Builder"
{
    trigger OnRun()
    var
        ManifestLines: List of [Text];
        ManifestReport: Text;
    begin
        BuildShipmentManifest(ManifestLines);
        ManifestReport := FormatManifestOutput(ManifestLines);
        StampManifestAudit(ManifestLines.Count());
    end;

    internal procedure BuildShipmentManifest(var ManifestLines: List of [Text])
    var
        WorkshopData: Record "Workshop Data";
        PreviousDate: Date;
        DayCount: Integer;
        TotalQty: Decimal;
    begin
        // Build a shipment manifest for the BLUE warehouse location,
        // grouped by posting date newest-first (carrier requirement).
        // Each day header shows the group date; lines show item/qty/customer.
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetRange("Location Code", 'BLUE');
        WorkshopData.SetFilter(Quantity, '>%1', 0);
        WorkshopData.SetFilter("Document No.", '<>%1', '');
        WorkshopData.SetCurrentKey("Posting Date");
        WorkshopData.SetAscending("Posting Date", false);

        if WorkshopData.Find('-') then
            repeat
                if WorkshopData."Posting Date" <> PreviousDate then begin
                    if PreviousDate <> 0D then
                        ManifestLines.Add('    Subtotal qty: ' + Format(TotalQty));
                    ManifestLines.Add('');
                    ManifestLines.Add('=== ' + Format(WorkshopData."Posting Date", 0, '<Weekday Text>, <Day> <Month Text> <Year4>') + ' ===');
                    PreviousDate := WorkshopData."Posting Date";
                    TotalQty := 0;
                    DayCount += 1;
                end;

                ManifestLines.Add(BuildManifestLine(WorkshopData));
                TotalQty += WorkshopData.Quantity;
            until WorkshopData.Next() = 0;

        if PreviousDate <> 0D then
            ManifestLines.Add('    Subtotal qty: ' + Format(TotalQty));
    end;

    local procedure BuildManifestLine(var WorkshopData: Record "Workshop Data"): Text
    var
        UrgencyFlag: Text;
    begin
        UrgencyFlag := GetShipmentUrgency(WorkshopData);
        exit(
            '[' + UrgencyFlag + '] ' +
            WorkshopData."Document No." + '  ' +
            PadRight(WorkshopData."Item No.", 12) + '  ' +
            'Qty: ' + Format(WorkshopData.Quantity) + '  ' +
            'Customer: ' + WorkshopData."Customer No." + '  ' +
            'Value: ' + Format(WorkshopData."Line Amount", 0, '<Precision,2:2><Standard Format,0>')
        );
    end;

    local procedure GetShipmentUrgency(var WorkshopData: Record "Workshop Data"): Text
    begin
        if WorkshopData."Line Amount" > 10000 then
            exit('PRIORITY')
        else
            if WorkshopData.Quantity > 50 then
                exit('BULK   ')
            else
                exit('STANDARD');
    end;

    local procedure PadRight(Value: Text; Width: Integer): Text
    begin
        while StrLen(Value) < Width do
            Value += ' ';
        exit(CopyStr(Value, 1, Width));
    end;

    local procedure StampManifestAudit(LineCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Code := 'MANIFEST-BUILD';
        WorkshopData.Active := true;
        WorkshopData."Posting Date" := Today();
        WorkshopData.Description := 'Shipment manifest built — ' + Format(LineCount) + ' lines';
        WorkshopData."Text Field 1" := Format(LineCount);
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

    internal procedure FormatManifestOutput(ManifestLines: List of [Text]): Text
    var
        Builder: TextBuilder;
        Line: Text;
    begin
        Builder.Append('=== SHIPMENT MANIFEST — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        foreach Line in ManifestLines do begin
            Builder.Append(Line);
            Builder.AppendLine();
        end;
        Builder.Append('=== END OF MANIFEST (' + Format(ManifestLines.Count()) + ' lines) ===');
        exit(Builder.ToText());
    end;
}
