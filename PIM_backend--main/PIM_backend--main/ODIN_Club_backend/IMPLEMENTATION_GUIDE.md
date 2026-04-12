# Implementation Guide

This file summarizes what was added in `odin_backend` and how to use it.

## Added modules
- `auth`: registration/login/email verification/forgot password/sensitive OTP.
- `users`: pending users approval by club responsable + list users.
- `clubs`: pending clubs list + admin approval/rejection.
- `rbac`: roles/permissions model and guards.
- `audit`: immutable audit log write/list.
- `finance`: accounting, payroll, transfers, treasury, budget, reports.
- `otp`: 6-digit code generation, persistence, verification and email send.

## Important security behavior
- Protected routes require JWT and `UserStatus.ACTIVE`.
- Non-admin users are restricted to their `clubId`.
- Sensitive routes require re-auth via:
  - `x-sensitive-password`, or
  - `x-sensitive-otp` (requested from `/api/auth/sensitive-action/request-otp`).
- Daily and amount limits are enforced using env configs.
- Sensitive actions always write to `audit_logs` with before/after snapshots.

## Main API paths
- Auth:
  - `POST /api/auth/register/responsable`
  - `POST /api/auth/register/member`
  - `POST /api/auth/verify-email`
  - `POST /api/auth/login`
  - `POST /api/auth/forgot-password/request`
  - `POST /api/auth/forgot-password/reset`
  - `POST /api/auth/sensitive-action/request-otp`
- Clubs:
  - `GET /api/clubs/active`
  - `GET /api/clubs/pending` (ADMIN)
  - `PATCH /api/clubs/:clubId/approval` (ADMIN)
- Users:
  - `GET /api/users/pending` (CLUB_RESPONSABLE)
  - `PATCH /api/users/:userId/approval` (CLUB_RESPONSABLE)
  - `GET /api/users`
- Finance:
  - Accounting: `POST/GET /api/finance/accounting/entries`
  - Payroll: `POST /api/finance/payroll/preview`, `POST /api/finance/payroll/execute`, `POST /api/finance/payroll/mark-paid`
  - Transfers: `POST /api/finance/transfers`, `GET /api/finance/transfers/:transferId/amortization`, `GET /api/finance/transfers/upcoming-tranches`, `POST /api/finance/transfers/pay-tranche`
  - Treasury: `GET /api/finance/treasury/accounts`, `POST /api/finance/treasury/reconcile`
  - Budget: `GET/POST /api/finance/budget/thresholds`
  - Reports: `POST /api/finance/reports/generate`, `GET /api/finance/reports/:reportId/download`
- Audit:
  - `GET /api/audit`

## Seed
`npm run seed:admin` creates global admin from env if missing.
