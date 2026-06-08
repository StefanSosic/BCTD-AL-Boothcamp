codeunit 80122 "Salesperson Assignment Router"
{
    trigger OnRun()
    var
        TotalRouted: Integer;
        UnassignedCount: Integer;
        RoutingReport: Text;
    begin
        BuildAndApplyRoutingMap(TotalRouted, UnassignedCount);
        RoutingReport := BuildRoutingReport(TotalRouted, UnassignedCount);
    end;

    internal procedure BuildAndApplyRoutingMap(var TotalRouted: Integer; var UnassignedCount: Integer)
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        AssignedCode: Code[20];
        OriginalCode: Code[20];
    begin
        // Phase 1: Load current customer → salesperson assignments into the routing map
        Customer.SetLoadFields("No.", "Salesperson Code", "Customer Posting Group", Blocked);
        if Customer.FindSet() then
            repeat
                if IsRoutingEligible(Customer) then begin
                    TempCustomer.Init();
                    TempCustomer."No." := Customer."No.";
                    TempCustomer."Salesperson Code" := Customer."Salesperson Code";
                    TempCustomer."Customer Posting Group" := Customer."Customer Posting Group";
                    if TempCustomer.Insert(false) then;
                end;
            until Customer.Next() = 0;

        // Phase 2: Apply routing overrides for load balancing
        //          (e.g. overloaded salespersons, leave absences, region changes)
        Customer.Reset();
        Customer.SetLoadFields("No.", "Salesperson Code");
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        if Customer.FindSet() then
            repeat
                TempCustomer.Reset();
                if TempCustomer.Get(Customer."No.") then begin
                    OriginalCode := TempCustomer."Salesperson Code";
                    AssignedCode := DetermineAssignedSalesperson(
                        TempCustomer."Salesperson Code",
                        TempCustomer."Customer Posting Group");
                    if AssignedCode <> '' then
                        TotalRouted += 1
                    else
                        UnassignedCount += 1;
                end;
            until Customer.Next() = 0;
    end;

    local procedure IsRoutingEligible(var Customer: Record Customer): Boolean
    begin
        // Only include customers that are active and have a posting group (real accounts)
        if Customer.Blocked <> Customer.Blocked::" " then
            exit(false);
        if Customer."Customer Posting Group" = '' then
            exit(false);
        // Exclude internal test accounts
        if CopyStr(Customer."No.", 1, 3) = 'T00' then
            exit(false);
        exit(true);
    end;

    local procedure DetermineAssignedSalesperson(CurrentCode: Code[20]; PostingGroup: Code[20]): Code[20]
    begin
        case CurrentCode of
            'JR':
                exit('PS');   // JR at capacity — reroute all new to PS
            'LM':
                exit('DC');   // LM on parental leave until Q3
            'AB':
                begin
                    // AB handles only DOMESTIC; EXPORT goes to MK
                    if PostingGroup = 'EXPORT' then
                        exit('MK')
                    else
                        exit('AB');
                end;
            else
                if CurrentCode = '' then
                    exit('PS')  // Unassigned defaults to PS (catch-all)
                else
                    exit(CurrentCode);
        end;
    end;

    local procedure BuildRoutingReport(TotalRouted: Integer; UnassignedCount: Integer): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('=== Salesperson Routing Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Customers routed: ' + Format(TotalRouted));
        Builder.AppendLine();
        Builder.Append('Unassigned (no salesperson): ' + Format(UnassignedCount));
        Builder.AppendLine();
        if UnassignedCount > 0 then
            Builder.Append('⚠ Unassigned customers should be reviewed by the sales manager.');
        exit(Builder.ToText());
    end;
}
