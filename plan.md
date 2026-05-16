# Project Delilah — Flutter Implementation Plan

> **Stack:** Flutter · Riverpod · GoRouter · Dio · PocketBase · Cloudinary · FastAPI (Vertex AI)
> **API Base:** `https://project-delilah.mooo.com`
> **PocketBase:** `https://project-delilah-pb.mooo.com`
> **Cloudinary Cloud:** `dyaclvpsc` · Upload Preset: `delilah`

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Directory Structure](#2-directory-structure)
3. [Environment & Config Setup](#3-environment--config-setup)
4. [Phase 1 — Core Infrastructure](#4-phase-1--core-infrastructure)
5. [Phase 2 — Auth Feature](#5-phase-2--auth-feature)
6. [Phase 3 — Image Generation Endpoint (`/api/generate`)](#6-phase-3--image-generation-endpoint-apigenerate)
7. [Phase 4 — Virtual Try-On Endpoint (`/api/tryon`)](#7-phase-4--virtual-try-on-endpoint-apitryon)
8. [Phase 5 — History Feature](#8-phase-5--history-feature)
9. [Phase 6 — Glassmorphic Design System](#9-phase-6--glassmorphic-design-system)
10. [Phase 7 — Router & Navigation Guards](#10-phase-7--router--navigation-guards)
11. [Data Flow Reference](#11-data-flow-reference)
12. [AI Drop-In Rules for New Endpoints](#12-ai-drop-in-rules-for-new-endpoints)
13. [Dependencies Checklist](#13-dependencies-checklist)

---

## 1. Project Overview

Project Delilah is a Flutter mobile app that lets authenticated users:

- Generate AI images via a FastAPI `/api/generate` endpoint (backed by Vertex AI)
- Perform virtual clothing try-ons via `/api/tryon`
- Browse a personal gallery of past generations pulled from PocketBase `history_logs`
- Apply any generated image as a device wallpaper

Authentication is handled entirely through PocketBase. Every FastAPI call is automatically decorated with the user's PocketBase JWT via a Dio interceptor. Successful generation results are silently logged to PocketBase for history tracking. Cloudinary stores all generated media assets.

---

## 2. Directory Structure

```
lib/
├── core/
│   ├── network/
│   │   ├── dio_client.dart           # Dio instance → https://project-delilah.mooo.com
│   │   └── pb_interceptor.dart       # Reads PB JWT → injects Bearer header
│   ├── services/
│   │   └── pb_service.dart           # PocketBase singleton → https://project-delilah-pb.mooo.com
│   ├── theme/
│   │   └── glass_theme.dart          # Colors, blurs, gradients, typography tokens
│   └── router.dart                   # GoRouter: routes + auth guards
│
├── shared/
│   ├── utils/
│   │   └── wallpaper_engine.dart     # Download Cloudinary URL → apply as wallpaper
│   └── widgets/
│       ├── glass_card.dart           # BackdropFilter blur container
│       ├── glass_input.dart          # Frosted text field
│       ├── glass_button.dart         # Frosted CTA button with loading state
│       └── async_value_widget.dart   # Unified AsyncValue<T> renderer
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart  # PB email/password sign-in, sign-out, register
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart    # AuthStateNotifier — tracks session validity
│   │
│   ├── history/
│   │   ├── data/
│   │   │   └── history_repository.dart  # PB collection: history_logs
│   │   ├── presentation/
│   │   │   ├── history_screen.dart       # Masonry grid gallery
│   │   │   └── history_detail_sheet.dart # Bottom sheet with wallpaper CTA
│   │   └── providers/
│   │       └── history_provider.dart
│   │
│   └── endpoints/
│       ├── image_generation/
│       │   ├── data/
│       │   │   ├── image_gen_model.dart      # Request/Response Dart models
│       │   │   └── image_gen_repository.dart # POST → /api/generate → returns secure_url
│       │   ├── presentation/
│       │   │   └── image_gen_screen.dart     # Prompt input + result viewport
│       │   └── providers/
│       │       └── image_gen_provider.dart   # AsyncNotifier<String?> (secure_url)
│       │
│       └── virtual_tryon/
│           ├── data/
│           │   ├── tryon_model.dart
│           │   └── tryon_repository.dart     # POST → /api/tryon (multipart)
│           ├── presentation/
│           │   └── tryon_screen.dart         # Person + garment image upload + result
│           └── providers/
│               └── tryon_provider.dart
│
└── main.dart
```

---

## 3. Environment & Config Setup

Create `lib/core/config.dart` — a single source of truth for all environment values. Do **not** commit secrets; use `--dart-define` or `flutter_dotenv` at build time.

```dart
// lib/core/config.dart
class AppConfig {
  static const fastApiBase    = 'https://project-delilah.mooo.com';
  static const pocketBaseUrl  = 'https://project-delilah-pb.mooo.com';
  static const cloudinaryCloud = 'dyaclvpsc';
  static const cloudinaryPreset = 'delilah';
}
```

> **Build command example:**
> ```bash
> flutter run \
>   --dart-define=FASTAPI_BASE=https://project-delilah.mooo.com \
>   --dart-define=PB_URL=https://project-delilah-pb.mooo.com
> ```

---

## 4. Phase 1 — Core Infrastructure

### 4.1 PocketBase Service (`lib/core/services/pb_service.dart`)

```dart
import 'package:pocketbase/pocketbase.dart';
import '../config.dart';

class PocketBaseService {
  late final PocketBase client;
  PocketBaseService() {
    client = PocketBase(AppConfig.pocketBaseUrl);
  }
}
```

Expose via Riverpod:

```dart
final pbServiceProvider = Provider<PocketBaseService>((_) => PocketBaseService());
final pbClientProvider  = Provider<PocketBase>((ref) => ref.watch(pbServiceProvider).client);
```

### 4.2 Bearer Token Interceptor (`lib/core/network/pb_interceptor.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:pocketbase/pocketbase.dart';

class PocketBaseAuthInterceptor extends Interceptor {
  final PocketBase _pb;
  PocketBaseAuthInterceptor(this._pb);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_pb.authStore.isValid) {
      options.headers['Authorization'] = 'Bearer ${_pb.authStore.token}';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept']       = 'application/json';
    super.onRequest(options, handler);
  }
}
```

### 4.3 Dio Client (`lib/core/network/dio_client.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pb_interceptor.dart';
import '../config.dart';

Dio createDioClient(PocketBase pb) {
  final dio = Dio(BaseOptions(
    baseUrl:        AppConfig.fastApiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 90), // AI generation can be slow
  ));
  dio.interceptors.add(PocketBaseAuthInterceptor(pb));
  // dev only: dio.interceptors.add(LogInterceptor(responseBody: true));
  return dio;
}

// Riverpod provider
final dioProvider = Provider<Dio>((ref) {
  final pb = ref.watch(pbClientProvider);
  return createDioClient(pb);
});
```

### 4.4 Wallpaper Engine (`lib/shared/utils/wallpaper_engine.dart`)

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';

class WallpaperEngine {
  static Future<bool> applyFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final dir      = await getTemporaryDirectory();
      final file     = File('${dir.path}/delilah_wallpaper.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return await AsyncWallpaper.setWallpaperFromFile(
        filePath:         file.path,
        wallpaperLocation: AsyncWallpaper.HOME_SCREEN,
      );
    } catch (_) {
      return false;
    }
  }
}
```

---

## 5. Phase 2 — Auth Feature

### 5.1 Auth Repository

```dart
// features/auth/data/auth_repository.dart
class AuthRepository {
  final PocketBase _pb;
  AuthRepository(this._pb);

  Future<RecordAuth> signIn(String email, String password) =>
      _pb.collection('users').authWithPassword(email, password);

  Future<RecordModel> register(String email, String password, String name) =>
      _pb.collection('users').create(body: {
        'email': email, 'password': password,
        'passwordConfirm': password, 'name': name,
      });

  void signOut() => _pb.authStore.clear();

  bool get isLoggedIn => _pb.authStore.isValid;
  RecordModel? get currentUser => _pb.authStore.record;
}
```

### 5.2 Auth Provider

```dart
// features/auth/providers/auth_provider.dart
sealed class AuthState {}
class AuthAuthenticated extends AuthState { final RecordModel user; AuthAuthenticated(this.user); }
class AuthUnauthenticated extends AuthState {}
class AuthLoading extends AuthState {}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repo = ref.read(authRepositoryProvider);
    return repo.isLoggedIn
        ? AuthAuthenticated(repo.currentUser!)
        : AuthUnauthenticated();
  }

  Future<void> signIn(String email, String password) async {
    state = AuthLoading();
    try {
      final result = await ref.read(authRepositoryProvider).signIn(email, password);
      state = AuthAuthenticated(result.record);
    } catch (e) {
      state = AuthUnauthenticated();
      rethrow;
    }
  }

  void signOut() {
    ref.read(authRepositoryProvider).signOut();
    state = AuthUnauthenticated();
  }
}
```

### 5.3 Screens

**`login_screen.dart`** — glassmorphic card with email + password `GlassInput` fields and a `GlassButton` that calls `authNotifier.signIn()`. Shows a `CircularProgressIndicator` while `AuthLoading`.

**`register_screen.dart`** — same pattern with name, email, password, confirm fields.

---

## 6. Phase 3 — Image Generation Endpoint (`/api/generate`)

### 6.1 Dart Models

```dart
// features/endpoints/image_generation/data/image_gen_model.dart

class ImageGenRequest {
  final String prompt;
  final String userId;        // PocketBase user ID for Cloudinary folder routing
  final String? negativePrompt;
  final int width;
  final int height;

  ImageGenRequest({
    required this.prompt,
    required this.userId,
    this.negativePrompt,
    this.width  = 1024,
    this.height = 1024,
  });

  Map<String, dynamic> toJson() => {
    'prompt':          prompt,
    'user_id':         userId,
    if (negativePrompt != null) 'negative_prompt': negativePrompt,
    'width':           width,
    'height':          height,
  };
}

class ImageGenResponse {
  final String secureUrl;     // Cloudinary CDN URL
  final String publicId;

  ImageGenResponse.fromJson(Map<String, dynamic> j)
    : secureUrl = j['secure_url'],
      publicId  = j['public_id'];
}
```

### 6.2 Repository

```dart
// features/endpoints/image_generation/data/image_gen_repository.dart
class ImageGenRepository {
  final Dio _dio;
  final PocketBase _pb;
  ImageGenRepository(this._dio, this._pb);

  Future<String> generate(ImageGenRequest request) async {
    // Step 1: Call FastAPI
    final response = await _dio.post('/api/generate', data: request.toJson());
    final result   = ImageGenResponse.fromJson(response.data);

    // Step 2: Log to PocketBase history_logs
    await _logToHistory(result, request.prompt);

    return result.secureUrl;
  }

  Future<void> _logToHistory(ImageGenResponse result, String prompt) async {
    final userId = _pb.authStore.record?.id;
    if (userId == null) return;

    await _pb.collection('history_logs').create(body: {
      'user':       userId,
      'type':       'image_generation',
      'prompt':     prompt,
      'image_url':  result.secureUrl,
      'public_id':  result.publicId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
```

### 6.3 Provider

```dart
// features/endpoints/image_generation/providers/image_gen_provider.dart
class ImageGenNotifier extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> generate(String prompt, {String? negativePrompt}) async {
    final userId = ref.read(pbClientProvider).authStore.record?.id ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(imageGenRepositoryProvider).generate(
        ImageGenRequest(
          prompt: prompt, userId: userId, negativePrompt: negativePrompt,
        ),
      )
    );
  }

  void reset() => state = const AsyncData(null);
}
```

### 6.4 Screen Layout (`image_gen_screen.dart`)

```
┌─────────────────────────────────────────────┐
│  [Blurred gradient background]              │
│                                             │
│  ┌─────────────────── GlassCard ──────────┐ │
│  │  🎨  Generate Image                    │ │
│  │                                        │ │
│  │  [GlassInput: Describe your image...]  │ │
│  │  [GlassInput: Negative prompt (opt)]   │ │
│  │                                        │ │
│  │  [GlassButton: Generate ▶]             │ │
│  └────────────────────────────────────────┘ │
│                                             │
│  ── Result Viewport ──                      │
│  [AsyncValue handler]                       │
│    Loading → shimmer placeholder            │
│    Data    → Image.network(secureUrl)       │
│             + [Set as Wallpaper] button     │
│    Error   → Error message glass card       │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 7. Phase 4 — Virtual Try-On Endpoint (`/api/tryon`)

### 7.1 Dart Models

```dart
// features/endpoints/virtual_tryon/data/tryon_model.dart
class TryOnRequest {
  final File personImage;   // User's photo
  final File garmentImage;  // Clothing item image
  final String userId;

  TryOnRequest({required this.personImage, required this.garmentImage, required this.userId});
}

class TryOnResponse {
  final String secureUrl;
  TryOnResponse.fromJson(Map<String, dynamic> j) : secureUrl = j['secure_url'];
}
```

### 7.2 Repository (Multipart)

```dart
// features/endpoints/virtual_tryon/data/tryon_repository.dart
class TryOnRepository {
  final Dio _dio;
  final PocketBase _pb;
  TryOnRepository(this._dio, this._pb);

  Future<String> tryOn(TryOnRequest request) async {
    final formData = FormData.fromMap({
      'user_id':       request.userId,
      'person_image':  await MultipartFile.fromFile(
                         request.personImage.path, filename: 'person.jpg'),
      'garment_image': await MultipartFile.fromFile(
                         request.garmentImage.path, filename: 'garment.jpg'),
    });

    final response = await _dio.post('/api/tryon',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final result = TryOnResponse.fromJson(response.data);
    await _logToHistory(result, request.userId);
    return result.secureUrl;
  }

  Future<void> _logToHistory(TryOnResponse result, String userId) async {
    await _pb.collection('history_logs').create(body: {
      'user':      userId,
      'type':      'virtual_tryon',
      'image_url': result.secureUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
```

### 7.3 Screen Layout (`tryon_screen.dart`)

```
┌─────────────────────────────────────────────┐
│  [Blurred gradient background]              │
│                                             │
│  👕  Virtual Try-On                         │
│                                             │
│  ┌── Upload Person ──┐  ┌── Garment ──────┐ │
│  │  [Image preview]  │  │  [Image preview] │ │
│  │  [Pick Photo btn] │  │  [Pick Photo btn]│ │
│  └───────────────────┘  └─────────────────┘ │
│                                             │
│  [GlassButton: Try On ▶]                    │
│                                             │
│  ── Result ──                               │
│  [AsyncValue → result image]                │
│  [Set as Wallpaper]                         │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 8. Phase 5 — History Feature

### 8.1 PocketBase Collection Schema — `history_logs`

| Field | Type | Notes |
|---|---|---|
| `user` | Relation → users | Required |
| `type` | Select | `image_generation`, `virtual_tryon` |
| `prompt` | Text (optional) | For generation only |
| `image_url` | URL | Cloudinary `secure_url` |
| `public_id` | Text (optional) | Cloudinary public ID |
| `created_at` | DateTime | Auto |

### 8.2 Repository

```dart
class HistoryRepository {
  final PocketBase _pb;
  HistoryRepository(this._pb);

  Future<List<RecordModel>> fetchUserHistory({int page = 1, int perPage = 24}) async {
    final userId = _pb.authStore.record?.id;
    if (userId == null) return [];
    return (await _pb.collection('history_logs').getList(
      page: page, perPage: perPage,
      filter: 'user = "$userId"',
      sort:   '-created',
    )).items;
  }
}
```

### 8.3 History Screen

Displays a masonry/staggered grid of `Image.network()` thumbnails from `history_logs`. Tapping a tile opens a `DraggableScrollableSheet` (bottom sheet) showing the full image, generation metadata, and the **Set as Wallpaper** button which calls `WallpaperEngine.applyFromUrl()`.

---

## 9. Phase 6 — Glassmorphic Design System

### 9.1 Theme Tokens (`lib/core/theme/glass_theme.dart`)

```dart
class GlassTheme {
  // Palette
  static const Color backgroundStart = Color(0xFF0D0D1A);
  static const Color backgroundEnd   = Color(0xFF1A0D2E);
  static const Color accent          = Color(0xFF7C4DFF);
  static const Color accentSecondary = Color(0xFF00E5FF);
  static const Color surfaceWhite    = Color(0x1AFFFFFF);  // 10% white
  static const Color borderWhite     = Color(0x33FFFFFF);  // 20% white
  static const Color textPrimary     = Color(0xFFFFFFFF);
  static const Color textSecondary   = Color(0xB3FFFFFF);  // 70% white

  // Blur values
  static const double blurCard  = 20.0;
  static const double blurInput = 12.0;

  // Border radius
  static const double radiusCard  = 20.0;
  static const double radiusInput = 12.0;
  static const double radiusButton = 14.0;

  // Gradient backgrounds
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentSecondary],
  );
}
```

### 9.2 Shared Widgets

**`GlassCard`** — wraps `BackdropFilter` + `ClipRRect` with frosted border. Use for all content containers.

**`GlassInput`** — `TextField` inside a `GlassCard` with `GlassTheme` styling. Exposes `controller`, `hint`, `icon`, `obscureText`.

**`GlassButton`** — gradient-background button with loading spinner. Exposes `onPressed`, `label`, `isLoading`, `icon`.

**`AsyncValueWidget<T>`** — generic widget that takes `AsyncValue<T>` and renders loading shimmer / error card / data via a builder callback.

---

## 10. Phase 7 — Router & Navigation Guards

```dart
// lib/core/router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState is AuthAuthenticated;
      final onAuth   = state.uri.path == '/login' || state.uri.path == '/register';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn  && onAuth)  return '/generate';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/generate', builder: (_, __) => const ImageGenScreen()),
          GoRoute(path: '/tryon',    builder: (_, __) => const TryOnScreen()),
          GoRoute(path: '/history',  builder: (_, __) => const HistoryScreen()),
        ],
      ),
    ],
  );
});
```

`AppShell` provides the persistent bottom navigation bar with tabs for Generate, Try-On, and History.

---

## 11. Data Flow Reference

```
User Action (UI)
      │
      ▼
Riverpod Provider (AsyncNotifier)
  state = AsyncLoading()
      │
      ▼
Data Repository
  Dio.post('https://project-delilah.mooo.com/api/...')
      │   ↑ PocketBaseAuthInterceptor injects Bearer JWT
      │
      ▼
FastAPI + Vertex AI
  Processes request
  Saves result to Cloudinary → returns { secure_url, public_id }
      │
      ▼
Data Repository
  PocketBase.collection('history_logs').create(...)  ← silent background log
      │
      ▼
Riverpod Provider
  state = AsyncData(secure_url)
      │
      ▼
UI renders result image + "Set as Wallpaper" CTA
      │
      ▼ (optional)
WallpaperEngine.applyFromUrl(secure_url)
  Download → local cache → AsyncWallpaper.setWallpaperFromFile()
```

---

## 12. AI Drop-In Rules for New Endpoints

When adding support for a new FastAPI endpoint, follow this exact checklist. Touch **only** a new folder under `features/endpoints/<endpoint_name>/`.

### Checklist

- [ ] **Read the endpoint definition** — method, path, request body schema, response schema
- [ ] **Create `data/` models** — `<name>_model.dart` with request/response Dart classes and `toJson()`/`fromJson()`
- [ ] **Create `data/` repository** — `<name>_repository.dart`
  - Use `ref.read(dioProvider)` for the HTTP call
  - On success, call `_pb.collection('history_logs').create(...)` with `user`, `type`, `image_url`
- [ ] **Create `providers/` notifier** — `<name>_provider.dart` extending `AutoDisposeAsyncNotifier<T>`
  - State: `null` → `AsyncLoading()` → `AsyncData(result)` or `AsyncError`
- [ ] **Create `presentation/` screen** — `<name>_screen.dart`
  - Use only `GlassCard`, `GlassInput`, `GlassButton`, `AsyncValueWidget` from `shared/widgets/`
  - Apply `GlassTheme` tokens for all colors, blurs, radii
  - Show loading shimmer when `AsyncLoading`, error card when `AsyncError`
  - Show result image + wallpaper CTA when `AsyncData`
- [ ] **Register route** — add `GoRoute` entry in `lib/core/router.dart`
- [ ] **Add nav tab** — add entry to `AppShell` bottom nav if the feature is user-facing

---

## 13. Dependencies Checklist

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management & navigation
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0

  # Network
  dio: ^5.4.3
  http: ^1.2.1

  # PocketBase
  pocketbase: ^0.21.0

  # Storage & wallpaper
  path_provider: ^2.1.3
  async_wallpaper: ^2.0.0

  # Image picking (for tryon)
  image_picker: ^1.1.0

  # UI utilities
  shimmer: ^3.0.0          # Loading skeletons
  cached_network_image: ^3.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

### Platform Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.SET_WALLPAPER"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick garment and person photos for virtual try-on.</string>
<key>NSCameraUsageDescription</key>
<string>Used to capture photos for virtual try-on.</string>
```

---

*End of Project Delilah Implementation Plan*
