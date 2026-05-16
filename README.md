# Delilah - AI Image Generation & Virtual Try-On App

<p align="center">
  <img src="assets/android-flutter-icon.png" alt="Delilah Logo" width="120">
</p>

<p align="center">
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/Built%20with-Flutter-blue.svg" alt="Built with Flutter">
  </a>
  <a href="https://pub.dev/packages/flutter_riverpod">
    <img src="https://img.shields.io/badge/State-Riverpod-success.svg" alt="Riverpod">
  </a>
  <a href="https://pub.dev/packages/go_router">
    <img src="https://img.shields.io/badge/Routing-GoRouter-orange.svg" alt="GoRouter">
  </a>
  <a href="https://pub.dev/packages/gal">
    <img src="https://img.shields.io/badge/Save-Gal-yellow.svg" alt="Gal">
  </a>
  <a href="https://pub.dev/packages/cloudinary">
    <img style="padding-left:5px" src="https://img.shields.io/badge/Storage-Cloudinary-purple.svg" alt="Cloudinary">
  </a>
</p>

---

## Overview

**Delilah** is a production-ready Flutter mobile application that provides AI-powered image generation and editing capabilities. The app connects to a FastAPI backend with Vertex AI for image processing and uses Cloudinary for image storage.

### Features

| Feature | Endpoint | Description |
|---------|----------|-------------|
| **Image Generation** | `/api/generate` | Generate stunning images from text prompts using Vertex AI Imagen |
| **Virtual Try-On** | `/api/tryon` | Try on clothes virtually by combining person photos with clothing items |
| **Image Editing** | `/api/edit` | Apply filters and semantic modifications to existing images |
| **Image Upscale** | `/api/upscale` | Enhance resolution and remove digital noise from images |
| **Product Makeover** | `/api/product-makeover` | Place products in contextual synthetic backgrounds |
| **Fix Old Image** | `/api/fixoldimage` | Restore old/damaged photos by removing artifacts |
| **Gallery** | `/api/gallery` | View, save, and manage all generated images |
| **Wallpaper** | - | Set any image as device wallpaper |

---

## Architecture

### Technology Stack

- **Frontend**: Flutter 3.11+ with Dart
- **State Management**: Riverpod 2.5+
- **Routing**: GoRouter 14+
- **HTTP Client**: Dio
- **Image Storage**: Cloudinary (unsigned uploads)
- **Secure Storage**: flutter_secure_storage (JWT tokens)
- **Image Saving**: Gal (gallery access)
- **Image Picking**: image_picker

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── config.dart              # API URLs and Cloudinary config
│   ├── router.dart              # GoRouter configuration with navigation
│   ├── network/
│   │   └── pb_interceptor.dart   # HTTP interceptors
│   ├── services/
│   │   ├── cloudinary_service.dart   # Cloudinary upload with caching
│   │   └── secure_storage.dart       # Token persistence
│   └── theme/
│       ├── theme_controller.dart     # Design tokens (colors, spacing)
│       └── glass_theme.dart          # Theme configuration
├── features/
│   ├── auth/                    # Authentication
│   │   ├── data/
│   │   │   └── auth_repository.dart  # Login/register API calls
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart    # Auth state management
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart      # Hero section + quick actions
│   ├── endpoints/
│   │   ├── image_generation/   # Generate images from prompts
│   │   ├── virtual_tryon/       # Virtual clothing try-on
│   │   ├── image_edit/         # Image editing & filters
│   │   ├── upscale/            # Image upscaling
│   │   ├── product_makeover/   # Product background change
│   │   └── fix_old_image/      # Photo restoration
│   └── history/
│       ├── presentation/
│       │   └── history_screen.dart  # Gallery with save/wallpaper
│       └── providers/
│           └── history_provider.dart # Gallery API state
└── shared/
    ├── widgets/
    │   ├── glass_button.dart   # Custom styled button
    │   ├── glass_input.dart    # Custom styled input
    │   └── async_value_widget.dart
    └── utils/
        └── wallpaper_engine.dart    # Android wallpaper setter
```

### State Management Pattern

The app uses **Riverpod** with a consistent pattern across all features:

1. **Provider**: Defines the state class (immutable data class)
2. **Notifier**: Handles state mutations and async operations
3. **Repository**: Makes API calls with proper auth headers
4. **Screen**: Consumes state via `ref.watch()` and triggers actions via `ref.read()`

Example pattern:
```dart
// State class
class TryOnState {
  final File? personImage;
  final String? resultUrl;
  final bool isGenerating;
  // ...
}

// Notifier
class TryOnNotifier extends Notifier<TryOnState> {
  Future<void> generate() async {
    state = state.copyWith(isGenerating: true);
    // API call...
    state = state.copyWith(resultUrl: result, isGenerating: false);
  }
}

