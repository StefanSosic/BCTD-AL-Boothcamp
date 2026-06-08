table 80100 "Workshop Exercise"
{
    Caption = 'Workshop Exercise';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Exercise No."; Integer)
        {
            Caption = 'Exercise No.';
        }
        field(2; "Exercise Id"; Enum "Workshop Exercise")
        {
            Caption = 'Exercise Id';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Target Time (ms)"; Integer)
        {
            Caption = 'Target Time (ms)';
        }
        field(6; "Last Execution Time (ms)"; Integer)
        {
            Caption = 'Last Execution Time (ms)';
        }
        field(7; Iterations; Integer)
        {
            Caption = 'Iterations';
            InitValue = 1;
        }
        field(8; Status; Enum "Workshop Exercise Status")
        {
            Caption = 'Status';
        }
        field(9; "Last SQL Rows Read"; Integer)
        {
            Caption = 'Last SQL Rows Read';
        }
        field(10; "Last SQL Statements"; Integer)
        {
            Caption = 'Last SQL Statements';
        }
        field(11; "Total Runs"; Integer)
        {
            Caption = 'Total Runs';
            FieldClass = FlowField;
            CalcFormula = count("Workshop Exercise Result" where("Exercise No." = field("Exercise No.")));
            Editable = false;
        }
        field(12; "Best Time (ms)"; Integer)
        {
            Caption = 'Best Time (ms)';
            FieldClass = FlowField;
            CalcFormula = min("Workshop Exercise Result"."Execution Time (ms)" where("Exercise No." = field("Exercise No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Exercise No.")
        {
            Clustered = true;
        }
    }

    procedure GetStatusStyle(): Text
    begin
        case Status of
            Status::Passed:
                exit('Favorable');
            Status::Failed:
                exit('Unfavorable');
            else
                exit('Standard');
        end;
    end;
}
