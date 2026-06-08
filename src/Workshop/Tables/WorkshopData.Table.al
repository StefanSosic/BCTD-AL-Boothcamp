table 80102 "Workshop Data"
{
    Caption = 'Workshop Data';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(4; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(8; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(9; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(11; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
        }
        field(12; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
        }
        field(13; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(14; "Text Field 1"; Text[100])
        {
            Caption = 'Text Field 1';
        }
        field(15; "Text Field 2"; Text[100])
        {
            Caption = 'Text Field 2';
        }
        field(16; "Text Field 3"; Text[100])
        {
            Caption = 'Text Field 3';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(CustomerItem; "Customer No.", "Item No.")
        {
        }
        key(PostingDate; "Posting Date")
        {
        }
        key(ItemNo; "Item No.")
        {
           
        }
    }
}
