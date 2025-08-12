# 🔐 Permission Management System Redesign
**Umfassender Architektur-Plan für ein typsicheres und wartbares RBAC-System**

---

## 🎯 **Problemanalyse**

### Aktuelle Probleme
- **Frontend-Backend Mismatch**: Frontend prüft auf Permissions, die nicht existieren
- **String-basierte Checks**: Keine Typsicherheit, anfällig für Tippfehler
- **Dezentrale Permission-Definition**: Permissions nur im Backend-Seeder definiert
- **Manuelle Synchronisation**: Kein automatisierter Abgleich zwischen Frontend und Backend
- **Fehlende Dokumentation**: Keine zentrale Übersicht aller verfügbaren Permissions

### Root Cause
```
Frontend: 'can_manage_staff_users'  ❌ (existiert nicht)
Backend:  'can_view_staff_users'    ✅ (existiert)
         'can_create_staff_users'   ✅ (existiert)
         'can_edit_staff_users'     ✅ (existiert)
```

---

## 🏗️ **Ziel-Architektur: Typsicheres Permission System**

### Vision
Ein **zentralisiertes, typsicheres und automatisch synchronisiertes** Permission Management System, das:
- ✅ **Typsicherheit** durch Enums/Konstanten gewährleistet
- ✅ **Automatische Synchronisation** zwischen Frontend und Backend
- ✅ **Zentrale Definition** aller Permissions
- ✅ **Entwicklerfreundlich** durch IntelliSense und Compile-Time-Checks
- ✅ **Wartbar** durch klare Struktur und Dokumentation

---

## 📋 **Implementierungsplan**

### **WICHTIG: Keine vordefinierten Rollen**
- **NUR der Superuser ist hardcodiert** als einzige feste Entität
- **ALLE anderen Rollen werden dynamisch erstellt** vom Superuser
- **Keine hardcodierten Rollen** wie "Mitarbeiter", "Hall Administrator", etc.
- **Rollen-Hierarchie** wird über `sortOrder` in der Datenbank abgebildet
- **Jede Rolle ist vollständig konfigurierbar** mit individuellen Permissions

### **Phase 1: Backend - Zentrale Permission-Definition**

⚠️ **Hinweis**: Permissions sind fest definiert, aber ROLLEN werden dynamisch erstellt!

#### 1.1 Permission-Konstanten erstellen
```dart
// lib/src/constants/permission_keys.dart
class PermissionKeys {
  // Staff Management
  static const String viewStaffUsers = 'can_view_staff_users';
  static const String createStaffUsers = 'can_create_staff_users';
  static const String editStaffUsers = 'can_edit_staff_users';
  static const String deleteStaffUsers = 'can_delete_staff_users';
  static const String managePermissions = 'can_manage_permissions';
  
  // User Management  
  static const String viewUsers = 'can_view_users';
  static const String createUsers = 'can_create_users';
  static const String editUsers = 'can_edit_users';
  
  // Statistics & Reporting
  static const String viewStatistics = 'can_view_statistics';
  static const String generateReports = 'can_generate_reports';
  
  // System Administration
  static const String accessAdminDashboard = 'can_access_admin_dashboard';
  static const String manageSystemSettings = 'can_manage_system_settings';
}
```

#### 1.2 Permission-Kategorien definieren
```dart
// lib/src/constants/permission_categories.dart
class PermissionCategories {
  static const String staffManagement = 'staff_management';
  static const String userManagement = 'user_management';
  static const String ticketManagement = 'ticket_management';
  static const String systemSettings = 'system_settings';
  static const String reporting = 'reporting';
}
```

#### 1.3 Permission-Seeder refaktorieren
```dart
// lib/src/helpers/permission_seeder.dart
import '../constants/permission_keys.dart';
import '../constants/permission_categories.dart';

class PermissionSeeder {
  static Future<void> _seedStaffManagementPermissions(Session session) async {
    final permissions = [
      _createPermission(
        PermissionKeys.viewStaffUsers,  // ✅ Typsicher
        'Personal anzeigen',
        'Kann alle Mitarbeiter im System einsehen',
        PermissionCategories.staffManagement,
      ),
      // ... weitere Permissions
    ];
  }
}
```

### **Phase 2: Shared Package - Frontend-Backend-Synchronisation**

#### 2.1 Shared Permission Package erstellen
```
vertic_permissions/
├── lib/
│   ├── src/
│   │   ├── permission_keys.dart      # Zentrale Permission-Konstanten
│   │   ├── permission_categories.dart # Kategorien
│   │   ├── permission_metadata.dart   # Metadaten (Icons, Farben, etc.)
│   │   └── permission_groups.dart     # Logische Gruppierungen
│   └── vertic_permissions.dart
└── pubspec.yaml
```

