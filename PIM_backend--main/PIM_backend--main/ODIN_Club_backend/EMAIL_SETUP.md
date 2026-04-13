# Email Configuration Guide

The backend uses Nodemailer to send verification and password reset emails. This guide will help you configure email sending.

## Current Issue

You're getting a Gmail authentication error. This happens when:
1. Gmail credentials are incorrect
2. App Password is not properly configured
3. 2FA is not enabled on the Gmail account

## Solution Options

### Option 1: Fix Gmail App Password (Recommended for Production)

1. **Enable 2-Factor Authentication** on your Gmail account:
   - Go to https://myaccount.google.com/security
   - Enable 2-Step Verification

2. **Generate an App Password**:
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Enter "ODIN Club Backend" as the name
   - Copy the 16-character password (it will look like: `abcd efgh ijkl mnop`)

3. **Update your `.env` file**:
   ```env
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=abcdefghijklmnop  # Remove spaces from app password
   ```

### Option 2: Use Development Mode (Recommended for Testing)

The email service now has a **development mode** that logs tokens to the console instead of sending emails. This is perfect for testing!

**To enable development mode:**

1. Make sure `NODE_ENV=development` in your `.env` file
2. Remove or comment out SMTP credentials:
   ```env
   # SMTP_USER=mdarraji17@gmail.com
   # SMTP_PASS=yfqfd ebxt tqco zzzj
   ```

3. When you register or request password reset, check your console - you'll see:
   ```
   ================================================================================
   📧 EMAIL VERIFICATION (Development Mode - Email not sent)
   ================================================================================
   To: user@example.com
   Verification Token: abc123-def456-ghi789
   Verification URL: http://localhost:3000/verify-email?token=abc123-def456-ghi789
   ================================================================================
   ```

### Option 3: Use Mailtrap (Recommended for Development)

Mailtrap is a fake SMTP server for testing emails.

1. Sign up at https://mailtrap.io (free tier available)
2. Create an inbox
3. Copy the SMTP credentials
4. Update your `.env`:
   ```env
   SMTP_HOST=smtp.mailtrap.io
   SMTP_PORT=2525
   SMTP_USER=your-mailtrap-username
   SMTP_PASS=your-mailtrap-password
   ```

### Option 4: Use Ethereal Email (Quick Testing)

Ethereal Email provides temporary email accounts for testing.

1. Visit https://ethereal.email/create
2. Copy the generated credentials
3. Update your `.env` with the provided SMTP settings

## Current Configuration

Your current `.env` has:
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=mdarraji17@gmail.com
SMTP_PASS=yfqfd ebxt tqco zzzj
```

**To fix Gmail authentication:**
1. Make sure the password is a Gmail App Password (not your regular password)
2. Remove spaces from the app password in `.env`
3. Ensure 2FA is enabled on the Gmail account

## Testing

After configuration, test by:
1. Registering a new user
2. Check console logs (development mode) or your email inbox
3. Use the token/URL to verify the email

## Notes

- In development mode, tokens are logged to console - perfect for testing!
- The email service will automatically fall back to console logging if email sending fails in development
- For production, make sure to properly configure SMTP credentials
