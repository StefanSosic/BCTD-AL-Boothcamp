table 80105 "Workshop Attendee"
{
    Caption = 'Workshop Attendee';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "First Name"; Text[50])
        {
            Caption = 'First Name';
            NotBlank = true;
        }
        field(3; "Last Name"; Text[50])
        {
            Caption = 'Last Name';
            NotBlank = true;
        }
        field(4; Email; Text[250])
        {
            Caption = 'Email';

            trigger OnValidate()
            var
                InvalidEmailErr: Label 'Please enter a valid email address.';
            begin
                if (Email <> '') and not IsValidEmail(Email) then
                    Error(InvalidEmailErr);
            end;
        }
        field(5; "Dashboard URL"; Text[250])
        {
            Caption = 'Dashboard URL';
            // Example: https://my-workshop-dashboard.onrender.com
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure GetInstance(): Boolean
    begin
        if Get('') then
            exit(true);
        Init();
        "Primary Key" := '';
        exit(false);
    end;

    procedure GetOrCreate()
    begin
        if not Get('') then begin
            Init();
            "Primary Key" := '';
            Insert();
        end;
    end;

    procedure HasInfo(): Boolean
    begin
        if not Get('') then
            exit(false);
        exit(("First Name" <> '') and ("Last Name" <> '') and (Email <> ''));
    end;

    local procedure IsValidEmail(EmailAddress: Text): Boolean
    var
        AtPos: Integer;
        DotPos: Integer;
    begin
        AtPos := StrPos(EmailAddress, '@');
        if AtPos <= 1 then
            exit(false);
        DotPos := StrPos(CopyStr(EmailAddress, AtPos + 1), '.');
        if DotPos = 0 then
            exit(false);
        exit(true);
    end;
}
