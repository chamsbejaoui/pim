import { ROLE_PERMISSIONS } from '../../common/constants/role-permissions.constant';
import { Permission } from '../../common/enums/permission.enum';
import { Role } from '../../common/enums/role.enum';

export function canDeleteMessageForEveryone(params: {
  actorUserId: string;
  actorRole: Role;
  senderUserId: string;
}): boolean {
  if (params.actorUserId === params.senderUserId) {
    return true;
  }

  const permissions = ROLE_PERMISSIONS[params.actorRole] || [];
  return permissions.includes(Permission.CHAT_DELETE_EVERYONE);
}
