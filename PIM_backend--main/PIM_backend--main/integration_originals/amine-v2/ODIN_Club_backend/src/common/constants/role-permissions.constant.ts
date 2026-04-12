import { Permission } from '../enums/permission.enum';
import { Role } from '../enums/role.enum';

const allPermissions = Object.values(Permission);

export const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  [Role.ADMIN]: allPermissions,
  [Role.CLUB_RESPONSABLE]: [
    Permission.USERS_PENDING_READ,
    Permission.USERS_APPROVE,
    Permission.USERS_READ
  ],
  [Role.FINANCIER]: [
    Permission.USERS_READ,
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
  [Role.JOUEUR]: [Permission.USERS_READ],
  [Role.STAFF_TECHNIQUE]: [Permission.USERS_READ],
  [Role.STAFF_MEDICAL]: [Permission.USERS_READ]
};
