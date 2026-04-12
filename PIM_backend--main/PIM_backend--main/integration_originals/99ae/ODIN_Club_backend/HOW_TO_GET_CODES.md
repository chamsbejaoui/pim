# How to Get Your 6-Digit Verification Codes

Since email sending is not working, the **6-digit codes are automatically logged to your backend console** in development mode.

## Where to Find the Codes

When you register a new user or request a password reset, check your **backend terminal/console** where you're running `npm run start:dev`.

You'll see output like this:

```
================================================================================
📧 EMAIL VERIFICATION CODE
================================================================================
Email: user@example.com
Verification Code: 123456
Verification URL: http://localhost:3000/verify-email?token=123456
================================================================================
```

or for password reset:

```
================================================================================
🔑 PASSWORD RESET CODE
================================================================================
Email: user@example.com
Reset Code: 654321
Reset URL: http://localhost:3000/reset-password?token=654321
================================================================================
```

## Steps to Use the Code

1. **Register a new user** in your Flutter app
2. **Check your backend console** - you'll see the 6-digit code printed
3. **Copy the 6-digit code** (e.g., `123456`)
4. **Enter it in the Flutter app** on the email verification screen
5. The code input will auto-advance as you type

## Example

```
Backend Console Output:
================================================================================
📧 EMAIL VERIFICATION CODE
================================================================================
Email: john@example.com
Verification Code: 789012
Verification URL: http://localhost:3000/verify-email?token=789012
================================================================================
```

Then in your Flutter app, enter: `789012`

## Notes

- Codes are **always logged** in development mode, even if email sending fails
- The codes are **6-digit numbers** (e.g., 123456, 789012)
- Codes are valid for:
  - Email verification: 24 hours
  - Password reset: 1 hour

## To Fix Email Sending (Optional)

If you want to receive actual emails, you need to:

1. **Fix Gmail credentials** - Generate a new App Password at https://myaccount.google.com/apppasswords
2. **Or use Mailtrap** - Sign up at https://mailtrap.io for testing emails
3. **Or use Ethereal Email** - Visit https://ethereal.email/create for temporary email accounts

But for development and testing, **console logging is perfect** - just check your backend terminal!
