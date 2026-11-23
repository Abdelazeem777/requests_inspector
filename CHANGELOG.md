## 6.0.0

### Breaking changes

- The minimum supported versions, Dart `3.10` and Flutter `3.38.1`, are now declared explicitly in `pubspec.yaml`. 5.5.1 already needed them through `share_plus ^13.1.0`, so this is not a new restriction.
- `sensors_plus` is now `^7.0.0` (was `^6.1.1`). If your app, or another package it uses, depends on `sensors_plus` 6, upgrade it to 7 or dependency resolution fails.
- `graphql_flutter`, `connectivity_plus` and `collection` are no longer dependencies (the package never used them). If you relied on getting them transitively through `requests_inspector`, add them to your own `pubspec.yaml`.
- `RequestMethod` has two new values, `HEAD` and `OPTIONS`. If you have an exhaustive `switch` over `RequestMethod`, add the new cases.
- `onStoppingRequest`: the `RequestDetails` your callback receives now has the URL without its query string; all query parameters, including the ones written in the URL, are in `queryParameters`. If your callback reads or rewrites the query in `url`, use `queryParameters` instead.
- The generated `cURL` commands now quote every argument with single quotes (URL, headers and body, e.g. `curl -X GET 'https://x/y' -H 'k: v'`), send bodies with `--data-raw` instead of `-d` and multipart text fields with `--form-string` instead of `-F`, use `curl -I` for `HEAD` requests (without a body, which curl can't send with `-I`), and send `String` bodies as they are instead of JSON-encoding them a second time. If you compare against the old output, update it.

### Fixes and improvements

- Fix the type mismatch crash when a response body is a plain `bool`, `int` or `double`, and keep String bodies intact after editing them in the Stopper. Special thanks to [Nourhan Sabrii](https://github.com/NourSabry) for this fix! 🎉
- Update the dependencies and resolve the lint warnings and deprecations. Special thanks to [Sahad2701](https://github.com/Sahad2701) for this contribution! 🎉
- Failed GraphQL `HttpLink` requests (e.g. a `400` response) are now logged by `GraphQLInspectorLink` instead of looking as if nothing was sent (fixes [#69](https://github.com/Abdelazeem777/requests_inspector/issues/69)), and GraphQL requests now show their durations. Special thanks to [MAlazhariy](https://github.com/MAlazhariy) for this contribution! 🎉
- Search on the request details page now shows the correct match count and no longer highlights overlapping matches.
- Add support for `HEAD` and `OPTIONS` requests: they are logged and can be shared as a log, a `cURL` command (`curl -I` for `HEAD`) or HAR. Requests with an unknown method (e.g. `TRACE`) no longer crash; they are sent as usual, just not logged.
- Request Stopper: the editor now shows the URL without its query and the whole query (including parameters written in the URL) in the query parameters field, and the request is sent with exactly the edited query parameters. Parameters are no longer duplicated, and deleting keys (or replacing the content with `{}`) really removes them from the request. An empty or invalid query parameters field still keeps the last valid value.
- The Stopper editors no longer lose the cursor, or an edit in progress, when the keyboard opens or changes size.
- Generated `cURL` commands are now shell-safe: quotes, `$` and backticks in the URL, headers or body no longer break the command, and a body or form field that starts with `@` is sent as text instead of making curl read a local file.
- HAR export: `creator.version` is now the real package version (it was always `5.1.1`), `postData` is left out for requests without a body (as HAR 1.2 expects), and the shared HAR file is named `request.har` instead of a random `<uuid>.json`.
- The URL copy icon on the request details page copies the plain URL, without quotes.
- The Dark Mode switch in the inspector menu now updates as soon as you toggle it.
- Disposing a disabled `InspectorController` (e.g. one created by calling `InspectorController()` before `RequestsInspector`) no longer throws a `LateInitializationError`.
- Keep the host app accessible (VoiceOver, TalkBack and UI automation tools) while the inspector is enabled, and add tooltips, also read by screen readers, to the close button (`Close inspector`), the share button (`Share`) and the copy icons of the request details sections (`Copy URL`, `Copy Headers`, ...). Each copy icon is now its own button for screen readers and UI automation tools, instead of being merged into its section header.
- Android back button: it now closes the inspector's dialogs and menus first and then the inspector itself, instead of popping the page behind it. Known limitation: with Android predictive back, a back swipe while a page is pushed in the host app pops that hidden page and leaves the inspector open.
- `ShowInspectorOn.Shaking` now falls back to long press on web and desktop, where shaking isn't available.
- README: wrap the whole `MaterialApp` with `RequestsInspector` rather than using `MaterialApp.builder` so the back button works as described above, fix the code samples and the images that showed up as text.
- Add the repository, issue tracker and topics to the package metadata.

## 5.5.1

- Upgrade `connectivity_plus` to `^7.3.1`.

## 5.5.0

- Fix request details card background color rendering.
- Add unit tests for `InspectorController` and upgrade dependencies.

## 5.4.0

- Add Search feature on the request details page.

Special thanks to [amirbahrawy](https://github.com/amirbahrawy) and [Nourhan Sabrii](https://github.com/NourSabry) for this amazing contribution! 🎉

## 5.3.0

- New Search and Filters for Requests List.
- Add filters for Request and Response Stopper.

Special thanks to [Hamid Montazeri](https://github.com/hamidhandid) for this amazing contribution that makes the inspector much more powerful and user-friendly! 🎉

- Add Expand/Collapse json objects switch button for the JSON Tree View.

Special thanks to [MohamedGawdat](https://github.com/MohamedGawdat) for this amazing contribution! 🎉

## 5.2.2

- Fix Selectable text at normal view (#55), thanks to [Nourhan Sabrii](https://github.com/NourSabry).
- Upgrade `share_plus` to `^12.0.1` to fix iOS crash when `sharePositionOrigin` is missing.

## 5.2.1

- Enhance json pretty converter `convert` method to handle additional data types including bool, num, and null.
- Update README.md file with the new HAR file support.

## 5.2.0

- Add support for sharing HAR files.

## 5.1.1

- Add `defaultTreeViewEnabled` parameter to `RequestsInspector` widget to control the initial state of the JSON tree view.

```dart
RequestsInspector(
  defaultTreeViewEnabled: false,
  child: MyApp(),
);
```

## 5.1.0

- **FormData Inspection Support**: Now you can inspect FormData requests with proper formatting and display, thanks to [Mostafa Alazhariy](https://github.com/MAlazhariy).
- **Cloudflare Protection Fix**: Bypass Cloudflare protection errors in example app by adding browser-like headers, thanks to [mostafaelzahry](https://github.com/mostafaelzahry).
- **Fix Context Menu Issue**: Added custom `contextMenuBuilder` to all `SelectableText` widgets to prevent context menu conflicts and improve text selection behavior, thanks to [Nourhan Sabrii](https://github.com/NourSabry).
- **Upgrade Dependencies**: Upgraded `gql` package to latest stable version `1.0.0`.
- **Code Quality Improvements**: Major code refactoring with clean up formatting and improved readability across multiple files.

## 5.0.3

- Add status code and headers input fields in `Responses Stopper` Dialog.

## 5.0.2

- Set `initiallyExpanded` to `true` by default.

## 5.0.1

- Update dependencies, thanks to [ahmedsabahi](https://github.com/ahmedsabahi).

## 5.0.0

- 🌗 **Dark/Light Mode Toggle**: Automatically adapts to system theme or user preference with manual toggle option.
- 📋 **Click to Copy Content**: Makes it easier to copy values such as headers, URLs, and JSON content with a single tap.
- 📂 **Expandable/Collapsible Sections**: Improves navigation by letting users toggle visibility of large sections like headers, request/response bodies, etc.
- 🌳 **JSON Tree View**: Added JSON-Tree display option with a structured, interactive tree view — expandable and more readable.
- 🎨 **UI/UX Refinements**: Added spacing, border radius, section highlights, and consistent padding for better layout and readability in both light and dark modes.
- Major code refactoring with better separation of concerns and improved widget structure.
- Enhanced user experience with modern, clean interface design.

Special thanks to [BelalNayzak](https://github.com/BelalNayzak) for this amazing contribution that makes the inspector much more powerful and user-friendly! 🎉

## 4.2.3

- Add `ShareType` enum to choose the type of the share content and `Both` option to share both `cURL` and `Normal Log`.

## 4.2.2

- When there is data from error, show error first [#44](https://github.com/Abdelazeem777/requests_inspector/pull/44), thanks to [AnthonyXcode](https://github.com/AnthonyXcode)

## 4.2.1

- Fix `connectivity_plus` version dependency issue with `graphql` thanks to [MohamedGawdat](https://github.com/MohamedGawdat)

## 4.2.0

- Support Flutter v3.27.0 thanks to [MAlazhariy](https://github.com/MAlazhariy)

## 4.1.2

- Dispose singleton when dispose notifier thanks to [AnthonyXcode](https://github.com/AnthonyXcode).

## 4.1.1

- Downgrade `connectivity_plus` to the most suitable version.

## 4.1.0

- Start depending on `sensor_plus` instead of using `shake` package to handle the shaking event.
- Start using flutter v3.19.6.
- Increase the version to `4.1.0` because the `4.0.4` version is a sign of trouble 😅.

## 4.0.4

- Add a stunning and captivating new logo, thanks to the incredibly talented [Yumna Hossam](https://www.behance.net/yumnahossam). 🎉️🎉️
- Update documentation (`README.md`) file.

## 4.0.3

- Update documentation (`README.md`) file.

## 4.0.2

- Revert the latest solution provided on v4.0.1 because of related issue with `flutter_zoom_drawer` package.

## 4.0.1

- Update README.md file.
- Reverse between the `child` widget and the `Inspector` widget on the internal PageView to start with `Inspector` first.

## 4.0.0

- Completely new UI theme for the inspector. 🎉️🎉️
- Enhance user experience and texts readability. 😃

## 3.5.0

- Add the ability to intercept the response before sending it to the client and modify it. 🥳
- Renamed the Request intercept and Response intercept to `Stopper` so now both come under `Request Stopper` and `Response Stopper` respectively .

## 3.4.1

- Update showInspectorOn enum value from Shaking to Both.

## 3.4.0

- Add the ability to intercept the request before sending it to the server and modify it.

## 3.3.2

- Add request Duration to the request details for HTTP and GraphQL.

## 3.3.1

- Add support for Flutter v3.16.\*, thanks to [the-best-is-best](https://github.com/the-best-is-best).
- Upgrade `gql` package to v1.0.0+1.

## 3.3.0

- Increase the shaking count to 3 times to open the inspector.
- Remove HasuraGraphQL support for now because of the packages conflicts.

## 3.2.1

- Fix `hideInspectorBanner: true` no longer crashes the app, thanks to [vlytvyne](https://github.com/vlytvyne).

- Fix `ShowInspectorOn.LongPress` not working if `ShowInspectorOn.Shaking` is set, thanks to [vlytvyne](https://github.com/vlytvyne).

- Update README.md file.

## 3.2.0

- Now you can share your request as a `cURL` command. 🥳
  <br>

  **Note:**
  You can use `cURL` command to send the request again from your terminal.
  _OR_
  You can import the command to [Postman](https://www.postman.com/) to send the request again for more flexibility and control on the debugging process. 💪💪

## 3.1.2

- Upgrade `share_plus` v7.0.2.

## 3.1.1

- Refactoring the `example` project for better understanding thanks to [Moaz El-sawaf](https://github.com/moazelsawaf).
- Support flutter latest version v3.10.6.

## 3.1.0

- `WebSocketLink` is supported using the normal `GraphQLInspectorLink`.

## 3.0.1

- Fix share request bug with the iPad.

## 3.0.0

- Presenting `GraphQLInspectorLink` for supporting `GraphQL` clients. 🎉️
  (Thanks to [Abdelrahman Tareq](https://github.com/AbdoTareq) PR ).

- Some Refactoring for `HasuraGraphQL` support.

## 2.5.0

- Support `HasuraGraphQL`.

## 2.4.0

- Support `Dio` v5.

## 2.3.5

- Reformat shared text to be more readable.

## 2.3.4

- Support `Flutter 3`.
- Update `Share_plus` version.

## 2.3.3

- Extract built-in params from the url using `RequestsInspectorInterceptor`.

## 2.3.2

- Fix run again bug with `RequestsInspectorInterceptor` while using `baseUrl`.

## 2.3.1

- Fix json converter bug with FormData on share bug.

## 2.3.0

- Add share button to share request content.
- Add unique black border to the selected requests.

## 2.2.1

- Fix Nested `MaterialApp` bug with `Navigator` and `BuildContext`.
- Some UI enhancement.

## 2.2.0

- Add `Run again` button to rerun the `selectedRequested` from the package itself.
- Add `Clear all` button to remove all `RequestsDetails` from requests list.

## 2.1.2

- UI enhancement.

## 2.1.1

- Fix `UNIDENTIFIED` error.

## 2.1.0

- New UI theme is implemented.

## 2.0.2

- Fix `requestBody` not showing when using `RequestsInspectorInterceptor` bug.

## 2.0.1

- Fix supported platforms problem.

## 2.0.0

- Add support for Web, MacOs, Windows and Linux.
- More screenshots for the other platforms.
- `sentTime` now is optional and the default value is `DateTime.now()`.
- Add better explanation for usage of `ShowInspectorOn{LongPress, Shaking, Both}` enum with `RequestInspector` widget.

## 1.2.2

- Enhance time text appearance on SelectedRequest tab.
- Fix selecting the current selected request not moving the SelectedRequest Tab bug.

## 1.2.1

- Fix bug with `RequestInspectorInterceptor` to handle request onError.

## 1.2.0

- Add support for `queryParameters` if not send inside the `url`.

```dart
final params = {'userId': 1};

InspectorController().addNewRequest(
    RequestDetails(
      ...
      queryParameters: params,
      ...
```

## 1.1.3+7

- Add `RequestsInspectorInterceptor` that can be used with `Dio` instead of using normal `InspectorController.addRequest` method.

## 1.0.3+6

- Add an option for opening inspector by passing `showInspectorOn` to `RequestsInspector` widget.

**by default it is `Shaking`.**

```dart
enum ShowInspectorOn {
  LongPress,
  Shaking,
  Both,
}
```

## 1.0.2+5

- Reset `MaterialApp` widget back because of select text feature was not working correctly.

## 1.0.1+4

- Remove `Navigator` from the `Inspector` widget tree.

## 1.0.0+3

- Make sure the shaking sensor closed on dispose.
- Move package to stable version `v1.0.0+3`.

## 0.0.2+2

- Rename `RequestsInspectorController` to `InspectorController` to solve naming confusion.
- Add full example on `README.md` file.

## 0.0.1+1

- Fix screenshots on `README.md` file.

## 0.0.1

- Initial release.
