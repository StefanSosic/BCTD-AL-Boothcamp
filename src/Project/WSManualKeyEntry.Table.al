table 80106 "WS Manual Key Entry"
{
    // Used by Exercise 36 to demonstrate the fix for AutoIncrement PK performance issue.
    // Manual PK assignment (with NumberSequence) allows SQL Server to batch INSERT statements.
    // All rows in a loop can be sent as a single SQL batch — dramatically fewer round-trips.
    DataClassification = CustomerContent;
    Caption = 'WS Manual Key Entry';

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Id';
            // No AutoIncrement — PK assigned manually via NumberSequence.Next()
            // Allows SQL Server to batch multiple INSERT statements into one round-trip
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
