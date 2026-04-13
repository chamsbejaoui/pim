import '../../ui/shell/app_shell.dart';
import '../../user_management/models/user_management_models.dart';

bool erpIsAdminRole(String? role) {
  if (role == null) return false;
  final normalized = role.trim().toLowerCase();
  return normalized == 'admin' ||
      normalized == 'responsable' ||
      normalized == 'club_responsable' ||
      normalized == 'club_manager' ||
      normalized == 'club manager' ||
      normalized == 'superadmin' ||
      role == 'ADMIN' ||
      role == 'CLUB_RESPONSABLE';
}

SessionModel? erpSessionOf(AppShellScope? scope) => scope?.session;
