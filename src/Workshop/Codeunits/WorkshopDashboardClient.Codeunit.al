codeunit 80104 "Workshop Dashboard Client"
{
    /// <summary>
    /// Sends attendee registration and exercise run results to the live TV dashboard.
    /// All calls are fire-and-forget: errors are silently swallowed so a missing
    /// or unreachable dashboard never disrupts the workshop flow.
    /// </summary>

    procedure InitializeAttendee(Attendee: Record "Workshop Attendee")
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        Response: HttpResponseMessage;
        JsonText: Text;
        ErrorText: Text;
        CallFailedMsg: Label 'Dashboard call failed.\URL: %1\Error: %2', Comment = '%1 = URL, %2 = error message';
    begin
        if Attendee."Dashboard URL" = '' then exit;

        JsonText := BuildAttendeeJson(Attendee);
        Content.WriteFrom(JsonText);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        if not Client.Post(BaseUrl(Attendee."Dashboard URL") + '/api/attendee', Content, Response) then begin
            Message(CallFailedMsg, Attendee."Dashboard URL", 'Connection failed. Check the URL is HTTPS and reachable.');
            exit;
        end;

        if not Response.IsSuccessStatusCode() then begin
            ErrorText := Response.ReasonPhrase;
            Message(CallFailedMsg, Attendee."Dashboard URL",
                Format(Response.HttpStatusCode()) + ' ' + ErrorText);
        end;
    end;

    procedure PostExerciseResult(Exercise: Record "Workshop Exercise")
    var
        Attendee: Record "Workshop Attendee";
        AllExercises: Record "Workshop Exercise";
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        Response: HttpResponseMessage;
        JsonText: Text;
        TotalExercises: Integer;
        PassedCount: Integer;
    begin
        if not Attendee.Get('') then exit;
        if Attendee."Dashboard URL" = '' then exit;

        TotalExercises := AllExercises.Count();
        AllExercises.SetRange(Status, Enum::"Workshop Exercise Status"::Passed);
        PassedCount := AllExercises.Count();

        JsonText := BuildExerciseJson(Exercise, Attendee, TotalExercises, PassedCount);
        Content.WriteFrom(JsonText);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        // Fire-and-forget — ignore result so a dead dashboard never blocks an exercise run
        Client.Post(BaseUrl(Attendee."Dashboard URL") + '/api/exercise', Content, Response);
    end;

    local procedure BaseUrl(Url: Text): Text
    begin
        exit(Url.TrimEnd('/'));
    end;

    local procedure BuildAttendeeJson(Attendee: Record "Workshop Attendee"): Text
    var
        Json: JsonObject;
        JsonText: Text;
    begin
        Json.Add('firstName', Attendee."First Name");
        Json.Add('lastName', Attendee."Last Name");
        Json.Add('email', Attendee.Email);
        Json.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure BuildExerciseJson(Exercise: Record "Workshop Exercise"; Attendee: Record "Workshop Attendee"; TotalExercises: Integer; PassedCount: Integer): Text
    var
        Json: JsonObject;
        JsonText: Text;
    begin
        Json.Add('attendeeEmail', Attendee.Email);
        Json.Add('exerciseNo', Exercise."Exercise No.");
        Json.Add('name', Exercise.Name);
        Json.Add('status', Format(Exercise.Status));
        Json.Add('lastRunMs', Exercise."Last Execution Time (ms)");
        Json.Add('targetMs', Exercise."Target Time (ms)");
        Json.Add('sqlRowsRead', Exercise."Last SQL Rows Read");
        Json.Add('sqlStatements', Exercise."Last SQL Statements");
        Json.Add('totalExercises', TotalExercises);
        Json.Add('passedCount', PassedCount);
        Json.WriteTo(JsonText);
        exit(JsonText);
    end;
}
