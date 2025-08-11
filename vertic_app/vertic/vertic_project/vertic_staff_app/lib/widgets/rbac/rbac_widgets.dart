// **RBAC Widget Exports**
// 
// Zentrale Exportdatei für alle RBAC-Widgets und Services.
// Vereinfacht die Imports in anderen Dateien.

// Widgets
export 'role_management_widget.dart';
export 'role_creation_dialog.dart';
export 'staff_user_management_widget.dart';
export 'staff_user_email_creation_dialog.dart';
export 'staff_user_edit_dialog.dart';
export 'role_assignment_dialog.dart';

// Services (Re-Export für Convenience)
export '../../services/rbac/role_state_provider.dart';
export '../../services/rbac/role_management_service.dart';
export '../../services/rbac/staff_user_state_provider.dart';
export '../../services/rbac/staff_user_management_service.dart';