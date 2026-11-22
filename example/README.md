# example

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Maestro end-to-end flows

The flows in `.maestro/` drive this example app on a simulator/emulator.
They call real servers (https://dummyjson.com, https://postman-echo.com,
https://graphqlzero.almansi.me, https://raw.githubusercontent.com), so the
device needs network access. Install a debug build, then run Maestro against
it:

```sh
flutter run -d <device-id>          # installs the app; quit with q
maestro --device <device-id> test .maestro
```

Most flows use the Playground page (the flask icon in the app bar,
`lib/playground.dart`): it sends a request with every client the example
offers and shows what the app received. Its POST requests go to
postman-echo, which echoes the request it got, so a flow can check what the
request stopper really sent, what the response stopper handed to the app
(with the JSON type of every value), and what the share sheet and copy
buttons put on the clipboard ("Read clipboard").

| Flow | Covers |
| --- | --- |
| `inspector_smoke.yaml` | Long press opens the inspector, list, details, close button, Android back |
| `clients_and_details.yaml` | Dio (GET, POST JSON, FormData, HEAD, 404), GraphQL (with and without variables) and a manual `addNewRequest` in the list and on the details page |
| `list_search_filter_clear.yaml` | Search by URL, the filters dialog, Clear All |
| `details_view_options.yaml` | JSON Tree View, Expand Children and Dark Mode switches, search inside a request, Run again |
| `share_text.yaml` | Share as cURL Command, Normal Log and Both: the share sheet's text and what its Copy action copies |
| `share_har.yaml` | Share as HAR text (valid HAR JSON) and as a HAR file |
| `copy_buttons.yaml` | The copy icon of each details section |
| `request_stopper.yaml` | Stopper filters, editing a header, a query parameter and nested JSON values before sending, the method, and the ways out without edits |
| `response_stopper.yaml` | Stopper filters, editing the status code and the JSON body the app receives (types kept), the ways out without edits |
