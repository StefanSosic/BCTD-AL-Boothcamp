codeunit 80101 "Workshop Runner"
{
    procedure RunExercise(var Exercise: Record "Workshop Exercise")
    var
        ExerciseResult: Record "Workshop Exercise Result";
        DashboardClient: Codeunit "Workshop Dashboard Client";
        StartTime: DateTime;
        EndTime: DateTime;
        StartSqlRowsRead: BigInteger;
        StartSqlStatements: BigInteger;
        ElapsedMs: Integer;
        SqlRowsRead: BigInteger;
        SqlStatements: BigInteger;
        Iteration: Integer;
    begin
        StartSqlRowsRead := SessionInformation.SqlRowsRead();
        StartSqlStatements := SessionInformation.SqlStatementsExecuted();
        StartTime := CurrentDateTime();

        for Iteration := 1 to Exercise.Iterations do begin
            Database.SelectLatestVersion(); // Flush NST cache so each run measures real SQL, not cached data
            DispatchExercise(Exercise."Exercise Id");
        end;

        EndTime := CurrentDateTime();

        ElapsedMs := EndTime - StartTime;
        SqlRowsRead := SessionInformation.SqlRowsRead() - StartSqlRowsRead;
        SqlStatements := SessionInformation.SqlStatementsExecuted() - StartSqlStatements;

        // Update exercise record
        Exercise."Last Execution Time (ms)" := ElapsedMs;
        Exercise."Last SQL Rows Read" := SqlRowsRead;
        Exercise."Last SQL Statements" := SqlStatements;
        if ElapsedMs <= Exercise."Target Time (ms)" then
            Exercise.Status := Exercise.Status::Passed
        else
            Exercise.Status := Exercise.Status::Failed;
        Exercise.Modify(false);

        // Log result
        ExerciseResult.Init();
        ExerciseResult."Exercise No." := Exercise."Exercise No.";
        ExerciseResult."Execution Time (ms)" := ElapsedMs;
        ExerciseResult."SQL Rows Read" := SqlRowsRead;
        ExerciseResult."SQL Statements Executed" := SqlStatements;
        ExerciseResult."Run DateTime" := CurrentDateTime();
        ExerciseResult.Status := Exercise.Status;
        ExerciseResult.Insert(true);

        // Notify the live TV dashboard
        // DashboardClient.PostExerciseResult(Exercise);
    end;

    procedure RunAllExercises()
    var
        Exercise: Record "Workshop Exercise";
    begin
        if Exercise.FindSet(true) then
            repeat
                RunExercise(Exercise);
            until Exercise.Next() = 0;
    end;

    procedure InitializeExercises()
    var
        Install: Codeunit "Workshop Install";
    begin
        Install.SeedExercises();
        Message('All exercises have been initialized with test data.');
    end;

    procedure ResetData()
    var
        DataSetup: Codeunit "Workshop Data Setup";
    begin
        DataSetup.ResetData();
        Message('Workshop data has been reset.');
    end;

    procedure ResetResults()
    var
        Exercise: Record "Workshop Exercise";
        ExerciseResult: Record "Workshop Exercise Result";
    begin
        ExerciseResult.DeleteAll();
        if Exercise.FindSet(true) then
            repeat
                Exercise."Last Execution Time (ms)" := 0;
                Exercise."Last SQL Rows Read" := 0;
                Exercise."Last SQL Statements" := 0;
                Exercise.Status := Exercise.Status::"Not Run";
                Exercise.Modify(false);
            until Exercise.Next() = 0;
        Message('All results have been reset.');
    end;

    local procedure DispatchExercise(ExerciseId: Enum "Workshop Exercise")
    var
        Ex01: Codeunit "Marketing Email Campaign Mgr";
        Ex02: Codeunit "Marketing Email Campaign Mgr2";
        Ex03: Codeunit "Vendor Payment Aging Processor";
        Ex04: Codeunit "Customer Account Statement Gen";
        Ex05: Codeunit "Sales Order Credit Validator";
        Ex06: Codeunit "Sales Budget Variance Analyzer";
        Ex07: Codeunit "EDI Export Data Processor";
        Ex08: Codeunit "Vendor Contract Mass Updater";
        Ex09: Codeunit "Ledger Entry Archive Purger";
        Ex10: Codeunit "Warehouse Bin Stock Checker";
        Ex11: Codeunit "External Approval Batch Proc";
        Ex12: Codeunit "Payment Tolerance Auditor";
        Ex13: Codeunit "Customer Pricing Engine";
        Ex14: Codeunit "Salesperson Assignment Router";
        Ex15: Codeunit "Item Reorder Point Monitor";
        Ex16: Codeunit "Period Close Alloc Resetter";
        Ex17: Codeunit "Customer Credit Risk Assessor";
        Ex18: Codeunit "Order Eligibility Handler";
        Ex19: Codeunit "Sales Posting Auth Validator";
        Ex20: Codeunit "Whse Transfer Plan Advisor";
        Ex21: Codeunit "Data Import Staging Manager";
        Ex22: Codeunit "Workshop Setup Initializer";
        Ex23: Codeunit "Dimension Uniqueness Checker";
        Ex24: Codeunit "Customer Template Sync Manager";
        Ex25: Codeunit "Shipment Manifest Sort Builder";
        Ex26: Codeunit "Fiscal Period Date Collector";
        Ex27: Codeunit "Purchase Journal Line Importer";
        Ex28: Codeunit "Item Sales Analytics Engine";
        Ex29: Codeunit "Shipment Tracking No Generator";
        Ex30: Codeunit "Customer Quick Lookup Service";
        Ex31: Codeunit "Whse Movement Entry Creator";
        Ex32: Codeunit "Inventory Reservation Proc";
        Ex33: Codeunit "Item Qty Replenishment Monitor";
        Ex34: Codeunit "CRM Customer Data Exporter";
        Ex35: Codeunit "Inventory Stock Dashboard Rfsh";
        Ex36: Codeunit "Generic Audit Log Builder";
        Ex37: Codeunit "Product Count Sheet Batch Ldr";
        Ex38: Codeunit "Customer Group Mass Assigner";
        Ex39: Codeunit "Item Pricing Tier Refresher";
        Ex40: Codeunit "Sales Order Eligibility Gate";
        Ex41: Codeunit "WS Compliance Validator";
        Ex42: Codeunit "Inventory Cost Summary Builder";
        Ex43: Codeunit "Reservation Discount Processor";
        Ex44: Codeunit "Location Revenue Dashboard";
        Ex45: Codeunit "Workshop Approval Gate";
    begin
        case ExerciseId of
            ExerciseId::"Export Customer Email List":
                Ex01.Run();
            ExerciseId::"Export Customer Email List2":
                Ex02.Run();
            ExerciseId::"Get Latest Vendor Ledger Entries":
                Ex03.Run();
            ExerciseId::"Customer Balance Report":
                Ex04.Run();
            ExerciseId::"Validate Customer Credit Limit":
                Ex05.Run();
            ExerciseId::"Calculate Total Outstanding":
                Ex06.Run();
            ExerciseId::"Generate Sales Invoice CSV":
                Ex07.Run();
            ExerciseId::"Update Vendor Payment Terms":
                Ex08.Run();
            ExerciseId::"Purge Old Vendor Ledger Entries":
                Ex09.Run();
            ExerciseId::"Check If Warehouse Has Items":
                Ex10.Run();
            ExerciseId::"Process Approval Entries":
                Ex11.Run();
            ExerciseId::"Scan Sales Lines for Discounts":
                Ex12.Run();
            ExerciseId::"Build Price Calculation Buffer":
                Ex13.Run();
            ExerciseId::"Customer-to-Salesperson Map":
                Ex14.Run();
            ExerciseId::"Find Items Below Reorder Point":
                Ex15.Run();
            ExerciseId::"Reset Vendor Country Codes":
                Ex16.Run();
            ExerciseId::"Find Customers High Balance":
                Ex17.Run();
            ExerciseId::"Check Order Eligibility OR":
                Ex18.Run();
            ExerciseId::"Validate Posting Permissions AND":
                Ex19.Run();
            ExerciseId::"Update Vendor Shipping Methods":
                Ex20.Run();
            ExerciseId::"Clean Up Temp Records":
                Ex21.Run();
            ExerciseId::"Initialize Default Config":
                Ex22.Run();
            ExerciseId::"Check Single Default Dimension":
                Ex23.Run();
            ExerciseId::"Upsert Customer Template":
                Ex24.Run();
            ExerciseId::"List Items by Receipt Date":
                Ex25.Run();
            ExerciseId::"Collect Posting Date List":
                Ex26.Run();
            ExerciseId::"Import Journal Lines":
                Ex27.Run();
            ExerciseId::"Item Sales Summary Report":
                Ex28.Run();
            ExerciseId::"Generate Unique Document Numbers":
                Ex29.Run();
            ExerciseId::"Look Up Customer by No":
                Ex30.Run();
            ExerciseId::"Bulk Create Warehouse Entries":
                Ex31.Run();
            ExerciseId::"Reserve Inventory with Lock":
                Ex32.Run();
            ExerciseId::"Search Sales Lines by Item":
                Ex33.Run();
            ExerciseId::"Customer Export with Extensions":
                Ex34.Run();
            ExerciseId::"Inventory Dashboard Read Isolation":
                Ex35.Run();
            ExerciseId::"Build Audit Log Report":
                Ex36.Run();
            ExerciseId::"Load Product Count Sheet":
                Ex37.Run();
            ExerciseId::"Mass Assign Customer Groups":
                Ex38.Run();
            ExerciseId::"Refresh Item Pricing Tiers":
                Ex39.Run();
            ExerciseId::"Check Sales Order Eligibility":
                Ex40.Run();
            ExerciseId::"Validate Regulatory Compliance":
                Ex41.Run();
            ExerciseId::"Build Inventory Cost Summary":
                Ex42.Run();
            ExerciseId::"Process Reservation Discounts":
                Ex43.Run();
            ExerciseId::"Refresh Location Revenue":
                Ex44.Run();
            ExerciseId::"Evaluate Approval Gate":
                Ex45.Run();
        end;
    end;
}
