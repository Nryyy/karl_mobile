# karl_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

## Firebase Setup

This project uses generated Firebase platform options in
`lib/firebase_options.dart`. The file is ignored by git, so generate it before
running the app, tests, or any CI build on a clean checkout.

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=yourproject --platforms=android,ios,web \
	--out=lib/firebase_options.dart
```

In CI, run the same generation step before `flutter analyze`, `flutter test`,
or `flutter build` if the file is not committed.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
