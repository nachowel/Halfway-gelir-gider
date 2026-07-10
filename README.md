# gider

A new Flutter project.

## Android APK build

Create `.env.app.local` from `.env.app.example` and include only the public
Flutter app values:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_public_anon_or_publishable_key
```

Do not put `SUPABASE_SERVICE_ROLE_KEY` in `.env.app.local`; service-role keys
must never be shipped in a mobile app.

Build the APK with:

```powershell
flutter build apk --release --dart-define-from-file=.env.app.local
```

The APK is written to `build\app\outputs\flutter-apk\app-release.apk`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
