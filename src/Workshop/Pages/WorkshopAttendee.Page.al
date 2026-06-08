page 80102 "Workshop Attendee"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Workshop Attendee";
    Caption = 'Attendee Information';
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Your Details';

                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field(Email; Rec.Email)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
            }
            group(Dashboard)
            {
                Caption = 'Dashboard';

                field("Dashboard URL"; Rec."Dashboard URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Base URL of the live workshop dashboard, e.g. https://my-dashboard.onrender.com';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InitDashboard)
            {
                ApplicationArea = All;
                Caption = 'Send to Dashboard';
                ToolTip = 'Registers this attendee on the live dashboard immediately.';
                Image = SendTo;

                trigger OnAction()
                var
                    DashboardClient: Codeunit "Workshop Dashboard Client";
                    SentMsg: Label 'Attendee info sent to dashboard.';
                begin
                    if Rec.Modify(true) then;
                    DashboardClient.InitializeAttendee(Rec);
                    Message(SentMsg);
                end;
            }
        }
        area(Promoted)
        {
            actionref(InitDashboard_Promoted; InitDashboard) { }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrCreate();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        DashboardClient: Codeunit "Workshop Dashboard Client";
        MissingInfoErr: Label 'Please fill in First Name, Last Name, and Email before continuing.';
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then begin
            if (Rec."First Name" = '') or (Rec."Last Name" = '') or (Rec.Email = '') then
                Error(MissingInfoErr);
            if Rec.Modify(true) then;
            DashboardClient.InitializeAttendee(Rec);
        end;
        exit(true);
    end;
}
