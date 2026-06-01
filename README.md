# Karl Mobile - Document Management System with AI

A modern mobile application for document management with AI integration, approval workflow system, and Firebase backend.

## Screenshots

> Add UI screenshots to the `screenshots/` folder and update paths below

| Login | Documents | AI Chat | Approvals |
|-------|-----------|---------|-----------|
| ![Login](<img width="605" height="770" alt="image" src="https://github.com/user-attachments/assets/3d56f47d-1f80-4f4a-af5e-938cf68dd9f0" />
) | ![Documents](<img width="618" height="493" alt="image" src="https://github.com/user-attachments/assets/c56adb74-df91-4c88-84e0-c9c01f08a880" />
) | ![AI Chat](<img width="599" height="792" alt="image" src="https://github.com/user-attachments/assets/ee666d23-6cd4-46fb-897b-9c56171428ba" />
) | ![Approvals](<img width="600" height="779" alt="image" src="https://github.com/user-attachments/assets/6cc53135-3b4b-4dc5-a23a-89d0bb3947a0" />
) |

| QR Validation | Archive | Settings | Dark Theme |
|---------------|---------|----------|------------|
| ![QR](<img width="569" height="382" alt="image" src="https://github.com/user-attachments/assets/b34c6575-4a3f-4bee-aa9c-8e6575c53bab" />
) | ![Archive](<img width="600" height="780" alt="image" src="https://github.com/user-attachments/assets/51664739-b053-46ae-aab7-8cbc57c1aebc" />
) | ![Settings](<img width="606" height="794" alt="image" src="https://github.com/user-attachments/assets/5e8edfb0-469a-4c73-bbbd-ac95aad2eda5" />
) | ![Dark](<img width="614" height="784" alt="image" src="https://github.com/user-attachments/assets/eb3bcde6-a804-4bd7-bd2e-f69aaa1f918d" />
) |

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
