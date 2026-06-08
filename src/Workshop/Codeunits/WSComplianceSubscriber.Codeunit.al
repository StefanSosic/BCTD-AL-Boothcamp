codeunit 80200 "WS Compliance Subscriber"
{
    // ============================================================
    // Exercise 40 — Supporting Codeunit: Compliance Event Subscriber
    // ============================================================
    // This codeunit is manually bindable (EventSubscriberInstance = Manual).
    // It is used by Exercise 40 (Regulatory Compliance Validator) to
    // demonstrate the cost of always-bound vs JIT-bound subscribers.
    //
    // With EventSubscriberInstance = Manual, this subscriber is INACTIVE
    // by default. The caller controls when it is active via BindSubscription
    // and UnbindSubscription. This is the correct pattern for high-frequency
    // loops where the subscriber logic is only needed for a subset of rows.
    //
    // Workshop attendees should NOT edit this file.
    // The fix for Exercise 40 is in Exercise40_RegulatoryComplianceValidator.Codeunit.al
    // ============================================================

    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Workshop Data", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModifyWorkshopData(var Rec: Record "Workshop Data"; RunTrigger: Boolean)
    begin
        // Regulatory compliance check fired on Modify() for high-value lines.
        // In production this would: validate against external compliance API,
        // check against embargo lists, validate VAT registration numbers, etc.
        // Here we simulate cost via CalcSums + threshold comparison.
        RunComplianceValidation(Rec);
    end;

    local procedure RunComplianceValidation(var WorkshopData: Record "Workshop Data")
    var
        AuditRef: Record "Workshop Data";
        ComplianceTotal: Decimal;
        ComplianceThreshold: Decimal;
    begin
        // Simulates an expensive compliance check:
        // Looks up all prior entries for this customer to verify cumulative exposure.
        ComplianceThreshold := 10000;

        AuditRef.SetRange("Customer No.", WorkshopData."Customer No.");
        AuditRef.SetRange(Active, true);
        AuditRef.SetFilter("Posting Date",
            '>=%1&<=%2',
            CalcDate('<-CY>', Today()),
            Today());
        AuditRef.CalcSums(Amount);
        ComplianceTotal := AuditRef.Amount + WorkshopData.Amount;

        if ComplianceTotal > ComplianceThreshold then begin
            WorkshopData."Text Field 2" := CopyStr(
                'COMPLIANCE_CHECKED|' +
                Format(ComplianceTotal, 0, '<Precision,2:2><Standard Format,0>'),
                1, 100);
        end;
    end;
}