#### 2.2 Permission-Metadaten definieren
```dart
// vertic_permissions/lib/src/permission_metadata.dart
class PermissionMetadata {
  final String key;
  final String displayName;
  final String description;
  final String category;
  final String? iconName;
  final String? color;
  final bool isSystemCritical;

  const PermissionMetadata({
    required this.key,
    required this.displayName,
    required this.description,
    required this.category,
    this.iconName,
    this.color,
    this.isSystemCritical = false,
  });
}

class PermissionRegistry {
  static const List<PermissionMetadata> allPermissions = [
    PermissionMetadata(
      key: PermissionKeys.viewStaffUsers,
      displayName: 'Personal anzeigen',
      description: 'Kann alle Mitarbeiter im System einsehen',
      category: PermissionCategories.staffManagement,
      iconName: 'badge',
      color: '#3F51B5',
    ),
    // ... alle weiteren Permissions
  ];
}
```

### **Phase 3: Frontend - Typsichere Permission-Checks**

#### 3.1 Permission-Wrapper refaktorieren
```dart
// lib/widgets/permission_wrapper.dart
import 'package:vertic_permissions/vertic_permissions.dart';

class PermissionWrapper extends StatelessWidget {
  final String requiredPermission; // Wird durch Enum ersetzt
  final Widget child;
  final Widget? placeholder;

  // Neue typsichere Version:
  const PermissionWrapper.typed({
    required PermissionKey requiredPermission,  // ✅ Typsicher
    required this.child,
    this.placeholder,
  });
}
```

#### 3.2 Frontend-Checks aktualisieren
```dart
// lib/pages/admin/rbac_management_page.dart
import 'package:vertic_permissions/vertic_permissions.dart';

Widget _buildStaffUserTab(RbacStateProvider rbacProvider) {
  return PermissionWrapper.typed(
    requiredPermission: PermissionKeys.viewStaffUsers,  // ✅ Typsicher
    placeholder: _buildAccessDenied('Staff User Management'),
    child: // ... Widget-Inhalt
  );
}

Widget _buildStatisticsTab(RbacStateProvider rbacProvider) {
  return PermissionWrapper.typed(
    requiredPermission: PermissionKeys.viewStatistics,  // ✅ Typsicher
    placeholder: _buildAccessDenied('Statistics'),
    child: // ... Widget-Inhalt
  );
}
```

### **Phase 4: Automatisierung & Tooling**

#### 4.1 Permission-Export-Tool
```dart
// tools/export_permissions.dart
/// Exportiert alle Permissions als JSON für externe Tools
void main() {
  final permissions = PermissionRegistry.allPermissions;
  final json = permissions.map((p) => p.toJson()).toList();
  
  File('permissions.json').writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(json)
  );
  
  print('✅ ${permissions.length} Permissions exported to permissions.json');
}
```

#### 4.2 Synchronisation-Tests
```dart
// test/permission_sync_test.dart
void main() {
  group('Permission Synchronisation Tests', () {
    test('All frontend permissions exist in backend', () async {
      final frontendPermissions = extractFrontendPermissions();
      final backendPermissions = await loadBackendPermissions();
      
      for (final permission in frontendPermissions) {
        expect(
          backendPermissions.contains(permission),
          isTrue,
          reason: 'Permission "$permission" used in frontend but not defined in backend'
        );
      }
    });
    
    test('No unused permissions in backend', () async {
      // Test für ungenutzte Permissions
    });
  });
}
```

### **Phase 5: Migration & Rollout**

#### 5.1 Migrations-Strategie
```sql
-- migrations/add_missing_permissions.sql
INSERT INTO permissions (name, "displayName", description, category, "iconName", color)
VALUES 
  ('can_view_statistics', 'Statistiken anzeigen', 'Kann RBAC-Statistiken einsehen', 'reporting', 'analytics', '#4CAF50'),
  ('can_generate_reports', 'Berichte erstellen', 'Kann detaillierte Berichte generieren', 'reporting', 'description', '#2196F3');
```

#### 5.2 Rollout-Plan
1. **Backend**: Permission-Konstanten und Shared Package erstellen
2. **Migration**: Fehlende Permissions in DB hinzufügen  
3. **Frontend**: Schrittweise auf typsichere Checks umstellen
4. **Tests**: Synchronisation-Tests implementieren
5. **Dokumentation**: Developer Guidelines erstellen

---

## 🔧 **Technische Details**

### Ordnerstruktur
```
vertic_app/
├── vertic_permissions/                 # 📦 Shared Package
│   ├── lib/src/
│   │   ├── permission_keys.dart       # Zentrale Konstanten
│   │   ├── permission_categories.dart # Kategorien
│   │   ├── permission_metadata.dart   # Metadaten
│   │   └── permission_groups.dart     # Logische Gruppierungen
│   └── pubspec.yaml
├── vertic_server/
│   └── lib/src/
│       ├── constants/                 # Backend-Konstanten
│       ├── helpers/
│       │   └── permission_seeder.dart # Refaktoriert
│       └── endpoints/                 # Permission-Checks
└── vertic_staff_app/
    └── lib/
        ├── widgets/
        │   └── permission_wrapper.dart # Typsichere Version
        └── pages/                     # Aktualisierte Permission-Checks
```

