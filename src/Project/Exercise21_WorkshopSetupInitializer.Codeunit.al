codeunit 80130 "Workshop Setup Initializer"
{
    trigger OnRun()
    begin
        EnsureDefaultConfigRecord();
        ValidateConfigurationIntegrity();
    end;

    internal procedure EnsureDefaultConfigRecord()
    var
        WorkshopData: Record "Workshop Data";
        ConfigVersion: Text;
    begin
        ConfigVersion := 'v2026.1';

        // Configuration reset: wipe existing CONFIG entries and rebuild from defaults
        // This runs at startup and during system reinstall — usually the CONFIG
        // location is already empty (e.g. on fresh install), but we always delete.
        WorkshopData.SetRange("Location Code", 'CONFIG');

        WorkshopData.DeleteAll(false);

        // Insert the standard config entries for this version
        InsertConfigEntry(999001, 'CFG-DEFAULT', 'Default Workshop Configuration — ' + ConfigVersion, 0);
        InsertConfigEntry(999002, 'CFG-ALLOC', 'Allocation rules — period close threshold', 10000);
        InsertConfigEntry(999003, 'CFG-CREDIT', 'Credit limit default for new customers', 5000);
        InsertConfigEntry(999004, 'CFG-TOLERANCE', 'Payment tolerance percentage (0.01 = 1%)', 0.01);
        InsertConfigEntry(999005, 'CFG-REORDER', 'Default reorder point quantity', 10);
    end;

    local procedure InsertConfigEntry(EntryNo: Integer; Code: Code[20]; Description: Text[100]; Value: Decimal)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := EntryNo;
        WorkshopData.Code := Code;
        WorkshopData.Description := Description;
        WorkshopData."Location Code" := 'CONFIG';
        WorkshopData.Active := true;
        WorkshopData.Amount := Value;
        WorkshopData."Posting Date" := Today();
        WorkshopData."Document No." := 'CFG-' + Format(Today(), 0, '<Year4><Month,2><Day,2>');
        WorkshopData."Text Field 1" := Format(Today());
        WorkshopData."Text Field 2" := UserId();
        WorkshopData.Insert(false);
    end;

    local procedure GetConfigValue(ConfigCode: Code[20]): Decimal
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Location Code", 'CONFIG');
        WorkshopData.SetRange(Code, ConfigCode);
        WorkshopData.SetRange(Active, true);
        if WorkshopData.FindFirst() then
            exit(WorkshopData.Amount);
        exit(0);
    end;

    local procedure ValidateConfigurationIntegrity()
    var
        RequiredCodes: List of [Text];
        RequiredCode: Text;
        MissingCodes: Text;
        WorkshopData: Record "Workshop Data";
    begin
        // Ensure all mandatory config entries are present
        RequiredCodes.Add('CFG-DEFAULT');
        RequiredCodes.Add('CFG-ALLOC');
        RequiredCodes.Add('CFG-CREDIT');
        RequiredCodes.Add('CFG-TOLERANCE');
        RequiredCodes.Add('CFG-REORDER');

        foreach RequiredCode in RequiredCodes do begin
            WorkshopData.SetRange("Location Code", 'CONFIG');
            WorkshopData.SetRange(Code, RequiredCode);
            if WorkshopData.IsEmpty() then begin
                if MissingCodes <> '' then MissingCodes += ', ';
                MissingCodes += RequiredCode;
            end;
        end;

        if MissingCodes <> '' then
            Error('Workshop configuration incomplete. Missing entries: %1', MissingCodes);
    end;

    internal procedure IsConfigured(): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Location Code", 'CONFIG');
        WorkshopData.SetRange(Code, 'CFG-DEFAULT');
        WorkshopData.SetRange(Active, true);
        exit(not WorkshopData.IsEmpty());
    end;

    internal procedure GetSetupSummary(): Text
    var
        Builder: TextBuilder;
        CreditLimit: Decimal;
        ReorderPoint: Decimal;
        Tolerance: Decimal;
    begin
        CreditLimit := GetConfigValue('CFG-CREDIT');
        ReorderPoint := GetConfigValue('CFG-REORDER');
        Tolerance := GetConfigValue('CFG-TOLERANCE');

        Builder.Append('=== Workshop Configuration Summary ===');
        Builder.AppendLine();
        Builder.Append('Configured: ' + Format(IsConfigured()));
        Builder.AppendLine();
        Builder.Append('Default credit limit: ' + Format(CreditLimit, 0, '<Precision,2:2><Standard Format,0>'));
        Builder.AppendLine();
        Builder.Append('Reorder point qty: ' + Format(ReorderPoint));
        Builder.AppendLine();
        Builder.Append('Payment tolerance: ' + Format(Tolerance * 100) + '%');
        exit(Builder.ToText());
    end;
}
