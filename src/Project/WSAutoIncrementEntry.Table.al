table 80107 "WS AutoIncrement Entry"
{
    // Used by Exercise 36 to demonstrate AutoIncrement PK performance impact.
    // AutoIncrement = true on the PK prevents SQL Server from batching INSERT statements.
    // SQL Server must return SCOPE_IDENTITY() after each row, forcing N individual INSERTs.
    DataClassification = CustomerContent;
    Caption = 'WS AutoIncrement Entry';

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Id';
            AutoIncrement = true;  // SQL Server IDENTITY — disables bulk insert batching
        }
        field(2; "Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Item No.';
        }
        field(3; "Location Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Location Code';
        }
        field(4; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity';
        }
        field(5; "Unit Cost"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Unit Cost';
        }
        field(6; "Count Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Count Date';
        }
        field(7; "Counter Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Counter Code';
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
