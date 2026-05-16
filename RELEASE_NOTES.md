# Delilah v1.0.8 - AI Image Studio

## 🎉 Release Highlights

**Delilah** is a production-ready Flutter mobile application providing AI-powered image generation and editing through Vertex AI and Cloudinary integration.

---

## ✨ What's New

### 🚀 AI Features
- **Image Generation** - Generate stunning images from text prompts using Vertex AI Imagen
- **Virtual Try-On** - Try on clothes virtually by combining person photos with clothing items
- **Image Editing** - Apply filters and semantic modifications to images
- **Image Upscale** - Enhance resolution and remove digital noise
- **Product Makeover** - Place products in contextual synthetic backgrounds
- **Photo Restoration** - Restore old/damaged photos by removing artifacts

### 🎨 UI/UX Improvements
- **Home Screen** - New hero section with quick action cards
- **Bottom Navigation** - Home | Tools | Gallery | Logout
- **Tools Menu** - Modal sheet with all AI tools accessible from anywhere
- **Launcher Icons** - Custom adaptive icons for Android

### 💾 Storage & Image Handling
- **Cloudinary Integration** - Images uploaded to user's personal folder (`delilah_users/<email>/`)
- **URL Caching** - Avoid re-uploading same images with file-path caching
- **Save to Gallery** - Download generated images to device
- **Set as Wallpaper** - Apply any image as device wallpaper
- **Fullscreen Viewer** - Tap images to view in fullscreen mode

### 🔐 Authentication
- **JWT Token Persistence** - Login state survives app restarts via flutter_secure_storage
- **Auto-Gallery Refresh** - Gallery loads on first startup, won't reload unless explicitly refreshed

---

## 🛠 Technical Changes

| Version | Changes |
|---------|---------|
| **1.0.8** | Added assets folder, custom launcher icons, hero icon in home screen |
| **1.0.6** | Fixed save image permission - using proper temp directory path |
| **1.0.5** | Added save & fullscreen to all endpoints; fixed back gesture (goes to home, not exit) |
| **1.0.4** | Fixed modal overflow in tools menu |
| **1.0.3** | Added local image picker + Cloudinary upload to all 4 new endpoints |
| **1.0.2** | Added `/api/edit`, `/api/upscale`, `/api/product-makeover`, `/api/fixoldimage` endpoints |
| **1.0.1** | Added gallery delete functionality |
| **1.0.0** | Initial release with auth, generate, tryon, gallery |

---

## 📱 Screens

1. **Login/Register** - Authentication screens
2. **Home** - Hero section + quick actions
3. **Generate** - Text-to-image generation
4. **Virtual Try-On** - Person + clothing image combination
5. **Edit** - Image editing with custom prompts
6. **Upscale** - Resolution enhancement
7. **Product Makeover** - Background replacement
8. **Fix Old Image** - Photo restoration
9. **Gallery** - Grid view with save/wallpaper/delete actions

---

## 🔧 Tech Stack

- **Flutter** 3.11+ with Dart
- **Riverpod** for state management
- **GoRouter** for navigation
- **Dio** for HTTP requests
- **Cloudinary** for image storage
- **Gal** for gallery access
- **flutter_secure_storage** for token persistence
- **image_picker** for local image selection

---

## 📦 Installation

```bash
# Clone the repository
git clone <repo-url>

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

---

## 🔗 API Endpoints

All endpoints require `Authorization: Bearer <token>` header:

| Endpoint | Description |
|----------|-------------|
| `POST /api/generate` | Generate image from prompt |
| `POST /api/tryon` | Virtual clothing try-on |
| `POST /api/edit` | Edit image with prompts |
| `POST /api/upscale` | Upscale image |
| `POST /api/product-makeover` | Product background change |
| `POST /api/fixoldimage` | Fix old/damaged photos |
| `GET /api/gallery` | List user's images |
| `DELETE /api/gallery` | Delete image by public_id |

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- **Backend**: FastAPI with Vertex AI (Google Cloud)
- **Storage**: Cloudinary
- **Icons**: Custom Flutter app icon assets

---

**Built with ❤️ using Flutter**