### Dependencies
```yaml
# vertic_permissions/pubspec.yaml
name: vertic_permissions
version: 1.0.0

dependencies:
  meta: ^1.9.1

# vertic_server/pubspec.yaml & vertic_staff_app/pubspec.yaml
dependencies:
  vertic_permissions:
    path: ../vertic_permissions
```

---

## 📊 **Vorteile der neuen Architektur**

### Entwickler-Experience
- ✅ **IntelliSense**: Automatische Vervollständigung aller Permissions
- ✅ **Compile-Time-Checks**: Fehler werden zur Entwicklungszeit erkannt
- ✅ **Refactoring-Safety**: Umbenennung von Permissions ist typsicher
- ✅ **Dokumentation**: Alle Permissions sind zentral dokumentiert

### Wartbarkeit
- ✅ **Single Source of Truth**: Permissions nur an einer Stelle definiert
- ✅ **Automatische Synchronisation**: Keine manuellen Abgleiche nötig
- ✅ **Versionierung**: Permissions können versioniert werden
- ✅ **Testbarkeit**: Automatisierte Tests für Synchronisation

### Sicherheit
- ✅ **Keine Tippfehler**: Typsicherheit verhindert falsche Permission-Namen
- ✅ **Vollständigkeit**: Tests stellen sicher, dass alle Permissions existieren
- ✅ **Konsistenz**: Einheitliche Namenskonventionen

---

## 🚀 **Quick Start Guide**

### Schritt 1: Shared Package erstellen
```bash
cd vertic_app
mkdir vertic_permissions
cd vertic_permissions
flutter create --template=package .
```

### Schritt 2: Permission-Konstanten definieren
```dart
// lib/vertic_permissions.dart
export 'src/permission_keys.dart';
export 'src/permission_categories.dart';
export 'src/permission_metadata.dart';
```

### Schritt 3: Backend aktualisieren
```dart
// vertic_server/lib/src/helpers/permission_seeder.dart
import 'package:vertic_permissions/vertic_permissions.dart';

// Alle String-Literale durch Konstanten ersetzen
```

### Schritt 4: Frontend aktualisieren
```dart
// vertic_staff_app/lib/pages/admin/rbac_management_page.dart
import 'package:vertic_permissions/vertic_permissions.dart';

// Permission-Checks auf typsichere Version umstellen
```

### Schritt 5: Tests implementieren
```dart
// test/permission_sync_test.dart
// Automatisierte Tests für Frontend-Backend-Synchronisation
```

---

## 📚 **Weitere Verbesserungen**

### Permission-Gruppen
```dart
class PermissionGroups {
  static const List<String> staffManagement = [
    PermissionKeys.viewStaffUsers,
    PermissionKeys.createStaffUsers,
    PermissionKeys.editStaffUsers,
    PermissionKeys.deleteStaffUsers,
  ];
  
  static const List<String> fullAdminAccess = [
    ...staffManagement,
    PermissionKeys.managePermissions,
    PermissionKeys.accessAdminDashboard,
  ];
}
```

### Permission-Hierarchien
```dart
class PermissionHierarchy {
  static const Map<String, List<String>> implies = {
    PermissionKeys.editStaffUsers: [PermissionKeys.viewStaffUsers],
    PermissionKeys.deleteStaffUsers: [PermissionKeys.viewStaffUsers],
    PermissionKeys.managePermissions: [PermissionKeys.viewStaffPermissions],
  };
}
```

### Conditional Permissions
```dart
class ConditionalPermissions {
  static bool canEditStaffUser(StaffUser currentUser, StaffUser targetUser) {
    // Superuser kann alle bearbeiten
    if (currentUser.staffLevel == StaffUserType.superUser) return true;
    
    // FacilityAdmin kann nur niedrigere Levels bearbeiten
    if (currentUser.staffLevel == StaffUserType.facilityAdmin) {
      return targetUser.staffLevel.index < currentUser.staffLevel.index;
    }
    
    return false;
  }
}
```

---

## 🎯 **Fazit**

Diese Architektur löst die aktuellen Probleme und schafft ein **wartbares, typsicheres und entwicklerfreundliches** Permission Management System.

**Nächste Schritte:**
1. ✅ **Sofortige Lösung**: Frontend-Fixes sind bereits implementiert
2. 🚧 **Phase 1**: Shared Package und Backend-Konstanten erstellen
3. 🚧 **Phase 2**: Frontend schrittweise migrieren
4. 🚧 **Phase 3**: Tests und Automatisierung implementieren

**Zeitaufwand:** ~2-3 Entwicklertage für vollständige Implementierung
**ROI:** Deutlich reduzierte Wartungskosten und erhöhte Entwicklerproduktivität

---

*Erstellt am: 2025-07-31*  
*Version: 1.0*  
*Status: Bereit für Implementierung* ✅
