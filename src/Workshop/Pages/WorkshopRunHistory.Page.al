page 80101 "Workshop Run History"
{
    PageType = ListPart;
    SourceTable = "Workshop Exercise Result";
    Caption = 'Run History';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Results)
            {
                field("Run DateTime"; Rec."Run DateTime")
                {
                    ApplicationArea = All;
                    Width = 15;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = ResultStyle;
                    Width = 8;
                }
                field("Execution Time (ms)"; Rec."Execution Time (ms)")
                {
                    ApplicationArea = All;
                    Width = 12;
                    StyleExpr = ResultStyle;
                }
                field("SQL Rows Read"; Rec."SQL Rows Read")
                {
                    ApplicationArea = All;
                    Width = 12;
                }
                field("SQL Statements Executed"; Rec."SQL Statements Executed")
                {
                    ApplicationArea = All;
                    Width = 12;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Passed:
                ResultStyle := 'Favorable';
            Rec.Status::Failed:
                ResultStyle := 'Unfavorable';
            else
                ResultStyle := 'Standard';
        end;
    end;

    var
        ResultStyle: Text;
}
