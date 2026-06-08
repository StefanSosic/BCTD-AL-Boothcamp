codeunit 80100 "Workshop Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        // SeedExercises();
    end;

    procedure SeedExercises()
    var
        Exercise: Record "Workshop Exercise";
        DataSetup: Codeunit "Workshop Data Setup";
    begin
        if not Exercise.IsEmpty() then
            Exercise.DeleteAll();

        // Exercise 1: Missing SetLoadFields
        InsertExercise(1, Enum::"Workshop Exercise"::"Export Customer Email List",
            'Export Customer Email List',
            'Build customer email list — loads all fields instead of just No. and E-Mail',
            5000, 100);

        // Exercise 2: Incomplete SetLoadFields (reload)
        InsertExercise(2, Enum::"Workshop Exercise"::"Export Customer Email List2",
            'Export Customer Email List',
            'Email campaign — SetLoadFields list is incomplete, so BC reloads the full row per inaccessible field access',
            5000, 100);

        // Exercise 3: Find('-') vs FindSet
        InsertExercise(3, Enum::"Workshop Exercise"::"Get Latest Vendor Ledger Entries",
            'Get Latest Vendor Ledger Entries',
            'Retrieve vendor ledger entries sorted — uses Find(''-'') instead of FindSet with SetCurrentKey',
            3000, 100);

        // Exercise 4: CalcFields in Loop
        InsertExercise(4, Enum::"Workshop Exercise"::"Customer Balance Report",
            'Customer Balance Report',
            'Build customer balance summary — calls CalcFields(Balance) inside loop instead of SetAutoCalcFields',
            5000, 1);

        // Exercise 5: Record by Value
        InsertExercise(5, Enum::"Workshop Exercise"::"Validate Customer Credit Limit",
            'Validate Customer Credit Limit',
            'Check credit limits — passes Customer record by value instead of by reference (var)',
            5000, 300);

        // Exercise 6: Loop Sum vs CalcSums
        InsertExercise(6, Enum::"Workshop Exercise"::"Calculate Total Outstanding",
            'Calculate Total Outstanding',
            'Sum vendor budgeted amounts — loops with repeat..until instead of using CalcSums',
            3000, 50);

        // Exercise 7: Text Concatenation
        // InsertExercise(7, Enum::"Workshop Exercise"::"Generate Sales Invoice CSV",
        //     'Generate Sales Invoice CSV',
        //     'Build CSV content — uses += string concatenation instead of TextBuilder',
        //     15000, 1);

        // Exercise 8: Modify in Loop
        InsertExercise(8, Enum::"Workshop Exercise"::"Update Vendor Payment Terms",
            'Update Vendor Payment Terms',
            'Mass-update vendor payment terms — modifies loop variable directly instead of copy',
            3000, 100);

        // Exercise 9: Delete in Loop
        InsertExercise(9, Enum::"Workshop Exercise"::"Purge Old Vendor Ledger Entries",
            'Purge Old Vendor Ledger Entries',
            'Clean up old entries — deletes loop variable directly instead of Get + Delete on copy',
            3000, 1);

        // Exercise 10: Count = 0 vs IsEmpty
        InsertExercise(10, Enum::"Workshop Exercise"::"Check If Warehouse Has Items",
            'Check If Warehouse Has Items',
            'Check item existence — uses Count() = 0 instead of IsEmpty',
            3000, 1);

        // Exercise 11: IsEmpty Guard (Empty Table)
        InsertExercise(11, Enum::"Workshop Exercise"::"Process Approval Entries",
            'Process Approval Entries',
            'Process approvals on filtered (always empty) set — calls FindSet without IsEmpty guard',
            3000, 100);

        // Exercise 12: IsEmpty Guard (Full Table)
        InsertExercise(12, Enum::"Workshop Exercise"::"Scan Sales Lines for Discounts",
            'Scan Sales Lines for Discounts',
            'Find discounted sales lines — uses redundant IsEmpty + FindSet on large table (double scan)',
            3000, 100);

        // Exercise 13: Normal vs Temp Table
        InsertExercise(13, Enum::"Workshop Exercise"::"Build Price Calculation Buffer",
            'Build Price Calculation Buffer',
            'Build pricing buffer — inserts 2000 rows into real DB table instead of using temporary variable',
            15000, 20);

        // Exercise 14: Temp Table vs Dictionary
        InsertExercise(14, Enum::"Workshop Exercise"::"Customer-to-Salesperson Map",
            'Customer-to-Salesperson Map',
            'Build lookup map — uses temp table for key-value pairs instead of Dictionary',
            8000, 100);

        // Exercise 15: FindFirst in Loop
        InsertExercise(15, Enum::"Workshop Exercise"::"Find Items Below Reorder Point",
            'Find Items Below Reorder Point',
            'Loop items — uses FindFirst (buffers 1 record) instead of FindSet for iteration',
            3000, 100);

        // Exercise 16: Guard Before ModifyAll
        InsertExercise(16, Enum::"Workshop Exercise"::"Reset Vendor Country Codes",
            'Reset Vendor Country Codes',
            'Reset vendor data — guards ModifyAll with FindSet (loads all records) instead of just calling ModifyAll',
            3000, 50);

        // Exercise 17: Filter on CalcField
        InsertExercise(17, Enum::"Workshop Exercise"::"Find Customers High Balance",
            'Find Customers High Balance',
            'Credit risk report — filters on FlowField Balance instead of using SetAutoCalcFields + AL filter',
            5000, 100);

        // Exercise 18: Lazy Eval: OR
        // InsertExercise(18, Enum::"Workshop Exercise"::"Check Order Eligibility OR",
        //     'Check Order Eligibility (OR)',
        //     'Check express eligibility — uses or operator (evaluates both sides) instead of short-circuit',
        //     5000, 1);

        // Exercise 19: Lazy Eval: AND
        InsertExercise(19, Enum::"Workshop Exercise"::"Validate Posting Permissions AND",
            'Validate Posting Permissions (AND)',
            'Check posting rights — uses and operator (evaluates both sides) instead of short-circuit',
            5000, 100);

        // Exercise 20: Filters Inside Loop
        InsertExercise(20, Enum::"Workshop Exercise"::"Update Vendor Shipping Methods",
            'Update Vendor Shipping Methods',
            'Update shipping — changes filter inside repeat..until loop instead of collecting first',
            3000, 100);

        // Exercise 21: Guard Before DeleteAll
        InsertExercise(21, Enum::"Workshop Exercise"::"Clean Up Temp Records",
            'Clean Up Temp Records',
            'Delete staging records — guards DeleteAll with FindSet (loads all) instead of IsEmpty',
            3000, 100);

        // Exercise 22: DeleteAll Locking
        InsertExercise(22, Enum::"Workshop Exercise"::"Initialize Default Config",
            'Initialize Default Config',
            'Init setup record — calls DeleteAll on possibly empty table causing unnecessary lock',
            3000, 100);

        // Exercise 23: Count = 1 Check
        InsertExercise(23, Enum::"Workshop Exercise"::"Check Single Default Dimension",
            'Check Single Default Dimension',
            'Verify single dimension — uses Count = 1 instead of FindFirst + Next = 0',
            3000, 1);

        // Exercise 24: If Not Insert Then Modify
        InsertExercise(24, Enum::"Workshop Exercise"::"Upsert Customer Template",
            'Upsert Customer Template',
            'Create/update template — uses if not Insert then Modify instead of checking existence first',
            3000, 100);

        // Exercise 25: Find('-') with Sort
        InsertExercise(25, Enum::"Workshop Exercise"::"List Items by Receipt Date",
            'List Items by Receipt Date',
            'List items newest first — uses Find(''-'') instead of FindSet + SetCurrentKey + SetAscending',
            3000, 50);

        // Exercise 26: Temp Table vs List
        InsertExercise(26, Enum::"Workshop Exercise"::"Collect Posting Date List",
            'Collect Posting Date List',
            'Collect unique dates — uses temp table for simple date list instead of List of [Date]',
            8000, 100);

        // Exercise 27: Bulk Insert Buffer Flush
        InsertExercise(27, Enum::"Workshop Exercise"::"Import Journal Lines",
            'Import Journal Lines',
            'Import 5000 lines — calls FindLast inside loop (flushes bulk insert buffer) instead of counter',
            15000, 1);

        // Exercise 28: Query vs Nested Loops
        InsertExercise(28, Enum::"Workshop Exercise"::"Item Sales Summary Report",
            'Item Sales Summary Report',
            'Item sales summary — uses nested FindSet loops (N+1 queries) instead of Query object',
            15000, 1);

        // Exercise 29: NumberSequence vs LockTable
        InsertExercise(29, Enum::"Workshop Exercise"::"Generate Unique Document Numbers",
            'Generate Unique Document Numbers',
            'Generate tracking numbers — uses LockTable + FindLast instead of NumberSequence.Next()',
            5000, 100);

        // Exercise 30: Get vs Find for PK
        InsertExercise(30, Enum::"Workshop Exercise"::"Look Up Customer by No",
            'Look Up Customer by No',
            'Customer lookup — uses SetRange + FindFirst for known PK instead of Get()',
            3000, 50);

        // Exercise 31: Insert Return Value in Loop
        InsertExercise(31, Enum::"Workshop Exercise"::"Bulk Create Warehouse Entries",
            'Bulk Create Warehouse Entries',
            'Create 5000 entries — uses if Insert() then (disables bulk buffering) instead of bare Insert()',
            15000, 100);

        // Exercise 32: ReadIsolation vs LockTable
        InsertExercise(32, Enum::"Workshop Exercise"::"Reserve Inventory with Lock",
            'Reserve Inventory with Lock',
            'Reserve inventory — uses LockTable on entire table instead of ReadIsolation on specific record',
            5000, 100);

        // Exercise 33: IncludedFields
        InsertExercise(33, Enum::"Workshop Exercise"::"Search Sales Lines by Item",
            'Search Sales Lines by Item',
            'Sum quantities by item — secondary key missing IncludedFields (no covering index)',
            5000, 50);

        // Exercise 34: SetLoadFields with Table Extensions
        InsertExercise(34, Enum::"Workshop Exercise"::"Customer Export with Extensions",
            'Customer Export with Extensions',
            'Export customers — loads all fields including extension table JOIN instead of SetLoadFields',
            5000, 100);

        // Exercise 35: ReadIsolation::ReadUncommitted for Read-Only Queries
        InsertExercise(35, Enum::"Workshop Exercise"::"Inventory Dashboard Read Isolation",
            'Inventory Dashboard Read Isolation',
            'Dashboard refresh — reads 50 000 rows without ReadUncommitted, blocking concurrent warehouse writes',
            15000, 10);

        // Exercise 36: RecordRef vs Typed Record
        InsertExercise(36, Enum::"Workshop Exercise"::"Build Audit Log Report",
            'Build Audit Log Report',
            'Audit log export — uses RecordRef + FieldRef on a known table instead of a typed Record variable',
            15000, 20);

        // Exercise 37: AutoIncrement PK Disables SQL Bulk Insert
        InsertExercise(37, Enum::"Workshop Exercise"::"Load Product Count Sheet",
            'Load Product Count Sheet',
            'Count sheet import — AutoIncrement PK forces 10 000 individual SQL INSERTs instead of bulk batching',
            15000, 1);

        // Exercise 38: ModifyAll Degraded by Event Subscriber
        InsertExercise(38, Enum::"Workshop Exercise"::"Mass Assign Customer Groups",
            'Mass Assign Customer Groups',
            'Bulk group update — ModifyAll fires N individual Modify calls when OnAfterModify subscriber is bound',
            5000, 30);

        // Exercise 39: NST Record Cache — Stale Reads in Multi-Step Pipeline
        InsertExercise(39, Enum::"Workshop Exercise"::"Refresh Item Pricing Tiers",
            'Refresh Item Pricing Tiers',
            'Pricing pipeline — 10 passes over 50 000 rows silently read stale NST cache without SelectLatestVersion',
            15000, 10);

        // Exercise 40: Short-Circuit: case true of vs or
        InsertExercise(40, Enum::"Workshop Exercise"::"Check Sales Order Eligibility",
            'Check Sales Order Eligibility',
            'Order gate — uses or (eager evaluation) instead of case true of (short-circuit) for three expensive checks',
            5000, 1);

        // Exercise 41: JIT Subscriber Binding — Bind Only When Needed
        InsertExercise(41, Enum::"Workshop Exercise"::"Validate Regulatory Compliance",
            'Validate Regulatory Compliance',
            'Compliance batch — subscriber bound for entire 10 000-row loop instead of only for qualifying rows',
            5000, 1);

        // Exercise 42: SingleInstance Codeunit — Avoid Per-Call Instantiation
        InsertExercise(42, Enum::"Workshop Exercise"::"Build Inventory Cost Summary",
            'Build Inventory Cost Summary',
            'Cost rollup — helper codeunit instantiated per-row (50 000 times) instead of using [SingleInstance]',
            15000, 3);

        // Exercise 43: LockTable vs UpdLock — Precision Pessimistic Locking
        InsertExercise(43, Enum::"Workshop Exercise"::"Process Reservation Discounts",
            'Process Reservation Discounts',
            'Discount batch — LockTable acquires table-level X-lock; UpdLock locks only the rows being modified',
            5000, 1);

        // Exercise 44: AL-Side Aggregation vs Query GROUP BY
        InsertExercise(44, Enum::"Workshop Exercise"::"Refresh Location Revenue",
            'Refresh Location Revenue',
            'Revenue dashboard — iterates all rows in AL to aggregate per-location instead of using a Query object',
            15000, 10);

        // Exercise 45: in [...] Operator — Short-Circuit and Order Matters
        InsertExercise(45, Enum::"Workshop Exercise"::"Evaluate Approval Gate",
            'Evaluate Approval Gate',
            'Approval check — in [...] list has expensive CalcSums first; reordering to cheap-first short-circuits early',
            5000, 20);

        DataSetup.InitializeData();
    end;

    local procedure InsertExercise(ExerciseNo: Integer; ExerciseId: Enum "Workshop Exercise"; Name: Text[100]; Description: Text[250]; TargetTimeMs: Integer; Iterations: Integer)
    var
        Exercise: Record "Workshop Exercise";
    begin
        Exercise.Init();
        Exercise."Exercise No." := ExerciseNo;
        Exercise."Exercise Id" := ExerciseId;
        Exercise.Name := Name;
        Exercise.Description := Description;
        Exercise."Target Time (ms)" := TargetTimeMs;
        Exercise.Iterations := Iterations;
        Exercise.Status := Exercise.Status::"Not Run";
        Exercise.Insert(false);
    end;
}
