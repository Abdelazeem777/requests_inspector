## 0.0.1

- Initial release.

## 0.0.1+1

- Fix screenshots on `README.md` file.

## 0.0.2+2

- Rename `RequestsInspectorController` to `InspectorController` to solve naming confusion.
- Add full example on `README.md` file.

## 1.0.0+3

- Make sure the shaking sensor closed on dispose.
- Move package to stable version `v1.0.0+3`.

## 1.0.1+4

- Remove `Navigator` from the `Inspector` widget tree.

## 1.0.2+5

- Reset `MaterialApp` widget back because of select text feature was not working correctly.

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

## 1.1.3+7

- Add `RequestsInspectorInterceptor` that can be used with `Dio` instead of using normal `InspectorController.addRequest` method.

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

## 1.2.1

- Fix bug with `RequestInspectorInterceptor` to handle request onError.

## 1.2.2

- Enhance time text appearance on SelectedRequest tab.
- Fix selecting the current selected request not moving the SelectedRequest Tab bug.
