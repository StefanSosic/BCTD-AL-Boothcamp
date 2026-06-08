codeunit 80131 "Dimension Uniqueness Checker"
{
    trigger OnRun()
    var
        ValidationPassed: Boolean;
        DimensionReport: Text;
        CustomerNos: List of [Code[20]];
    begin
        CollectCustomersForValidation(CustomerNos);
        ValidateAllCustomerDimensions(CustomerNos, ValidationPassed);
        DimensionReport := BuildDimensionValidationReport(CustomerNos, ValidationPassed);
    end;

    local procedure CollectCustomersForValidation(var CustomerNos: List of [Code[20]])
    var
        Customer: Record Customer;
    begin
        // Validate dimension uniqueness for all unblocked customers
        // with an active posting group (real billing customers, not prospects)
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        Customer.SetFilter("Customer Posting Group", '<>%1', '');
        Customer.SetLoadFields("No.");
        if Customer.FindSet() then
            repeat
                CustomerNos.Add(Customer."No.");
            until Customer.Next() = 0;
    end;

    internal procedure ValidateAllCustomerDimensions(CustomerNos: List of [Code[20]]; var AllValid: Boolean)
    var
        CustomerNo: Code[20];
        FailureCount: Integer;
    begin
        AllValid := true;
        foreach CustomerNo in CustomerNos do
            if not HasExactlyOneDefaultDimension(CustomerNo) then begin
                AllValid := false;
                FailureCount += 1;
                if FailureCount > 100 then
                    exit;  // Stop early if too many failures — report will show partial
            end;
    end;

    internal procedure HasExactlyOneDefaultDimension(CustomerNo: Code[20]): Boolean
    var
        WorkshopData: Record "Workshop Data";
    begin
        // A customer must have exactly one default dimension entry with code DIM*
        // More than one causes ambiguity in posting; zero means no dimension is set.
        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Code, 'DIM*');

        exit(WorkshopData.Count() = 1);
    end;

    local procedure GetDimensionViolationDescription(CustomerNo: Code[20]): Text
    var
        WorkshopData: Record "Workshop Data";
        DimCount: Integer;
    begin
        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Code, 'DIM*');
        DimCount := WorkshopData.Count();

        if DimCount = 0 then
            exit('No dimension entry found for customer ' + CustomerNo + ' — posting will fail.')
        else
            exit(Format(DimCount) + ' dimension entries found for customer ' + CustomerNo +
                 ' — ambiguous. Remove all but one.');
    end;

    local procedure ClassifyDimensionStatus(CustomerNo: Code[20]): Text
    var
        WorkshopData: Record "Workshop Data";
    begin
        WorkshopData.SetRange("Customer No.", CustomerNo);
        WorkshopData.SetRange(Active, true);
        WorkshopData.SetFilter(Code, 'DIM*');
        if WorkshopData.IsEmpty() then
            exit('MISSING')
        else
            if HasExactlyOneDefaultDimension(CustomerNo) then
                exit('VALID')
            else
                exit('DUPLICATE');
    end;

    internal procedure BuildDimensionValidationReport(CustomerNos: List of [Code[20]]; AllValid: Boolean): Text
    var
        Builder: TextBuilder;
        ValidCount: Integer;
        InvalidCount: Integer;
        CustomerNo: Code[20];
        Status: Text;
    begin
        foreach CustomerNo in CustomerNos do begin
            Status := ClassifyDimensionStatus(CustomerNo);
            if Status = 'VALID' then
                ValidCount += 1
            else
                InvalidCount += 1;
        end;

        Builder.Append('=== Account Dimension Uniqueness Report — ' + Format(Today()) + ' ===');
        Builder.AppendLine();
        Builder.Append('Customers validated: ' + Format(CustomerNos.Count()));
        Builder.AppendLine();
        Builder.Append('Valid (exactly 1 dimension): ' + Format(ValidCount));
        Builder.AppendLine();
        Builder.Append('Invalid (missing or duplicate): ' + Format(InvalidCount));
        Builder.AppendLine();
        if AllValid then
            Builder.Append('Overall result: PASSED — all customers have unique default dimension.')
        else
            Builder.Append('⚠ Overall result: FAILED — review and correct dimension setup.');
        exit(Builder.ToText());
    end;
}
