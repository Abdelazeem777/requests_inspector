# requests_inspector

A new Flutter package project.

## First, add it at the top of your `MaterialApp` with `enabled: true`.

```dart
void main() {
  runApp(const RequestsInspector(
    enabled: true,
    child: MyApp(),
  ));
}

```

## Then, on your request add new `RequestDetails` using `RequestInspectorController`.

```dart
RequestsInspectorController().addNewRequest(
    RequestDetails(
        requestName: requestName,
        requestMethod: RequestMethod.GET,
        url: apiBaseUrl,
        statusCode: response.statusCode,
        headers: headers,
        responseBody: response.data,
        sentTime: DateTime.now()),
    );
```

## And we are done!

Note:
you can access `RequestInspector` widget by long press on any place on your screen.
