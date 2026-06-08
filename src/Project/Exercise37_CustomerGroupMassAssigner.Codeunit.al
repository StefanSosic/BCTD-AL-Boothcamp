codeunit 80146 "Customer Group Mass Assigner"
{
    trigger OnRun()
    var
        UpdatedCount: Integer;
        GroupCode: Code[20];
        SummaryText: Text;
    begin
        // Year-end customer group reassignment: assign all active customers
        // in a region to a new pricing group for the upcoming fiscal year.
        // Marketing has confirmed the group codes. Expected runtime: < 10s.
        GroupCode := 'PRIORITY-A';
        UpdatedCount := AssignCustomerPricingGroup('EU', GroupCode);
        SummaryText := BuildAssignmentSummary(UpdatedCount, GroupCode);
        LogAssignmentRun(SummaryText, UpdatedCount);
    end;

    internal procedure AssignCustomerPricingGroup(
        RegionFilter: Text; NewGroupCode: Code[20]): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        // Assign all Workshop Data entries for EU customers to a new pricing group.
        WorkshopData.SetRange("Location Code", RegionFilter);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Customer No.", '<>%1', '');

        WorkshopData.ModifyAll("Text Field 1", NewGroupCode, true);

        exit(GetUpdatedCount(RegionFilter, NewGroupCode));
    end;

    internal procedure AssignCustomerPricingGroupFixed(
        RegionFilter: Text; NewGroupCode: Code[20]): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Location Code", RegionFilter);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter("Customer No.", '<>%1', '');
        WorkshopData.ModifyAll("Text Field 1", NewGroupCode, false);

        exit(GetUpdatedCount(RegionFilter, NewGroupCode));
    end;

    local procedure GetUpdatedCount(RegionFilter: Text; GroupCode: Code[20]): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Location Code", RegionFilter);
        WorkshopData.SetRange("Text Field 1", GroupCode);
        exit(WorkshopData.Count());
    end;

    local procedure BuildAssignmentSummary(
        UpdatedCount: Integer; GroupCode: Code[20]): Text
    var
        Builder: TextBuilder;
    begin
        Builder.Append('GROUP_ASSIGN');
        Builder.Append('|Group:' + GroupCode);
        Builder.Append('|Count:' + Format(UpdatedCount));
        Builder.Append('|Date:' + Format(Today()));
        Builder.Append('|User:' + UserId());
        exit(Builder.ToText());
    end;

    local procedure LogAssignmentRun(SummaryText: Text; UpdatedCount: Integer)
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.Init();
        WorkshopData."Entry No." := GetNextEntryNo();
        WorkshopData.Description := CopyStr(SummaryText, 1, 100);
        WorkshopData."Posting Date" := Today();
        WorkshopData."Location Code" := 'GROUP-LOG';
        WorkshopData.Quantity := UpdatedCount;
        WorkshopData.Active := true;
        WorkshopData.Insert(false);
    end;

    local procedure GetNextEntryNo(): Integer
    var
        WorkshopData: Record "Workshop Data";
    begin
        if WorkshopData.FindLast() then
            exit(WorkshopData."Entry No." + 1);
        exit(1);
    end;
}
