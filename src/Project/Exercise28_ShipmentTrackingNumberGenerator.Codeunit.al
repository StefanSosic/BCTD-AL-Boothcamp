codeunit 80137 "Shipment Tracking No Generator"
{
    trigger OnRun()
    var
        ShipmentNos: List of [Code[20]];
        ReportText: Text;
        i: Integer;
    begin
        // Simulate batch shipment label generation for the picking station
        for i := 1 to 25 do
            ShipmentNos.Add(GenerateShipmentTrackingNumber());
        RecordGeneratedBatch(ShipmentNos);
        ReportText := BuildGenerationReport(ShipmentNos);
    end;

    internal procedure GenerateShipmentTrackingNumber(): Code[20]
    var
        WorkshopData: Record "Workshop Data";
        NextSeq: BigInteger;
        TrackingNo: Code[20];
    begin
        // Generate a sequential tracking number for a new outbound shipment.
        // Must be unique and monotonically increasing. Called once per shipment
        // from both the batch pick station and the individual parcel scan screen.

        WorkshopData.LockTable(true);
        WorkshopData.SetRange("Location Code", 'SHIPPING');
        WorkshopData.SetRange(Active, true);
        if WorkshopData.FindLast() then
            NextSeq := WorkshopData."Entry No." + 1
        else
            NextSeq := 1;

        TrackingNo := CopyStr('SHP-' + Format(NextSeq, 0, '<Integer>'), 1, 20);
        exit(TrackingNo);
    end;

    local procedure RecordGeneratedBatch(ShipmentNos: List of [Code[20]])
    var
        WorkshopData: Record "Workshop Data";
        TrackingNo: Code[20];
        EntryNo: Integer;
    begin
        WorkshopData.SetLoadFields("Entry No.");
        if WorkshopData.FindLast() then
            EntryNo := WorkshopData."Entry No." + 1
        else
            EntryNo := 1;

        foreach TrackingNo in ShipmentNos do begin
            WorkshopData.Init();
            WorkshopData."Entry No." := EntryNo;
            WorkshopData."Document No." := TrackingNo;
            WorkshopData."Location Code" := 'SHIPPING';
            WorkshopData."Posting Date" := Today();
            WorkshopData.Active := true;
            WorkshopData.Code := 'SHIP-BATCH';
            WorkshopData."Text Field 1" := Format(Today(), 0, '<Year4><Month,2><Day,2>');
            WorkshopData."Text Field 2" := UserId();
            WorkshopData.Description := 'Outbound shipment — ' + TrackingNo;
            WorkshopData.Insert(false);
            EntryNo += 1;
        end;
    end;

    local procedure GetCarrierForTrackingNo(TrackingNo: Code[20]): Text
    var
        SeqStr: Text;
        SeqNo: Integer;
    begin
        // Determine carrier based on the tracking number sequence range
        SeqStr := CopyStr(Format(TrackingNo), StrLen('SHP-') + 1);
        if Evaluate(SeqNo, SeqStr) then begin
            if SeqNo mod 3 = 0 then exit('DHL');
            if SeqNo mod 3 = 1 then exit('UPS');
            exit('FedEx');
        end;
        exit('UNKNOWN');
    end;

    internal procedure BuildGenerationReport(ShipmentNos: List of [Code[20]]): Text
    var
        Builder: TextBuilder;
        No: Code[20];
    begin
        Builder.Append('=== Shipment Tracking Number Generation Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Numbers generated: ' + Format(ShipmentNos.Count()));
        Builder.AppendLine();
        foreach No in ShipmentNos do begin
            Builder.Append('  ' + No + '  [' + GetCarrierForTrackingNo(No) + ']');
            Builder.AppendLine();
        end;
        exit(Builder.ToText());
    end;
}
