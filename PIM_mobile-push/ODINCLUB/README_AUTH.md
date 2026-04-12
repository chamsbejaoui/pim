# ODIN Club - Authentication Setup

This Flutter app includes complete authentication functionality with the ODIN Club backend.

## Features

- ✅ User Registration
- ✅ User Login
- ✅ Email Verification
- ✅ Forgot Password
- ✅ Reset Password
- ✅ Beautiful UI with Green and White Gradient Theme

## Setup Instructions

### 1. Install Dependencies

```bash
cd ODINCLUB
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/config/app_config.dart` and update the `baseUrl` based on your platform:

- **Android Emulator**: `http://10.0.2.2:3000`
- **iOS Simulator**: `http://localhost:3000`
- **Physical Device**: `http://YOUR_COMPUTER_IP:3000` (e.g., `http://192.168.1.100:3000`)

### 3. Start the Backend

Make sure your NestJS backend is running:

```bash
cd ../ODIN_Club_backend
npm install
npm run start:dev
```

The backend should be running on `http://localhost:3000` (or your configured port).

### 4. Run the Flutter App

```bash
cd ODINCLUB
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── app_config.dart          # Backend URL configuration
├── screens/
│   ├── login_screen.dart         # Login interface
│   ├── register_screen.dart      # Registration interface
│   ├── forgot_password_screen.dart  # Forgot password
│   ├── reset_password_screen.dart   # Reset password
│   ├── email_verification_screen.dart # Email verification
│   └── home_screen.dart          # Home screen after login
├── services/
│   └── api_service.dart          # API communication service
├── theme/
│   └── app_theme.dart            # App theme with green/white gradient
└── main.dart                     # App entry point
```

## User Roles

The app supports the following user roles:
- Administrateur
- Responsable du club
- Entraîneur
- Scout
- Comptable
- Joueur (default)

## API Endpoints Used

- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `GET /auth/verify-email?token=...` - Email verification
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token

## Theme

The app uses a beautiful green and white gradient theme:
- Primary Green: `#4CAF50`
- Light Green: `#81C784`
- Dark Green: `#388E3C`
- White: `#FFFFFF`

All screens feature gradient backgrounds and modern Material Design 3 components.

## Notes

- Tokens are stored securely using `shared_preferences`
- Email verification is required before login
- Password reset tokens are sent via email
- The app automatically navigates to login after successful registration
