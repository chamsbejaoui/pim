import { Permission } from '../enums/permission.enum';
import { Role } from '../enums/role.enum';

const allPermissions = Object.values(Permission);

export const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  [Role.ADMIN]: allPermissions,
  [Role.CLUB_RESPONSABLE]: [
    Permission.USERS_PENDING_READ,
    Permission.USERS_APPROVE,
    Permission.USERS_READ,
    Permission.CHAT_READ,
    Permission.CHAT_WRITE,
    Permission.CHAT_DELETE_EVERYONE,
    Permission.NOTIF_READ,
    Permission.NOTIF_WRITE,
    Permission.ANNOUNCEMENT_SEND,
    Permission.TRAINING_REMINDER_SEND,
    Permission.EMERGENCY_SEND,
    Permission.DOC_SHARE
  ],
  [Role.FINANCIER]: [
    Permission.USERS_READ,
    Permission.CHAT_READ,
    Permission.CHAT_WRITE,
    Permission.NOTIF_READ,
    Permission.DOC_SHARE,
    Permission.FINANCE_ACCOUNTING_CREATE,
    Permission.FINANCE_ACCOUNTING_READ,
    Permission.FINANCE_PAYROLL_PREVIEW,
    Permission.FINANCE_PAYROLL_EXECUTE,
    Permission.FINANCE_TRANSFERS_CREATE,
    Permission.FINANCE_TRANSFERS_PAY,
    Permission.FINANCE_TREASURY_READ,
    Permission.FINANCE_TREASURY_RECONCILE,
    Permission.FINANCE_BUDGET_READ,
    Permission.FINANCE_BUDGET_EDIT,
    Permission.FINANCE_REPORTS_GENERATE,
    Permission.FINANCE_AUDIT_READ
  ],
  [Role.JOUEUR]: [
    Permission.USERS_READ,
    Permission.CHAT_READ,
    Permission.CHAT_WRITE,
    Permission.NOTIF_READ,
    Permission.DOC_SHARE
  ],
  [Role.STAFF_TECHNIQUE]: [
    Permission.USERS_READ,
    Permission.CHAT_READ,
    Permission.CHAT_WRITE,
    Permission.NOTIF_READ,
    Permission.NOTIF_WRITE,
    Permission.ANNOUNCEMENT_SEND,
    Permission.TRAINING_REMINDER_SEND,
    Permission.EMERGENCY_SEND,
    Permission.DOC_SHARE
  ],
  [Role.STAFF_MEDICAL]: [
    Permission.USERS_READ,
    Permission.CHAT_READ,
    Permission.CHAT_WRITE,
    Permission.NOTIF_READ,
    Permission.NOTIF_WRITE,
    Permission.MEDICAL_ALERT_SEND,
    Permission.MEDICAL_ALERT_CONFIDENTIAL_READ,
    Permission.EMERGENCY_SEND,
    Permission.DOC_SHARE
  ],
  [Role.SCOUT]: [
    Permission.USERS_READ,
    Permission.CHAT_READ,
    Permission.CHAT_WRITE,
    Permission.NOTIF_READ,
    Permission.DOC_SHARE
  ]
};
