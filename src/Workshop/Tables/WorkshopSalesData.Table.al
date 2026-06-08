table 80104 "Workshop Sales Data"
{
    Caption = 'Workshop Sales Data';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(6; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
        }
        field(7; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
        }
        field(8; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
        }
        field(9; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
        }
        field(10; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
        }
        field(11; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            FieldClass = FlowField;
            CalcFormula = sum("Workshop Sales Data"."Line Amount" where("Customer No." = field("Customer No.")));
            Editable = false;
        }
        field(12; "Total Quantity"; Decimal)
        {
            Caption = 'Total Quantity';
            FieldClass = FlowField;
            CalcFormula = sum("Workshop Sales Data".Quantity where("Customer No." = field("Customer No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Customer; "Customer No.")
        {
            SumIndexFields = "Line Amount", Quantity;
        }
        key(ItemDate; "Item No.", "Posting Date")
        {
        }
        key(Salesperson; "Salesperson Code")
        {
            SumIndexFields = "Line Amount";
        }
    }
}
