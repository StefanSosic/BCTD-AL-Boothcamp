table 80101 "Workshop Exercise Result"
{
    Caption = 'Workshop Exercise Result';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Exercise No."; Integer)
        {
            Caption = 'Exercise No.';
            TableRelation = "Workshop Exercise"."Exercise No.";
        }
        field(3; "Execution Time (ms)"; Integer)
        {
            Caption = 'Execution Time (ms)';
        }
        field(4; "SQL Rows Read"; Integer)
        {
            Caption = 'SQL Rows Read';
        }
        field(5; "SQL Statements Executed"; Integer)
        {
            Caption = 'SQL Statements Executed';
        }
        field(6; "Run DateTime"; DateTime)
        {
            Caption = 'Run DateTime';
        }
        field(7; Status; Enum "Workshop Exercise Status")
        {
            Caption = 'Status';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Exercise; "Exercise No.", "Entry No.")
        {
        }
    }
}
