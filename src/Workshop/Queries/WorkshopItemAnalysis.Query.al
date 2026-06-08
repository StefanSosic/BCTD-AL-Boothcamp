query 80100 "Workshop Item Analysis"
{
    // This query is the SOLUTION for Exercise 27.
    // Attendees should discover they need to use a Query instead of nested loops.
    // Joins WorkshopData (active items) with WorkshopSalesData to aggregate
    // total sales amount, total quantity, and line count per item — one SQL round-trip.
    QueryType = Normal;
    Caption = 'Workshop Item Analysis';

    elements
    {
        dataitem(WorkshopData; "Workshop Data")
        {
            DataItemTableFilter = Active = const(true), "Item No." = filter('<>');

            column(ItemNo; "Item No.")
            {
            }
            dataitem(WorkshopSalesData; "Workshop Sales Data")
            {
                DataItemLink = "Item No." = WorkshopData."Item No.";
                SqlJoinType = InnerJoin;

                column(TotalAmount; "Line Amount")
                {
                    Method = Sum;
                }
                column(TotalQuantity; Quantity)
                {
                    Method = Sum;
                }
            }
        }
    }
}
