query 80108 "WS Location Revenue"
{
    // Query for Exercise 43 — AL-Side Grouping vs. SQL GROUP BY
    // Aggregates total Line Amount and record count per Location Code
    // from active Workshop Data entries (positive Line Amount).
    // SQL generated: SELECT "Location Code", SUM("Line Amount"), COUNT("Entry No.")
    //                FROM "Workshop Data$..."
    //                WHERE Active = 1 AND "Line Amount" > 0
    //                GROUP BY "Location Code"
    //                ORDER BY "Location Code"
    // This is a single SQL round-trip regardless of how many locations exist.
    QueryType = Normal;

    elements
    {
        dataitem(Workshop_Data; "Workshop Data")
        {
            DataItemTableFilter = Active = const(true), "Line Amount" = filter(> 0);

            column(Location_Code; "Location Code")
            {
                // GROUP BY column — SQL groups rows by this value
            }
            column(Sum_Line_Amount; "Line Amount")
            {
                Method = Sum;
                // Translates to SUM("Line Amount") in SQL
            }
        }
    }
}
