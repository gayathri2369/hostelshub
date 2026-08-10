# 🏠 HostelHub

A Flutter-based marketplace app for hostel students to buy, sell, and donate items within their campus community. Features AI-powered product condition detection using Google Gemini Vision.

## 📱 Platform Support

- ✅ **Android** (Production Ready)
- ✅ **Web** (Tested & Working)
- 🔜 **iOS** (Not yet implemented)

## 🌟 Features

### For Buyers
- 🔍 Browse available products
- ❤️ Add items to wishlist
- 💬 Chat with sellers in real-time
- 🎯 Filter by category and condition
- 🔎 Search products
- 👤 Manage profile

### For Sellers
- 📦 List products with AI verification
- 🤖 **AI Product Condition Detection** (NEW/OLD/BROKEN)
- 📊 View sales dashboard
- 💰 Track active & sold items
- 📝 Edit/delete listings
- 💬 Chat with buyers
- 📈 See unread messages

### AI-Powered Features
- 🤖 **Google Gemini Vision AI** for automatic product condition assessment
- 📸 Upload product photos for instant verification
- ✅ Condition detection: NEW, OLD, or BROKEN
- 🎯 Confidence scoring
- 🔄 Retry mechanism for reliability

### Common Features
- 🎁 Donate items (books, clothes, home items) with AI verification
- 🔄 Switch between buyer/seller roles
- 🔐 Secure authentication
- 💾 Cloud database (Supabase)
- 🚀 Real-time updates
- 🎨 Beautiful Material Design UI

## 🗄️ Database

**Backend**: Supabase (PostgreSQL)

### Tables
1. **profiles** - User profiles and authentication
2. **products** - Product listings with AI-verified conditions
3. **wishlists** - User wishlists
4. **conversations** - Chat conversations
5. **messages** - Chat messages

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.44.0 or higher
- Dart 3.12.0 or higher
- Android Studio / VS Code
- Google Gemini API key ([Get one here](https://aistudio.google.com/app/apikey))

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/gayathri2369/hostelshub.git
cd hostelshub
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run on Android device**
```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

4. **Build release APK**
```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_api_key_here
```

## 🤖 AI Integration

This app uses **Google Gemini 2.5 Flash** for intelligent product condition detection.

### How it works:
1. User uploads a product photo
2. Image is sent to Gemini Vision API
3. AI analyzes the image and returns:
   - Condition: NEW, OLD, or BROKEN
   - Confidence score (0.0 - 1.0)
   - Reasoning explanation
4. Result is displayed to the user
5. Retry option if verification fails

### API Configuration
The app requires a Gemini API key passed via `--dart-define`:
```bash
--dart-define=GEMINI_API_KEY=your_key_here
```

Get your free API key: https://aistudio.google.com/app/apikey

## 🏗️ Project Structure

```
hostelhub/
├── lib/
│   ├── models/               # Data models
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   └── message_model.dart
│   ├── providers/            # State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── product_provider.dart
│   │   └── chat_provider.dart
│   ├── services/             # External services
│   │   ├── gemini_vision_service.dart  # AI detection
│   │   └── mistral_ai_service.dart     # AI orchestration
│   ├── screens/              # UI screens
│   │   ├── auth/            # Login, Register, Splash
│   │   ├── buyer/           # Buyer dashboard, Product detail
│   │   ├── seller/          # Seller dashboard, Sell flow
│   │   └── common/          # Profile, Chat, Donate
│   ├── widgets/              # Reusable widgets
│   ├── utils/                # Utilities & config
│   └── main.dart             # App entry point
├── android/                  # Android platform
├── web/                      # Web platform
└── assets/                   # Images and assets
```

## 🎨 Tech Stack

- **Framework**: Flutter 3.44.0
- **Language**: Dart 3.12.0
- **State Management**: Provider
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **AI**: Google Gemini 2.5 Flash Vision
- **HTTP Client**: http package
- **Image Handling**: image_picker, cached_network_image
- **UI**: Material Design 3
- **Local Storage**: SharedPreferences
- **Unique IDs**: uuid

## 📱 App Information

- **Package Name**: `com.hostelhub.marketplace`
- **Version**: 1.0.0+1
- **Minimum SDK**: Android 5.0 (API 21)
- **Target SDK**: Latest

## ✅ Build Status

- ✅ **Android Release**: SUCCESS (53.8 MB)
- ✅ **Flutter Analyze**: 0 errors (10 style warnings)
- ✅ **AI Integration**: Working with Gemini 2.5 Flash
- ✅ **Network Security**: Configured for HTTPS

## 🔧 Configuration

### Required Environment Variables
- `GEMINI_API_KEY` - Google Gemini API key for AI detection

### Network Security
The app includes network security configuration for:
- `generativelanguage.googleapis.com` (Gemini API)
- Supabase domains

Location: `android/app/src/main/res/xml/network_security_config.xml`

## 🚢 Deployment

### Android Release APK
```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=GEMINI_API_KEY=your_key
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Distribution
- Direct APK sharing
- Google Play Store (requires proper signing key)

## 🔐 Security

- ✅ Passwords hashed by Supabase
- ✅ HTTPS encryption for all API calls
- ✅ Row Level Security (RLS) on database
- ✅ JWT-based authentication
- ✅ Secure API key handling
- ✅ Network security config for Android

## 🧪 Testing

Before distribution, test:
1. ✅ User registration & login
2. ✅ Product upload with AI verification
3. ✅ Donation with AI verification
4. ✅ Wishlist functionality
5. ✅ Real-time chat
6. ✅ Profile management
7. ✅ Search and filters

## 📊 AI Detection Details

### Gemini Vision Service
- **Model**: gemini-2.5-flash
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- **Authentication**: x-goog-api-key header
- **Input**: Base64-encoded JPEG/PNG images
- **Output**: JSON with condition, confidence, and reasoning
- **Retry Logic**: Single retry on 429/503 errors
- **Error Handling**: Clear user feedback with retry button

### Condition Classification
- **NEW**: Unused or like-new condition, no visible wear
- **OLD**: Visible wear but fully functional and usable
- **BROKEN**: Visible damage, cracks, missing parts, or malfunction

## 🎯 Roadmap

### Completed ✅
- [x] User authentication
- [x] Product marketplace
- [x] **AI-powered product verification**
- [x] Wishlist feature
- [x] Real-time chat system
- [x] Donation system
- [x] Web support
- [x] Production release build

### Future Enhancements 🔜
- [ ] Custom app icon
- [ ] Push notifications
- [ ] Payment integration
- [ ] Product reviews & ratings
- [ ] iOS support
- [ ] Dark mode
- [ ] Admin panel

## 📝 License

This project is created for educational purposes.

## 👥 Contributors

- **Developer**: Gayathri
- **Repository**: https://github.com/gayathri2369/hostelshub

## 🆘 Support

For issues and questions:
- Open an issue on GitHub
- Check Flutter docs: https://flutter.dev/docs
- Check Supabase docs: https://supabase.com/docs
- Check Gemini API docs: https://ai.google.dev/docs

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend services
- Google AI for Gemini Vision API
- Open source community

---

**Made with ❤️ using Flutter, Supabase & Google Gemini AI**
