tableextension 80100 "Workshop Customer Ext" extends Customer
{
    // This extension exists to demonstrate Exercise 33.
    // When you read Customer records WITHOUT SetLoadFields, the SQL engine
    // joins this extension table on every read — even if you don't use these fields.
    // The fix: use SetLoadFields to specify only the fields you need.

    fields
    {
        field(80100; "Workshop Category"; Code[20])
        {
            Caption = 'Workshop Category';
            DataClassification = CustomerContent;
        }
        field(80101; "Workshop Notes"; Text[250])
        {
            Caption = 'Workshop Notes';
            DataClassification = CustomerContent;
        }
        field(80102; "Workshop Rating"; Integer)
        {
            Caption = 'Workshop Rating';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 10;
        }
    }
}
