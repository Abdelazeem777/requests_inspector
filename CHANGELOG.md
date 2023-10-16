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
