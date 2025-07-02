# Construction Management App

A comprehensive Flutter application for construction project management with robust authentication system.

## Features

### 🔐 Authentication System
- **Login Page** - Clean, modern design with email/password authentication
- **Registration Page** - Complete user onboarding with form validation
- **Password Security** - Real-time password strength indicator
- **Form Validation** - Comprehensive client-side validation
- **Remember Me** - Persistent login sessions
- **Forgot Password** - Password reset functionality
- **Demo Credentials** - Use `demo@construction.com` / `Demo123!` for testing

### 🏗️ Construction Theme
- Professional blue and orange color scheme
- Construction industry iconography
- Mobile-first responsive design
- Accessibility compliance (ARIA labels, keyboard navigation)
- Smooth animations and transitions

### 🛡️ Security Features
- Input sanitization and validation
- Secure password requirements (8+ chars, mixed case, numbers, special chars)
- JWT token management
- Secure local storage
- Session management

## Project Structure

```
lib/
├── main.dart                 # App entry point with authentication wrapper
├── models/                   # Data models
│   ├── user_model.dart       # User data structure
│   └── auth_response_model.dart # API response models
├── services/                 # Business logic layer
│   ├── auth_service.dart     # Authentication operations
│   ├── api_service.dart      # HTTP client wrapper
│   └── storage_service.dart  # Local data persistence
├── providers/                # State management
│   └── auth_provider.dart    # Authentication state management
├── screens/                  # UI screens
│   ├── LoginPage.dart        # Login interface
│   ├── register_page.dart    # Registration interface
│   └── home_page.dart        # Main dashboard
├── widgets/                  # Reusable UI components
│   ├── custom_text_field.dart        # Enhanced input fields
│   ├── custom_button.dart             # Styled buttons
│   ├── password_strength_indicator.dart # Password validation UI
│   └── loading_overlay.dart           # Loading states
├── utils/                    # Utilities and helpers
│   ├── app_colors.dart       # Color scheme
│   ├── constants.dart        # App constants
│   └── validators.dart       # Form validation logic
└── routes/                   # Navigation management
    └── app_routes.dart       # Route definitions
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.7.2)
- Dart SDK
- Android Studio / VS Code
- Device/Emulator for testing

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/samimh23/Construction-Managment.git
cd Construction-Managment
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the application**
```bash
flutter run
```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2              # State management
  http: ^1.2.1                  # HTTP requests
  shared_preferences: ^2.2.3    # Local storage
  email_validator: ^2.1.17      # Email validation
  crypto: ^3.0.3                # Security utilities
  flutter_spinkit: ^5.2.1       # Loading animations

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Authentication Flow

### Login Process
1. User enters email and password
2. Client-side validation
3. API authentication (currently simulated)
4. Token storage and user session creation
5. Navigation to dashboard

### Registration Process
1. User fills comprehensive registration form
2. Real-time validation and password strength checking
3. Email availability verification
4. Account creation with API
5. Automatic login and dashboard navigation

### Security Measures
- **Password Requirements**: Minimum 8 characters with mixed case, numbers, and special characters
- **Token Management**: Secure JWT token storage with refresh capability
- **Session Persistence**: Optional "Remember Me" functionality
- **Input Validation**: Comprehensive client and server-side validation
- **Error Handling**: User-friendly error messages and retry mechanisms

## API Integration

The authentication service is designed to work with RESTful APIs:

```dart
// Example API endpoints (customize for your backend)
static const String baseUrl = 'https://api.constructionmanagement.com';
static const String loginEndpoint = '/auth/login';
static const String registerEndpoint = '/auth/register';
static const String refreshTokenEndpoint = '/auth/refresh';
```

### Demo Mode
Currently configured with demo authentication for testing:
- **Email**: `demo@construction.com`
- **Password**: `Demo123!`

## Customization

### Theming
Modify `lib/utils/app_colors.dart` to customize the color scheme:

```dart
class AppColors {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color primaryOrange = Color(0xFFFF6B00);
  // ... other colors
}
```

### Validation Rules
Update validation logic in `lib/utils/validators.dart`:

```dart
static String? validatePassword(String? value) {
  // Customize password requirements
  if (value == null || value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  // ... additional rules
}
```

### API Configuration
Configure your backend endpoints in `lib/utils/constants.dart`:

```dart
class AppConstants {
  static const String baseUrl = 'YOUR_API_BASE_URL';
  // ... other constants
}
```

## Testing

Run the test suite:

```bash
flutter test
```

### Test Coverage
- Widget tests for UI components
- Unit tests for validation logic
- Integration tests for authentication flow
- Provider state management tests

## UI Screenshots

### Login Page
![Login Page](https://github.com/user-attachments/assets/feb783a8-0a2f-4e9c-ae51-59a2d564df59)

The login page features:
- Clean, professional design
- Construction-themed branding
- Email and password fields with validation
- Remember me functionality
- Forgot password link
- Responsive layout

### Key Features Demonstrated
- **Modern UI Design**: Clean, professional interface suitable for construction industry
- **Form Validation**: Real-time validation with helpful error messages
- **Responsive Design**: Works on mobile devices and tablets
- **Accessibility**: Proper labeling and keyboard navigation support
- **Loading States**: Smooth loading indicators during authentication
- **Password Security**: Strong password requirements with visual feedback

## Architecture Highlights

### State Management
Uses Provider pattern for clean separation of concerns:
- `AuthProvider` manages authentication state
- Reactive UI updates based on auth state changes
- Centralized error handling and loading states

### Service Layer
Well-structured service architecture:
- `AuthService` handles authentication logic
- `ApiService` provides HTTP client abstraction
- `StorageService` manages local data persistence

### Security First
Built with security best practices:
- Input sanitization and validation
- Secure token storage
- Password strength requirements
- Error handling without information leakage

## Future Enhancements

- [ ] Biometric authentication (fingerprint/face ID)
- [ ] Two-factor authentication (2FA)
- [ ] Social login integration (Google, Apple)
- [ ] Password recovery via SMS
- [ ] Account lockout after failed attempts
- [ ] Advanced session management
- [ ] Offline authentication capabilities

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Email: support@constructionmanagement.com
- Documentation: [Project Wiki](https://github.com/samimh23/Construction-Managment/wiki)

---

Built with ❤️ for the construction industry