// Provider
final tryOnNotifierProvider = NotifierProvider<TryOnNotifier, TryOnState>(() => TryOnNotifier());
```

---

## Backend API

### Authentication

The app uses JWT tokens from PocketBase for authentication.

**Login**: `POST /api/auth/login`
```json
{"email": "user@example.com", "password": "password"}
```

**Response**:
```json
{"token": "jwt_token_here"}
```

### Image Endpoints

All endpoints (except login/register) require `Authorization: Bearer <token>` header.

| Method | Endpoint | Request Body | Response |
|--------|----------|--------------|----------|
| POST | `/api/generate` | `{"prompt": "..."}` | `{"status": "success", "secure_url": "..."}` |
| POST | `/api/tryon` | `{"person_image_url": "...", "product_image_url": "..."}` | `{"status": "success", "secure_url": "..."}` |
| POST | `/api/edit` | `{"image_url": "...", "edit_prompt": "..."}` | `{"status": "success", "secure_url": "..."}` |
| POST | `/api/upscale` | `{"image_url": "...", "enhancement_focus": "..."}` | `{"status": "success", "secure_url": "..."}` |
| POST | `/api/product-makeover` | `{"product_image_url": "...", "background_context": "..."}` | `{"status": "success", "secure_url": "..."}` |
| POST | `/api/fixoldimage` | `{"image_url": "...", "repair_instructions": "..."}` | `{"status": "success", "secure_url": "..."}` |
| GET | `/api/gallery` | - | `{"images": [{"secure_url": "...", "public_id": "...", ...}]}` |
| DELETE | `/api/gallery` | `{"public_id": "..."}` | `{"success": true}` |

### Cloudinary Integration

Images are uploaded to Cloudinary with folder structure:
```
delilah_users/<email_cleaned>/<tag>/
```

Example: `delilah_users/user_example_com/generated_studio/`

---

## Design System

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| `canvasWhite` | `#FFFFFF` | Main background |
| `cohereBlack` | `#1A1A1A` | Primary text |
| `actionBlue` | `#4F46E5` | Primary actions |
| `softStone` | `#F3F4F6` | Card backgrounds |
| `hairline` | `#E5E7EB` | Borders |
| `mutedSlate` | `#6B7280` | Secondary text |
| `deepEnterpriseGreen` | `#10B981` | Success states |
| `errorRed` | `#EF4444` | Error states |

### Typography

Uses **Unica77** font family (via design tokens in `theme_controller.dart`):

- `headlineLarge`: 28px, bold
- `titleMedium`: 18px, semibold
- `bodyMedium`: 14px, regular
- `bodySmall`: 12px, regular

---

## Navigation

The app uses a **Shell Route** pattern with bottom navigation:

```
Home (default landing)
  └── Quick actions → Generate, Try-On, Edit, Gallery
  
Tools (modal menu)
  ├── Generate Image
  ├── Virtual Try-On
  ├── Edit Image
  ├── Upscale
  ├── Product Makeover
  └── Fix Old Image
  
Gallery
  └── Grid view → Detail sheet → Save/Wallpaper/Delete
  
Logout → Login screen
```

### Navigation Logic

- Unauthenticated users are redirected to `/login`
- Authenticated users on auth pages are redirected to `/home`
- Back gesture from any tool goes to Home (not exit app)
- Gallery auto-refreshes on first load only

---

## Building & Running

### Prerequisites

- Flutter 3.11+
- Dart 3.11+
- Android SDK with API 21+

### Development

```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Analyze code
flutter analyze

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Release Build

The release build uses a custom keystore located at `../keystore/release-key.jks`.

```bash
# Build release (signs with release key)
flutter build apk --release
```

---

## Permissions

### Android (AndroidManifest.xml)

- `INTERNET` - API calls
- `SET_WALLPAPER` - Set wallpaper feature
- `READ_EXTERNAL_STORAGE` (API ≤ 32) - Gallery access
- `WRITE_EXTERNAL_STORAGE` (API ≤ 29) - Save to gallery

---

## Key Implementation Details

### Cloudinary Upload with Caching

Images uploaded from device are cached by file path to avoid re-uploading the same image:

```dart
final cachedUrl = cloudinary.getCachedUrl(file.path);
if (cachedUrl != null) {
  state = state.copyWith(imageUrl: cachedUrl);
  return;
}
```

### Save to Gallery

Uses `gal` package for modern gallery access:

```dart
final tempDir = await getTemporaryDirectory();
final tempFile = File('${tempDir.path}/image.jpg');
await tempFile.writeAsBytes(response.bodyBytes);
await Gal.putImage(tempFile.path);
await tempFile.delete();
```

### Wallpaper Setting (Android)

Uses platform channel to set wallpaper with center-crop for proper aspect ratio:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
val wallpaperManager = WallpaperManager.getInstance(applicationContext)
wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
```

---

## Version History

| Version | Changes |
|---------|---------|
| 1.0.8 | Added launcher icons, assets folder |
| 1.0.6 | Fixed save image permission error |
| 1.0.5 | Add save/fullscreen to new endpoints, back gesture fix, gallery auto-refresh |
| 1.0.4 | Fix layout overflow in home screen modal |
| 1.0.3 | Add local image picker + Cloudinary upload, create homepage |
| 1.0.2 | Add missing API endpoints (edit, upscale, product-makeover, fixoldimage) |
| 1.0.1 | Add gallery delete functionality |
| 1.0.0 | Initial release with auth, generate, tryon, gallery |

---

## License

MIT License

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Run `flutter analyze` to check for issues
5. Commit with clear description
6. Push and create pull request