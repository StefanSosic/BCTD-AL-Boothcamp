page 80100 "Workshop Runner"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Workshop Exercise";
    Caption = 'AL Performance Workshop';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Exercises)
            {
                field("Exercise No."; Rec."Exercise No.")
                {
                    ApplicationArea = All;
                    Width = 5;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Width = 30;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    Width = 8;
                }
                field("Last Execution Time (ms)"; Rec."Last Execution Time (ms)")
                {
                    ApplicationArea = All;
                    Width = 12;
                    StyleExpr = StatusStyle;
                }
                field("Target Time (ms)"; Rec."Target Time (ms)")
                {
                    ApplicationArea = All;
                    Width = 12;
                }
                field(Iterations; Rec.Iterations)
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field("Last SQL Rows Read"; Rec."Last SQL Rows Read")
                {
                    ApplicationArea = All;
                    Width = 12;
                }
                field("Last SQL Statements"; Rec."Last SQL Statements")
                {
                    ApplicationArea = All;
                    Width = 12;
                }
            }
        }
        area(FactBoxes)
        {
            part(RunHistory; "Workshop Run History")
            {
                ApplicationArea = All;
                SubPageLink = "Exercise No." = field("Exercise No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunSelected)
            {
                ApplicationArea = All;
                Caption = 'Run Selected';
                ToolTip = 'Run the selected exercise and measure performance.';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Runner: Codeunit "Workshop Runner";
                begin
                    Runner.RunExercise(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RunAll)
            {
                ApplicationArea = All;
                Caption = 'Run All';
                ToolTip = 'Run all exercises and measure performance.';
                Image = AllLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Runner: Codeunit "Workshop Runner";
                begin
                    Runner.RunAllExercises();
                    CurrPage.Update(false);
                end;
            }
            action(Initialize)
            {
                ApplicationArea = All;
                Caption = 'Initialize';
                ToolTip = 'Seed all exercises and create test data. Use this if exercises are missing.';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Runner: Codeunit "Workshop Runner";
                begin
                    Runner.InitializeExercises();
                    CurrPage.Update(false);
                end;
            }
            action(ResetResults)
            {
                ApplicationArea = All;
                Caption = 'Reset Results';
                ToolTip = 'Clear all execution results and set status back to Not Run.';
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Runner: Codeunit "Workshop Runner";
                begin
                    Runner.ResetResults();
                    CurrPage.Update(false);
                end;
            }
            action(ResetData)
            {
                ApplicationArea = All;
                Caption = 'Reset Data';
                ToolTip = 'Delete and re-create all workshop test data.';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Runner: Codeunit "Workshop Runner";
                begin
                    Runner.ResetData();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(AttendeeInfo)
            {
                ApplicationArea = All;
                Caption = 'Attendee Info';
                ToolTip = 'View or edit your attendee information (name and email).';
                Image = ContactPerson;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Workshop Attendee");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Attendee: Record "Workshop Attendee";
    begin
        if not Attendee.HasInfo() then
            Page.RunModal(Page::"Workshop Attendee");
    end;

    trigger OnAfterGetRecord()
    begin
        StatusStyle := Rec.GetStatusStyle();
    end;

    var
        StatusStyle: Text;
}
