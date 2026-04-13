# ODIN Club Backend

Backend API for ODIN Club management system built with NestJS.

## Features

- ✅ User registration with email verification
- ✅ Login with email/password
- ✅ Google OAuth login
- ✅ Forgot password functionality
- ✅ Role-based access control (6 user types)
- ✅ JWT authentication
- ✅ Email notifications

## User Roles

1. **Administrateur** - Administrator
2. **Responsable du club** - Club Manager
3. **Entraîneur** - Coach
4. **Scout** - Scout
5. **Comptable** - Accountant
6. **Joueur** - Player

## Prerequisites

- Node.js (v18 or higher)
- MongoDB database (running locally or remote)
- SMTP email account (Gmail recommended)
- Google OAuth credentials (for Google login)

## Installation

1. Install dependencies:
```bash
npm install
```

2. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

3. **📖 See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed step-by-step instructions** on how to configure:
   - Database connection (MongoDB)
   - JWT secret key
   - SMTP email settings (Gmail, Outlook, etc.)
   - Google OAuth credentials
   - Frontend URL

4. Ensure MongoDB is running (default: `mongodb://localhost:27017`)

5. Run the application:
```bash
npm run start:dev
```

## API Endpoints

### Authentication

- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login with email/password
- `GET /auth/google` - Initiate Google OAuth login
- `GET /auth/google/callback` - Google OAuth callback
- `GET /auth/verify-email?token=<token>` - Verify email address
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token

### User

- `GET /users/profile` - Get current user profile (requires authentication)

## Environment Variables

See `.env.example` for all required environment variables.

## Email Setup

### Gmail Setup

1. Enable 2-Step Verification on your Google account
2. Generate an App Password:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
3. Use the generated password in `SMTP_PASS`

### Other SMTP Providers

Update `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, and `SMTP_PASS` accordingly.

## Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `http://localhost:3000/auth/google/callback`
6. Copy Client ID and Client Secret to `.env`

## Database Schema

The application uses Mongoose with MongoDB. Collections are automatically created on first run. The database name is `odin_club` (configurable via `MONGODB_URI`).

## Development

```bash
# Development mode with hot reload
npm run start:dev

# Build for production
npm run build

# Production mode
npm run start:prod
```

## Security Notes

- Change `JWT_SECRET` in production
- Use strong database passwords
- Enable HTTPS in production
- Set `NODE_ENV=production` in production
- Set `synchronize: false` in production (use migrations instead)
