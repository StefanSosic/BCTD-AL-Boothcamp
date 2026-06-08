enum 80101 "Workshop Exercise Status"
{
    Extensible = false;

    value(0; "Not Run")
    {
        Caption = 'Not Run';
    }
    value(1; Passed)
    {
        Caption = '✅ Passed';
    }
    value(2; Failed)
    {
        Caption = '❌ Failed';
    }
}
