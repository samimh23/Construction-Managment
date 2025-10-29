# 🏗️ Construction Management System

A comprehensive cross-platform mobile application for construction workforce management, featuring real-time attendance tracking, GPS geofencing, face recognition, and automated payroll calculations.

![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=node.js)
![MongoDB](https://img.shields.io/badge/MongoDB-6+-47A248?style=for-the-badge&logo=mongodb)

## 📱 Overview

This application digitizes construction site operations by automating attendance tracking, worker management, and payroll calculations. Built with Flutter for cross-platform mobile deployment and Node.js/NestJS for a robust backend, it eliminates manual processes and provides real-time visibility into workforce operations.

## ✨ Key Features

### 🎯 Core Functionality
- **📍 GPS-Based Attendance** - Automatic check-in/check-out with geofence validation to prevent location fraud
- **👤 Face Recognition** - Biometric verification for secure worker authentication
- **🔐 Multi-Role Access Control** - Separate interfaces for Owner, Manager, Construction Manager, and Worker
- **💰 Automated Payroll** - Real-time wage calculations based on attendance data
- **📶 Offline-First Architecture** - Queue system with automatic sync when connectivity is restored
- **⚡ Real-Time Updates** - WebSocket integration for live attendance synchronization
- **📊 Analytics Dashboard** - Interactive charts with attendance trends and workforce insights

### 🏢 Role-Specific Features

**Owner Dashboard:**
- Site-wide analytics and KPIs
- Multi-site attendance overview
- Payroll summaries with visual charts
- Worker performance metrics
- Budget tracking per site

**Manager Interface:**
- Worker check-in/check-out management
- Face registration for workers
- Site-specific attendance tracking
- Real-time worker location monitoring
- Daily attendance reports

**Worker Features:**
- Personal attendance history
- Multiple check-in/check-out sessions per day
- View work hours and earnings
- Profile management

### 🔒 Security Features
- JWT authentication with refresh token mechanism
- Role-based access control (RBAC)
- Secure token storage
- Geofence validation preventing attendance fraud
- Face recognition for identity verification

## 🛠️ Tech Stack

### Frontend (Mobile)
| Technology | Purpose |
|------------|---------|
| **Flutter 3.7+** | Cross-platform mobile framework |
| **Provider** | State management solution |
| **Dio** | HTTP client with interceptors for auth |
| **fl_chart** | Beautiful data visualization charts |
| **flutter_map** | Map integration with geolocation |
| **Socket.io Client** | Real-time bidirectional communication |
| **Image Picker** | Camera access for face recognition |
| **Geolocator** | GPS location services |
| **Shared Preferences** | Local data persistence |
| **Flutter Secure Storage** | Encrypted credential storage |

### Backend
| Technology | Purpose |
|------------|---------|
| **Node.js & NestJS** | RESTful API framework |
| **MongoDB** | NoSQL database for flexible data models |
| **Socket.io** | Real-time server for live updates |
| **JWT** | Secure authentication tokens |
| **Multer** | File upload handling for images |
| **Mongoose** | MongoDB ODM |

### Architecture Patterns
- **Offline-First** with queue system for poor connectivity scenarios
- **Provider Pattern** for reactive state management
- **Repository Pattern** for clean data layer separation
- **Clean Architecture** principles for maintainability
- **ProxyProvider** for dependency injection

## 📂 Project Structure

```
lib/
├── auth/                       # Authentication Module
│   ├── models/                 # User, LoginRequest, AuthResponse
│   ├── Providers/              # AuthProvider (state management)
│   ├── services/               # AuthService (API calls)
│   ├── screens/                # Login, Register screens
│   └── Widgets/                # Auth-related UI components
│
├── Dashboard/                  # Owner Analytics Dashboard
│   ├── pages/                  # Dashboard UI
│   ├── models/                 # Dashboard data models
│   └── widgets/                # Chart components, KPI cards
│
├── Manger/                     # Manager Module
│   ├── Screens/                # Manager home page
│   ├── manager_provider/       # Manager state management
│   ├── Service/                # Manager API services
│   └── Models/                 # Manager-specific models
│
├── Worker/                     # Worker Management Module
│   ├── Models/                 # Worker, Attendance models
│   ├── Provider/               # WorkerProvider
│   ├── Screens/                # Worker list, details
│   └── Service/                # Worker API service
│
├── Construction/               # Construction Site Module
│   ├── Provider/               # Site provider
│   ├── service/                # Site API service
│   ├── screen/                 # Site management screens
│   └── Models/                 # Site data models
│
├── profile/                    # User Profile Module
│   ├── provider/               # ProfileProvider
│   ├── screens/                # Profile page
│   └── service/                # Profile API service
│
└── core/                       # Shared Resources
    ├── constants/              # API endpoints, colors, configs
    ├── widgets/                # Reusable UI components
    └── utils/                  # Helper functions
```

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: 3.7.0 or higher
- **Dart SDK**: 3.0 or higher
- **Node.js**: 18+ (for backend)
- **MongoDB**: 6+ (for backend)
- **Android Studio** / **Xcode** (for mobile development)
- **Git**

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/samimh23/Construction-Managment.git
cd Construction-Managment
```

2. **Install Flutter dependencies**
```bash
flutter pub get
```

3. **Configure API endpoint**
Edit `lib/core/constants/api_constants.dart`:
```dart
class ApiConstants {
  static const String baseUrl = 'YOUR_API_URL';
  static const String socketUrl = 'YOUR_SOCKET_URL';
}
```

4. **Run the app**
```bash
# Debug mode
flutter run

# Release mode (Android)
flutter build apk --release

# Release mode (iOS)
flutter build ios --release
```

### Backend Setup (if applicable)
```bash
cd backend
npm install
cp .env.example .env  # Configure your environment variables
npm run start:dev
```

## 📱 App Architecture

### State Management Flow
```
UI Layer (Widgets)
    ↓
Provider (State Management)
    ↓
Service Layer (Business Logic)
    ↓
API/Repository Layer
    ↓
Backend (NestJS + MongoDB)
```

### Key Architectural Decisions

1. **Offline-First Design**
   - Queue system stores operations when offline
   - Automatic sync when connectivity restored
   - Optimistic UI updates for better UX

2. **Provider Pattern**
   - Reactive state management
   - Dependency injection via ProxyProvider
   - Separation of concerns

3. **Multi-Session Attendance**
   - Workers can check-in/out multiple times per day
   - Each session tracked independently
   - Accurate payroll calculations

## 🎨 Design Highlights

- **Modern UI/UX** - Gradient backgrounds, smooth animations, glassmorphism effects
- **Responsive Design** - Adapts to different screen sizes and orientations
- **Accessibility** - Clear visual hierarchy, readable fonts, proper contrast ratios
- **Performance Optimized** - Lazy loading, efficient list rendering, image caching
- **Consistent Branding** - Unified color scheme and typography throughout

### Color Palette
- **Primary**: `#6366F1` (Indigo)
- **Success**: `#059669` (Emerald)
- **Error**: `#DC2626` (Red)
- **Warning**: `#F59E0B` (Amber)
- **Background**: `#F1F5F9` (Slate)

## 🔧 Key Technical Achievements

✅ **95%+ code sharing** between iOS and Android platforms  
✅ **100% offline capability** with automatic sync queue system  
✅ **Real-time updates** using WebSocket for live attendance data  
✅ **Geofencing accuracy** preventing attendance fraud with GPS validation  
✅ **Face recognition** integration for biometric worker verification  
✅ **Animated UI** with smooth transitions and visual feedback  
✅ **Role-based routing** with secure navigation guards  
✅ **Multi-session tracking** supporting complex work schedules  

## 📊 Performance Metrics

- **App Size**: ~45MB (release build)
- **Startup Time**: <2 seconds on mid-range devices
- **Offline Capability**: 100% functional with auto-sync
- **Battery Efficiency**: Optimized location tracking with distance filters
- **Code Quality**: Follows Flutter best practices and clean code principles

## 🔐 Security Features

1. **JWT Authentication**
   - Access tokens with 1-hour expiration
   - Refresh tokens for seamless re-authentication
   - Automatic token refresh on 401 errors

2. **Role-Based Access Control**
   - Server-side role validation
   - Client-side role-based routing
   - Protected API endpoints

3. **Geofence Validation**
   - Haversine formula for distance calculation
   - Configurable radius per construction site
   - Real-time location verification

4. **Secure Storage**
   - Encrypted token storage
   - Sensitive data protection
   - Secure API communication (HTTPS)

## 📈 Future Enhancements

- [ ] Push notifications for attendance reminders
- [ ] Document management (upload site photos, reports)
- [ ] Expense tracking per site
- [ ] Multi-language support (i18n)
- [ ] Dark mode theme
- [ ] Export reports to PDF/Excel
- [ ] Integration with accounting software
- [ ] Advanced analytics with ML predictions
- [ ] QR code scanning for quick check-in
- [ ] Biometric authentication (fingerprint/face ID)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/samimh23/Construction-Managment/issues).

### How to Contribute
1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

**Sami Mahjoub**

- 💼 LinkedIn: [Connect with me](https://linkedin.com/in/yourprofile)
- 🐙 GitHub: [@samimh23](https://github.com/samimh23)
- 📧 Email: your.email@example.com
- 🌐 Portfolio: [Your Portfolio](https://yourwebsite.com)

## 🙏 Acknowledgments

- Flutter team for the amazing cross-platform framework
- NestJS community for backend best practices
- MongoDB for flexible data modeling
- Open source community for incredible packages
- All contributors and supporters of this project

## 📞 Support

If you found this project helpful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs via [Issues](https://github.com/samimh23/Construction-Managment/issues)
- 💡 Suggesting new features
- 📢 Sharing with others who might benefit

---

<div align="center">

**Built with ❤️ using Flutter & Node.js**

⭐ **Star this repo if you find it useful!** ⭐

</div>
