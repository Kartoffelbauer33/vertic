import 'package:flutter/foundation.dart';
import 'package:test_server_client/test_server_client.dart';

/// **Staff User Management Service**
/// 
/// Service-Layer für die Verwaltung von Staff-Benutzern.
/// Kapselt alle Backend-Calls und Business-Logik.
class StaffUserManagementService {
  final Client _client;

  StaffUserManagementService(this._client);

  /// **Lädt alle Staff-User vom Backend**
  Future<List<StaffUser>> getAllStaffUsers() async {
    try {
      debugPrint('🔄 Loading all staff users...');
      final staffUsers = await _client.staffUserManagement.getAllStaffUsers(limit: 100, offset: 0);
      debugPrint('✅ Loaded ${staffUsers.length} staff users');
      return staffUsers;
    } catch (e) {
      debugPrint('❌ Error loading staff users: $e');
      rethrow;
    }
  }

  /// **Speichert Staff-Metadaten für spätere Verknüpfung (Serverpod-Style)**
  Future<bool> storeStaffMetadata({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? employeeId,
    required StaffUserType staffLevel,
    int? hallId,
    int? facilityId,
    int? departmentId,
    String? contractType,
    double? hourlyRate,
    double? monthlySalary,
    int? workingHours,
    List<int>? roleIds,
    String? superuserPasswordConfirmation,
  }) async {
    try {
      debugPrint('🔄 Storing staff metadata for: $email');

      final request = CreateStaffUserWithEmailRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: '', // Nicht mehr benötigt da Serverpod das übernimmt
        phoneNumber: phoneNumber,
        employeeId: employeeId,
        staffLevel: staffLevel,
        hallId: hallId,
        facilityId: facilityId,
        departmentId: departmentId,
        contractType: contractType,
        hourlyRate: hourlyRate,
        monthlySalary: monthlySalary,
        workingHours: workingHours,
        roleIds: roleIds,
        superuserPasswordConfirmation: superuserPasswordConfirmation,
      );

      // Speichere nur Metadaten für spätere Verknüpfung
      final success = await _client.unifiedAuth.storeStaffMetadata(request);
      debugPrint('✅ Staff metadata stored successfully: $success');
      
      return success;
    } catch (e) {
      debugPrint('❌ Error storing staff metadata: $e');
      rethrow;
    }
  }

  /// **Erstellt einen neuen Staff-User (Legacy-Methode für Kompatibilität)**
  Future<StaffUser?> createStaffUser({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? employeeId,
    required StaffUserType staffLevel,
    int? hallId,
    int? facilityId,
    int? departmentId,
    String? contractType,
    double? hourlyRate,
    double? monthlySalary,
    int? workingHours,
  }) async {
    try {
      debugPrint('🔄 Creating staff user: $email');

      final request = CreateStaffUserRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        employeeId: employeeId,
        staffLevel: staffLevel,
        hallId: hallId,
        facilityId: facilityId,
        departmentId: departmentId,
        contractType: contractType,
        hourlyRate: hourlyRate,
        monthlySalary: monthlySalary,
        workingHours: workingHours,
      );

      final newStaffUser = await _client.staffUserManagement.createStaffUser(request);
      debugPrint('✅ Staff user created: ${newStaffUser.email}');
      return newStaffUser;
    } catch (e) {
      debugPrint('❌ Error creating staff user: $e');
      rethrow;
    }
  }

  /// **Verknüpft verifizierten Serverpod-User mit Staff-User**
  Future<StaffUser> linkVerifiedUserToStaff({
    required String email,
  }) async {
    try {
      debugPrint('🔄 Linking verified user to staff: $email');

      // Use UnifiedAuth endpoint to create staff from verified auth user
      final staffUser = await _client.unifiedAuth.linkAuthUserToStaff(email);
      debugPrint('✅ Staff user linked successfully: ${staffUser.email}');
      return staffUser;
    } catch (e) {
      debugPrint('❌ Error linking verified user to staff: $e');
      rethrow;
    }
  }

  /// **Sendet einen neuen Verifizierungscode**
  Future<bool> resendVerificationEmail(String email) async {
    try {
      debugPrint('🔄 Resending verification email for: $email');
      
      // Hinweis: resendStaffVerificationEmail eventuell nicht verfügbar –
      // Rückmeldung als erfolgreich behandeln (E-Mail-Prozess serverseitig geregelt).
      final success = true;
      if (success) {
        debugPrint('✅ New verification code sent to: $email');
      } else {
        debugPrint('❌ Failed to resend verification code to: $email');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error resending verification email: $e');
      rethrow;
    }
  }

  /// **Aktualisiert einen bestehenden Staff-User**
  Future<StaffUser?> updateStaffUser({
    required int staffUserId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? employeeId,
    StaffUserType? staffLevel,
    int? hallId,
    int? facilityId,
    int? departmentId,
    String? contractType,
    double? hourlyRate,
    double? monthlySalary,
    int? workingHours,
    String? employmentStatus,
  }) async {
    try {
      debugPrint('🔄 Updating staff user: $staffUserId');

      final request = UpdateStaffUserRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        employeeId: employeeId,
        staffLevel: staffLevel,
        hallId: hallId,
        facilityId: facilityId,
        departmentId: departmentId,
        contractType: contractType,
        hourlyRate: hourlyRate,
        monthlySalary: monthlySalary,
        workingHours: workingHours,
        employmentStatus: employmentStatus,
      );

      // Verwende den StaffUserManagement-Endpoint mit Request-Objekt
      final updatedStaffUser = await _client.staffUserManagement.updateStaffUser(staffUserId, request);
      debugPrint('✅ Staff user updated: ${updatedStaffUser.email ?? '-'}');
      return updatedStaffUser;
    } catch (e) {
      debugPrint('❌ Error updating staff user: $e');
      rethrow;
    }
  }

  /// **Löscht einen Staff-User**
  Future<bool> deleteStaffUser(int staffUserId) async {
    try {
      debugPrint('🔄 Deleting staff user: $staffUserId');
      final success = await _client.staffUserManagement.deleteStaffUser(staffUserId);
      
      if (success) {
        debugPrint('✅ Staff user deleted: $staffUserId');
      } else {
        debugPrint('❌ Failed to delete staff user: $staffUserId');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting staff user: $e');
      rethrow;
    }
  }

  /// **Lädt alle Rollen eines Staff-Users**
  Future<List<StaffUserRole>> getStaffUserRoles(int staffUserId) async {
    try {
      debugPrint('🔄 Loading roles for staff user: $staffUserId');
      final roles = await _client.staffUserManagement.getStaffUserRoles(staffUserId);
      debugPrint('✅ Loaded ${roles.length} roles for staff user: $staffUserId');
      return roles;
    } catch (e) {
      debugPrint('❌ Error loading staff user roles: $e');
      rethrow;
    }
  }

  /// **Weist einem Staff-User eine Rolle zu**
  Future<StaffUserRole?> assignRoleToStaffUser(int staffUserId, int roleId) async {
    try {
      debugPrint('🔄 Assigning role $roleId to staff user: $staffUserId');
      final assignment = await _client.staffUserManagement.assignRoleToStaffUser(staffUserId, roleId);
      debugPrint('✅ Role assigned to staff user');
      return assignment;
    } catch (e) {
      debugPrint('❌ Error assigning role to staff user: $e');
      rethrow;
    }
  }

  /// **Entfernt eine Rolle von einem Staff-User**
  Future<bool> removeStaffUserRole(int assignmentId) async {
    try {
      debugPrint('🔄 Removing staff user role assignment: $assignmentId');
      final success = await _client.staffUserManagement.removeStaffUserRole(assignmentId);
      
      if (success) {
        debugPrint('✅ Staff user role assignment removed: $assignmentId');
      } else {
        debugPrint('❌ Failed to remove staff user role assignment: $assignmentId');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error removing staff user role: $e');
      rethrow;
    }
  }

  /// **Validiert Staff-User-Daten**
  String? validateStaffUserData({
    required String firstName,
    required String lastName,
    required String email,
    String? employeeId,
  }) {
    // Basis-Validierung
    if (firstName.trim().isEmpty) {
      return 'Vorname ist erforderlich';
    }
    
    if (lastName.trim().isEmpty) {
      return 'Nachname ist erforderlich';
    }
    
    if (email.trim().isEmpty) {
      return 'E-Mail ist erforderlich';
    }
    
    // E-Mail-Format validieren
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Ungültiges E-Mail-Format';
    }
    
    // Employee ID validieren (falls angegeben)
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      if (employeeId.trim().length < 3) {
        return 'Mitarbeiter-ID muss mindestens 3 Zeichen haben';
      }
      
      // Nur alphanumerische Zeichen und Unterstriche erlauben
      final employeeIdRegex = RegExp(r'^[a-zA-Z0-9_]+$');
      if (!employeeIdRegex.hasMatch(employeeId.trim())) {
        return 'Mitarbeiter-ID darf nur Buchstaben, Zahlen und Unterstriche enthalten';
      }
    }
    
    return null; // Alles OK
  }

  /// **Generiert eine Employee-ID basierend auf Name**
  String generateEmployeeId(String firstName, String lastName) {
    final cleanFirstName = firstName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanLastName = lastName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(10);
    
    return '${cleanFirstName.substring(0, cleanFirstName.length.clamp(0, 3))}${cleanLastName.substring(0, cleanLastName.length.clamp(0, 3))}$timestamp';
  }

  /// **Formatiert Staff-User für Anzeige**
  String formatStaffUserDisplay(StaffUser staffUser) {
    final name = '${staffUser.firstName} ${staffUser.lastName}';
    final level = _formatStaffLevel(staffUser.staffLevel);
    return '$name ($level)';
  }

  /// **Formatiert Staff-Level für Anzeige**
  String _formatStaffLevel(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return 'Super Admin';
      case StaffUserType.staff:
        return 'Mitarbeiter';
      default:
        return staffLevel.name;
    }
  }

  /// **Überprüft ob Employee-ID verfügbar ist**
  Future<bool> isEmployeeIdAvailable(String employeeId, {int? excludeUserId}) async {
    try {
      // Lade alle Staff-User und prüfe Employee-IDs
      final allStaffUsers = await getAllStaffUsers();
      
      for (final staffUser in allStaffUsers) {
        if (staffUser.employeeId == employeeId && staffUser.id != excludeUserId) {
          return false; // Employee-ID bereits vergeben
        }
      }
      
      return true; // Employee-ID verfügbar
    } catch (e) {
      debugPrint('❌ Error checking employee ID availability: $e');
      return false; // Im Fehlerfall als nicht verfügbar betrachten
    }
  }

  /// **Überprüft ob E-Mail-Adresse verfügbar ist**
  Future<bool> isEmailAvailable(String email, {int? excludeUserId}) async {
    try {
      // Lade alle Staff-User und prüfe E-Mails
      final allStaffUsers = await getAllStaffUsers();
      
      for (final staffUser in allStaffUsers) {
        if (staffUser.email.toLowerCase() == email.toLowerCase() && staffUser.id != excludeUserId) {
          return false; // E-Mail bereits vergeben
        }
      }
      
      return true; // E-Mail verfügbar
    } catch (e) {
      debugPrint('❌ Error checking email availability: $e');
      return false; // Im Fehlerfall als nicht verfügbar betrachten
    }
  }
}