import { Role } from '../enums/role.enum';
import { UserStatus } from '../enums/user-status.enum';

export interface AuthUser {
  sub: string;
  email: string;
  role: Role;
  clubId: string | null;
  status: UserStatus;
}
