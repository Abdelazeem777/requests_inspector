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

## Maestro smoke test

The flows in `.maestro/` drive this example app (it calls
https://dummyjson.com, so the device needs network access). Install a debug
build on a simulator/emulator, then run Maestro against it:

```sh
flutter run -d <device-id>          # installs the app; quit with q
maestro --device <device-id> test .maestro
```
