import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'permission_provider.dart';

/// **PermissionWrapper - Ein Widget zur Steuerung der Sichtbarkeit basierend auf Berechtigungen.**
///
/// Dieses Widget prüft mithilfe des `PermissionProvider`, ob der Benutzer
/// die erforderliche Berechtigung (`requiredPermission`) besitzt.
///
/// - Wenn die Berechtigung vorhanden ist, wird das `child`-Widget angezeigt.
/// - Wenn nicht, wird standardmäßig ein leerer `SizedBox` gerendert
///   (oder optional das `placeholder`-Widget, falls eines bereitgestellt wird).
class PermissionWrapper extends StatelessWidget {
  /// Das Widget, das angezeigt wird, wenn der Benutzer die Berechtigung hat.
  final Widget child;

  /// Die erforderliche Berechtigung (z.B. 'can_delete_users').
  final String requiredPermission;

  /// Ein optionales Widget, das angezeigt wird, wenn die Berechtigung fehlt.
  final Widget? placeholder;

  const PermissionWrapper({
    super.key,
    required this.child,
    required this.requiredPermission,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, _) {
        // Prüfe, ob der Benutzer die Berechtigung hat.
        if (permissionProvider.hasPermission(requiredPermission)) {
          return child;
        } else {
          // Wenn keine Berechtigung, zeige den Platzhalter oder nichts an.
          return placeholder ?? const SizedBox.shrink();
        }
      },
    );
  }
}
