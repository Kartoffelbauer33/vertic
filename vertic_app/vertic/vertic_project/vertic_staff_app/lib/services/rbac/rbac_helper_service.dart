import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🎯 RBAC Helper Service**
/// 
/// Utility-Funktionen für RBAC-Management
/// Extrahiert aus RBAC-Management-Page Helper-Methoden
class RbacHelperService {
  
  // ═══════════════════════════════════════════════════════════════
  // 🎨 STAFF LEVEL HELPERS (exakt aus RBAC-Management-Page extrahiert)
  // ═══════════════════════════════════════════════════════════════

  /// **🎨 Farbe für Staff Level**
  /// (Exakt aus _getStaffLevelColor in RBAC-Management-Page extrahiert)
  static Color getStaffLevelColor(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return Colors.red;
      case StaffUserType.staff:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// **🔧 Icon für Staff Level**
  /// (Exakt aus _getStaffLevelIcon in RBAC-Management-Page extrahiert)
  static IconData getStaffLevelIcon(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return Icons.verified;
      case StaffUserType.staff:
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  /// **📝 Text für Staff Level**
  /// (Exakt aus _getStaffLevelText in RBAC-Management-Page extrahiert)
  static String getStaffLevelText(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return 'Super-Administrator';
      case StaffUserType.staff:
        return 'Mitarbeiter';
      default:
        return 'Unbekannt';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔐 PERMISSION CATEGORY HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// **🔧 Icon für Permission-Kategorie**
  /// (Basierend auf bestehenden Patterns aus RBAC-Management-Page)
  static IconData getPermissionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'admin':
      case 'administration':
        return Icons.admin_panel_settings;
      case 'user':
      case 'users':
        return Icons.people;
      case 'product':
      case 'products':
        return Icons.inventory;
      case 'ticket':
      case 'tickets':
        return Icons.confirmation_number;
      case 'pos':
      case 'point_of_sale':
        return Icons.point_of_sale;
      case 'report':
      case 'reports':
        return Icons.analytics;
      case 'system':
        return Icons.settings;
      case 'security':
        return Icons.security;
      default:
        return Icons.key;
    }
  }

  /// **🎨 Farbe für Permission-Kategorie**
  /// (Basierend auf bestehenden Patterns aus RBAC-Management-Page)
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'admin':
      case 'administration':
        return Colors.red;
      case 'user':
      case 'users':
        return Colors.blue;
      case 'product':
      case 'products':
        return Colors.green;
      case 'ticket':
      case 'tickets':
        return Colors.orange;
      case 'pos':
      case 'point_of_sale':
        return Colors.purple;
      case 'report':
      case 'reports':
        return Colors.teal;
      case 'system':
        return Colors.grey;
      case 'security':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📝 TEXT FORMATTING HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// **📝 Formatiert Permission-Name für Anzeige**
  static String formatPermissionName(String permissionName) {
    // Entferne Präfixe wie "can_", "is_", etc.
    String formatted = permissionName
        .replaceAll('can_', '')
        .replaceAll('is_', '')
        .replaceAll('has_', '');

    // Ersetze Unterstriche durch Leerzeichen
    formatted = formatted.replaceAll('_', ' ');

    // Kapitalisiere ersten Buchstaben jedes Wortes
    return formatted.split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// **📝 Formatiert Staff User Name für Anzeige**
  static String formatStaffUserName(StaffUser staffUser) {
    final firstName = staffUser.firstName ?? '';
    final lastName = staffUser.lastName ?? '';
    
    if (firstName.isEmpty && lastName.isEmpty) {
      return staffUser.email;
    }
    
    return '$firstName $lastName'.trim();
  }

  /// **📝 Formatiert Role Name für Anzeige**
  static String formatRoleName(Role role) {
    return role.displayName ?? role.name;
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔍 VALIDATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// **✅ Validiert Email-Format**
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  /// **✅ Validiert Staff User Daten**
  static String? validateStaffUserData({
    required String firstName,
    required String lastName,
    required String email,
  }) {
    if (firstName.trim().isEmpty) {
      return 'Vorname ist erforderlich';
    }
    
    if (lastName.trim().isEmpty) {
      return 'Nachname ist erforderlich';
    }
    
    if (email.trim().isEmpty) {
      return 'E-Mail ist erforderlich';
    }
    
    if (!isValidEmail(email)) {
      return 'Ungültiges E-Mail-Format';
    }
    
    return null; // Alles valid
  }

  /// **✅ Validiert Role Name**
  static String? validateRoleName(String roleName) {
    if (roleName.trim().isEmpty) {
      return 'Rollenname ist erforderlich';
    }
    
    if (roleName.length < 3) {
      return 'Rollenname muss mindestens 3 Zeichen lang sein';
    }
    
    if (roleName.length > 50) {
      return 'Rollenname darf maximal 50 Zeichen lang sein';
    }
    
    return null; // Valid
  }

  // ═══════════════════════════════════════════════════════════════
  // 📊 STATISTICS HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// **📊 Zählt Permissions pro Kategorie**
  static Map<String, int> getPermissionCountsByCategory(List<Permission> permissions) {
    final counts = <String, int>{};
    
    for (final permission in permissions) {
      final category = permission.category;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    
    return counts;
  }

  /// **📊 Zählt Staff Users pro Level**
  static Map<StaffUserType, int> getStaffUserCountsByLevel(List<StaffUser> staffUsers) {
    final counts = <StaffUserType, int>{};
    
    for (final staffUser in staffUsers) {
      final level = staffUser.staffLevel;
      counts[level] = (counts[level] ?? 0) + 1;
    }
    
    return counts;
  }

  /// **📊 Berechnet Role-Permission-Statistiken**
  static Map<String, dynamic> getRoleStatistics(List<Role> roles) {
    return {
      'totalRoles': roles.length,
      'systemRoles': roles.where((r) => r.isSystemRole).length,
      'customRoles': roles.where((r) => !r.isSystemRole).length,
    };
  }
}
