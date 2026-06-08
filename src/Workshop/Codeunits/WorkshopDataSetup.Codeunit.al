codeunit 80103 "Workshop Data Setup"
{
    procedure InitializeData()
    begin
        CreateWorkshopData();
        CreateWorkshopSalesData();
    end;

    procedure ResetData()
    var
        WorkshopData: Record "Workshop Data";
        WorkshopSalesData: Record "Workshop Sales Data";
    begin
        WorkshopData.DeleteAll();
        WorkshopSalesData.DeleteAll();
        InitializeData();
    end;

    local procedure CreateWorkshopData()
    var
        WorkshopData: Record "Workshop Data";
        i: Integer;
        CustomerNos: List of [Code[20]];
        ItemNos: List of [Code[20]];
        Locations: List of [Code[10]];
    begin
        if not WorkshopData.IsEmpty() then
            exit;

        CustomerNos.Add('10000');
        CustomerNos.Add('20000');
        CustomerNos.Add('30000');
        CustomerNos.Add('40000');
        CustomerNos.Add('50000');

        ItemNos.Add('1000');
        ItemNos.Add('1001');
        ItemNos.Add('1100');
        ItemNos.Add('1200');
        ItemNos.Add('1300');
        ItemNos.Add('1896-S');
        ItemNos.Add('1900-S');
        ItemNos.Add('1906-S');
        ItemNos.Add('1908-S');
        ItemNos.Add('1920-S');

        Locations.Add('BLUE');
        Locations.Add('RED');
        Locations.Add('GREEN');
        Locations.Add('YELLOW');
        Locations.Add('WHITE');

        for i := 1 to 10000 do begin
            WorkshopData.Init();
            WorkshopData."Entry No." := i;
            WorkshopData.Description := StrSubstNo('Workshop Data Entry %1', i);
            WorkshopData.Amount := (i mod 1000) * 1.5;
            WorkshopData.Code := StrSubstNo('WD%1', Format(i, 0, '<Integer,5><Filler Character,0>'));
            WorkshopData."Posting Date" := CalcDate('<-1Y>', Today()) + (i mod 365);
            WorkshopData."Document No." := StrSubstNo('DOC-%1', Format(i, 0, '<Integer,6><Filler Character,0>'));
            WorkshopData.Active := (i mod 3) <> 0;
            WorkshopData."Customer No." := CustomerNos.Get((i mod CustomerNos.Count()) + 1);
            WorkshopData."Item No." := ItemNos.Get((i mod ItemNos.Count()) + 1);
            WorkshopData.Quantity := (i mod 50) + 1;
            WorkshopData."Unit Price" := ((i mod 200) + 1) * 0.75;
            WorkshopData."Line Amount" := WorkshopData.Quantity * WorkshopData."Unit Price";
            WorkshopData."Location Code" := Locations.Get((i mod Locations.Count()) + 1);
            WorkshopData."Text Field 1" := StrSubstNo('Additional info for entry %1 - batch processing reference', i);
            WorkshopData."Text Field 2" := StrSubstNo('Cross-reference data field %1 for warehouse operations', i);
            WorkshopData."Text Field 3" := StrSubstNo('Extended description line %1 with supplementary details', i);
            WorkshopData.Insert(false);
        end;
    end;

    local procedure CreateWorkshopSalesData()
    var
        WorkshopSalesData: Record "Workshop Sales Data";
        i: Integer;
        CustomerNos: List of [Code[20]];
        ItemNos: List of [Code[20]];
        SalespersonCodes: List of [Code[20]];
        CountryCodes: List of [Code[10]];
    begin
        if not WorkshopSalesData.IsEmpty() then
            exit;

        CustomerNos.Add('10000');
        CustomerNos.Add('20000');
        CustomerNos.Add('30000');
        CustomerNos.Add('40000');
        CustomerNos.Add('50000');

        ItemNos.Add('1000');
        ItemNos.Add('1001');
        ItemNos.Add('1100');
        ItemNos.Add('1200');
        ItemNos.Add('1300');

        SalespersonCodes.Add('JR');
        SalespersonCodes.Add('PS');
        SalespersonCodes.Add('LM');
        SalespersonCodes.Add('DC');

        CountryCodes.Add('US');
        CountryCodes.Add('GB');
        CountryCodes.Add('DE');
        CountryCodes.Add('FR');
        CountryCodes.Add('NL');

        for i := 1 to 5000 do begin
            WorkshopSalesData.Init();
            WorkshopSalesData."Entry No." := i;
            WorkshopSalesData."Customer No." := CustomerNos.Get((i mod CustomerNos.Count()) + 1);
            WorkshopSalesData."Item No." := ItemNos.Get((i mod ItemNos.Count()) + 1);
            WorkshopSalesData."Posting Date" := CalcDate('<-1Y>', Today()) + (i mod 365);
            WorkshopSalesData.Quantity := (i mod 100) + 1;
            WorkshopSalesData."Unit Price" := ((i mod 500) + 1) * 0.5;
            WorkshopSalesData."Line Amount" := WorkshopSalesData.Quantity * WorkshopSalesData."Unit Price";
            WorkshopSalesData."Discount %" := i mod 30;
            WorkshopSalesData."Salesperson Code" := SalespersonCodes.Get((i mod SalespersonCodes.Count()) + 1);
            WorkshopSalesData."Country Code" := CountryCodes.Get((i mod CountryCodes.Count()) + 1);
            WorkshopSalesData.Insert(false);
        end;
    end;
}
