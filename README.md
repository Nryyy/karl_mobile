# Karl Mobile - Document Management System with AI

A modern mobile application for document management with AI integration, approval workflow system, and Firebase backend.

## Screenshots

> Add UI screenshots to the `screenshots/` folder and update paths below

| Login | Documents | AI Chat | Approvals |
|-------|-----------|---------|-----------|
| ![Login](screenshots/login.png) | ![Documents](screenshots/documents.png) | ![AI Chat](screenshots/ai_chat.png) | ![Approvals](screenshots/approvals.png) |

| QR Validation | Archive | Settings | Dark Theme |
|---------------|---------|----------|------------|
| ![QR](screenshots/qr_scan.png) | ![Archive](screenshots/archive.png) | ![Settings](screenshots/settings.png) | ![Dark](screenshots/dark_theme.png) |

## Features

### 📄 Document Management
- Create and edit documents
- Upload files via Firebase Storage
- Archive documents
- QR codes for quick document access

### 🤖 AI Assistant
- Document analysis using AI
- Interactive chat for questions
- Response generation based on document content

### ✅ Approval System
- Send documents for approval
- Approvals inbox for pending reviews
- Sign or reject with comments
- Track approval status

### 🔐 Authentication
- Email/Password registration and login
- Google Sign-In via Firebase Auth
- Password reset functionality

### 🎨 UI/UX
- Light and dark theme support
- Localization (EN/PL/UA)
- Smooth transition animations
- Responsive design

## Technologies

| Category | Technologies |
|----------|--------------|
| **Framework** | Flutter 3.x, Dart 3.x |
| **State Management** | Flutter Riverpod |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Navigation** | Go Router |
| **HTTP Client** | HTTP package with retry logic |
| **UI** | Material Design 3, Google Fonts |
| **QR Codes** | qr_flutter |
| **File Picker** | file_picker, image_picker |
| **Storage** | shared_preferences (local cache) |

## Architecture

The project is built using **Clean Architecture** principles with clear layer separation:

```
lib/
├── core/              # Base services and utilities
│   ├── config/        # Configuration (API, themes)
│   ├── http/          # HTTP client with retry logic
│   ├── providers/     # Global providers
│   └── services/      # Firebase services
├── features/          # Feature-based modules
│   ├── auth/          # Authentication (pages, providers, services)
│   ├── documents/     # Documents (pages, models, repository)
│   ├── ai_chat/       # AI chat (service, models, screens)
│   └── navigation/    # Navigation (dashboard, account, settings)
├── config/            # Routing (Go Router)
├── l10n/              # Localization (ARB files)
└── generated/         # Generated localization files
```

### Patterns
- **Repository Pattern** - data access abstraction
- **Provider Pattern** (Riverpod) - state management
- **Dependency Injection** - via providers

## Installation & Running

### Requirements
- Flutter SDK ^3.11.5
- Dart SDK ^3.11.5
- Firebase project

### Installation Steps

1. **Clone the repository**
```bash
git clone https://github.com/Nryyy/karl_mobile.git
cd karl_mobile
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase configuration**
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-firebase-project \
  --platforms=android,ios,web \
  --out=lib/firebase_options.dart
```

4. **Generate localization**
```bash
flutter gen-l10n
```

5. **Run the application**
```bash
# For development
flutter run

# For Android
flutter build apk --release

# For iOS (requires Mac and Xcode)
flutter build ios --release

# For Web
flutter build web --release
```

### Running Tests
```bash
flutter test
```

## Project Structure

| Path | Purpose |
|------|---------|
| `lib/core/services/` | Firebase services (Auth, Firestore, Storage, QR) |
| `lib/core/http/` | HTTP client with retry and error handling |
| `lib/core/config/` | API endpoints configuration |
| `lib/features/auth/` | Login, registration, password reset pages |
| `lib/features/documents/` | Documents, archive, approvals, QR history |
| `lib/features/ai_chat/` | AI chat interface and service |
| `lib/features/navigation/` | Dashboard, settings, account |
| `lib/config/router/` | Go Router configuration |
| `lib/l10n/` | ARB localization files |
| `test/` | Unit and widget tests |

## Firebase Setup

This project uses generated Firebase platform options in `lib/firebase_options.dart`. The file is git-ignored, so generate it before running:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=yourproject --platforms=android,ios,web \
	--out=lib/firebase_options.dart
```

In CI, run the same generation step before `flutter analyze`, `flutter test`, or `flutter build` if the file is not committed.

## API Endpoints

- `GET /api/Documents/sent-to-me/{userId}` - documents pending approval
- `POST /api/Documents/{id}/sign` - sign a document
- `POST /api/Documents/{id}/reject` - reject a document
- AI Chat API - integration with AI service

## License

MIT License - see [LICENSE](LICENSE) for details.

---

For Flutter development reference: [online documentation](https://docs.flutter.dev/)
