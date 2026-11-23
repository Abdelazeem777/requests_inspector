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

The flows in `.maestro/` drive the Playground app (`lib/playground_main.dart`,
a separate entrypoint, so this example stays simple) on a simulator/emulator.
They call real servers (https://dummyjson.com, https://postman-echo.com,
https://graphqlzero.almansi.me, https://raw.githubusercontent.com), so the
device needs network access. Install a debug build of the Playground, then run
Maestro against it:

```sh
flutter run -d <device-id> -t lib/playground_main.dart   # installs the app; quit with q
maestro --device <device-id> test .maestro
```

The flows find the share button by its `Share` tooltip, so they need a version
of the package that has it. The copy icons' tooltips (`Copy URL`, ...) are not
reachable through accessibility, so those icons are tapped by position inside
their section header.

The Playground sends a request with every client the example offers and shows
what the app received. Its POST requests go to postman-echo, which echoes the
request it got, so a flow can check what the request stopper really sent, what
the response stopper handed to the app (with the JSON type of every value), and
what the share sheet and copy buttons put on the clipboard ("Read clipboard").

| Flow | Covers |
| --- | --- |
| `inspector_smoke.yaml` | Long press opens the inspector, list, details, close button, Android back |
| `clients_and_details.yaml` | Dio (GET, POST JSON, FormData, HEAD, 404), GraphQL (with and without variables) and a manual `addNewRequest` in the list and on the details page |
| `list_search_filter_clear.yaml` | Search by URL, the filters dialog, Clear All |
| `details_view_options.yaml` | JSON Tree View, Expand Children and Dark Mode switches (they flip while the menu is open), search inside a request, Run again |
| `share_text.yaml` | Share as cURL Command (`--data-raw`, `curl -I` for HEAD), Normal Log and Both: the share sheet's text and what its Copy action copies |
| `share_har.yaml` | Share as HAR text (valid HAR JSON, `creator.version` is the package version) and as a HAR file (`request.har`) |
| `copy_buttons.yaml` | The copy icon of each details section (the URL is copied without quotes) |
| `request_stopper.yaml` | Stopper filters, editing a header, a query parameter (one tap in a field puts the cursor there) and nested JSON values before sending, the method, and the ways out without edits |
| `response_stopper.yaml` | Stopper filters, editing the status code and the JSON body the app receives (types kept), the ways out without edits |
