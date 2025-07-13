import 'package:serverpod/serverpod.dart';
import 'dart:typed_data'; // Für ByteData
import '../generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

/// Endpoint für Benutzerprofil-Verwaltung
///
/// ⚠️ **MIGRATION ZU UNIFIED AUTH:**
/// - saveExtendedProfile() → unifiedAuth.updateClientProfile()
/// - getCurrentUserProfile() → unifiedAuth.getCurrentUserProfile()
/// - completeClientRegistration() → unifiedAuth.completeClientRegistration()
class UserProfileEndpoint extends Endpoint {
  /// 🔐 PRIVATE: Authenticated StaffUser ID ermitteln
  Future<int?> _getAuthenticatedStaffUserId(Session session) async {
    return await StaffAuthHelper.getAuthenticatedStaffUserId(session);
  }

  /// Erstellt Child-Account mit Parent-Verknüpfung (NEUES FAMILY SYSTEM)
  Future<AppUser?> addChildAccount(
    Session session,
    int parentUserId,
    String firstName,
    String lastName,
    DateTime birthDate,
    String gender, {
    String? address,
    String? city,
    String? postalCode,
    String? phoneNumber,
  }) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Child-Account-Erstellung verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_user_profiles');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_user_profiles (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      final now = DateTime.now().toUtc();

      // Validierung: Kind muss unter 18 sein
      final age = DateTime.now().difference(birthDate).inDays / 365.25;
      if (age >= 18) {
        session.log(
            'Child-Account-Erstellung fehlgeschlagen: Person ist nicht minderjährig (Alter: ${age.toStringAsFixed(1)})',
            level: LogLevel.warning);
        return null;
      }

      // Hole Parent-Daten für Email und Adresse
      final parentUser = await AppUser.db.findById(session, parentUserId);
      if (parentUser == null) {
        session.log('Parent User nicht gefunden: $parentUserId',
            level: LogLevel.error);
        return null;
      }

      // Generiere einzigartige Email für das Kind
      final childEmail =
          '${firstName.toLowerCase()}.${lastName.toLowerCase()}.child@${parentUser.email?.split('@').last ?? 'family.local'}';

      // Erstelle Child AppUser (KEIN Serverpod-Auth, da minderjährig)
      final childUser = AppUser(
        firstName: firstName,
        lastName: lastName,
        email: childEmail,
        parentEmail: parentUser.email,
        gender: gender,
        address: address ?? parentUser.address, // Parent-Adresse als Default
        city: city ?? parentUser.city,
        postalCode: postalCode ?? parentUser.postalCode,
        phoneNumber: phoneNumber ?? parentUser.phoneNumber,
        birthDate: birthDate,
        isMinor: true,
        requiresParentalConsent: true,
        accountStatus: 'child_account',
        isEmailVerified:
            false, // Child benötigt keine separate Email-Verifikation
        createdAt: now,
        updatedAt: now,
      );

      final savedChild = await AppUser.db.insertRow(session, childUser);
      session.log(
          'Child-Account erstellt: $firstName $lastName (ID: ${savedChild.id}, Parent: $parentUserId) von Staff $authUserId',
          level: LogLevel.info);

      return savedChild;
    } catch (e) {
      session.log('Fehler bei addChildAccount: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Lädt alle Kinder eines Parents
  Future<List<AppUser>> getChildrenOfParent(
      Session session, int parentUserId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Family-Zugriff verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_user_profiles');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_user_profiles (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      // Finde alle UserRelationships wo User Parent ist
      final relationships = await UserRelationship.db.find(
        session,
        where: (t) =>
            t.parentUserId.equals(parentUserId) & t.isActive.equals(true),
      );

      if (relationships.isEmpty) {
        return [];
      }

      // Lade alle Child-User
      final childIds = relationships.map((r) => r.childUserId).toList();
      final children = <AppUser>[];

      for (final childId in childIds) {
        final child = await AppUser.db.findById(session, childId);
        if (child != null) {
          children.add(child);
        }
      }

      session.log('${children.length} Kinder für Parent $parentUserId geladen',
          level: LogLevel.info);
      return children;
    } catch (e) {
      session.log('Fehler bei getChildrenOfParent: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Lädt Benutzerprofil nach Email
  Future<AppUser?> getUserProfile(Session session, String email) async {
    // 🔑 HYBRID-AUTHENTICATION - BEIDE APPS UNTERSTÜTZEN
    int? authenticatedUserId;
    String authSource = '';

    // 1. ZUERST: Staff-Authentication prüfen (für Staff-App)
    final staffUserId = await _getAuthenticatedStaffUserId(session);
    if (staffUserId != null) {
      final hasPermission = await PermissionHelper.hasPermission(
          session, staffUserId, 'can_view_user_profiles');
      if (!hasPermission) {
        session.log(
            '❌ Fehlende Berechtigung: can_view_user_profiles (User: $staffUserId)',
            level: LogLevel.warning);
        return null;
      }

      // Staff-User gefunden - lade den zugehörigen AppUser
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser != null) {
        // Finde den entsprechenden AppUser basierend auf Email
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.email.equals(staffUser.email),
        );
        if (appUser != null) {
          authenticatedUserId = appUser.id;
          authSource = 'Staff-Auth';
          session.log(
              '🔑 $authSource: Staff-User ${staffUser.email} → AppUser-ID $authenticatedUserId');
        }
      }

      // Staff darf beliebige Profile sehen (unabhängig von eigener Email)
      try {
        session.log('✅ Staff-Zugriff auf Profil $email erlaubt');
        return await AppUser.db.findFirstRow(
          session,
          where: (t) => t.email.equals(email),
        );
      } catch (e) {
        session.log('Fehler bei getUserProfile: $e', level: LogLevel.error);
        return null;
      }
    }

    // 2. FALLBACK: Client-App Authentication prüfen (für Client-App)
    final authInfo = await session.authenticated;
    if (authInfo != null) {
      // **NEUE METHODE: Finde AppUser basierend auf userInfoId (nicht mehr Email!)**
      final appUser = await AppUser.db.findFirstRow(
        session,
        where: (u) => u.userInfoId.equals(authInfo.userId),
      );
      if (appUser != null) {
        authenticatedUserId = appUser.id;
        authSource = 'Client-Auth';
        session.log(
            '🔑 $authSource: UserInfo.id=${authInfo.userId} → AppUser-ID $authenticatedUserId (${appUser.email})');

        // Client-App: Nur eigenes Profil sehen (Email-basierte Validierung)
        session.log(
            '🔍 PROFILE Client Email-Validierung: authenticated="${appUser.email}" vs angefragt="$email"');
        if (appUser.email?.toLowerCase() != email.toLowerCase()) {
          session.log(
              '❌ AppUser darf nur sein eigenes Profil sehen - authenticated: "${appUser.email}" != angefragt: "$email"',
              level: LogLevel.warning);
          return null;
        }
        session
            .log('✅ PROFILE Client Email-Validierung erfolgreich für: $email');
      } else {
        session.log(
            '🔑 Client-Auth FEHLER: Kein AppUser für UserInfo.id=${authInfo.userId} gefunden!',
            level: LogLevel.error);
        return null;
      }
    }

    // 3. VALIDIERUNG: Keine Authentication gefunden
    if (authenticatedUserId == null) {
      session.log('❌ Nicht eingeloggt - Profil-Zugriff verweigert',
          level: LogLevel.warning);
      return null;
    }

    // 4. Profil laden
    try {
      return await AppUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );
    } catch (e) {
      session.log('Fehler bei getUserProfile: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Manuelle Freigabe durch Staff (für Minderjährige)
  Future<bool> manuallyApproveUser(
    Session session,
    int userId,
    int staffId,
    String reason,
  ) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - User-Freigabe verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_approve_users');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_approve_users (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      final now = DateTime.now().toUtc();

      var user = await AppUser.db.findById(session, userId);
      if (user == null) {
        session.log('User für manuelle Freigabe nicht gefunden: $userId',
            level: LogLevel.warning);
        return false;
      }

      user = user.copyWith(
        accountStatus: 'manual_approved',
        isManuallyApproved: true,
        approvedBy: staffId,
        approvedAt: now,
        approvalReason: reason,
        isBlocked: false,
        blockedReason: null,
        blockedAt: null,
        updatedAt: now,
      );

      await AppUser.db.updateRow(session, user);

      session.log('User manuell freigegeben: ${user.email} von Staff: $staffId',
          level: LogLevel.info);
      return true;
    } catch (e) {
      session.log('Fehler bei manuallyApproveUser: $e', level: LogLevel.error);
      return false;
    }
  }

  /// FOTO-MANAGEMENT

  /// Lädt ein Profilbild für einen Benutzer hoch
  Future<bool> uploadProfilePhoto(
      Session session, String userEmail, ByteData photoData) async {
    // 🔑 UNIFIED AUTHENTICATION SYSTEM (Phase 3.1)
    int? authenticatedUserId;
    String authSource = '';

    // 1. ZUERST: Staff-Authentication prüfen (für Staff-App)
    final staffUserId = await _getAuthenticatedStaffUserId(session);
    if (staffUserId != null) {
      final hasPermission = await PermissionHelper.hasPermission(
          session, staffUserId, 'can_manage_user_profiles');
      if (!hasPermission) {
        session.log(
            '❌ Fehlende Berechtigung: can_manage_user_profiles (User: $staffUserId)',
            level: LogLevel.warning);
        return false;
      }

      // Staff-User gefunden
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser != null) {
        authSource = 'Staff-Auth';
        session.log('🔑 $authSource: Staff-Upload für $userEmail');
      }
    } else {
      // 2. FALLBACK: Client-App Authentication prüfen (für Client-App)
      final authInfo = await session.authenticated;
      if (authInfo != null) {
        // Finde AppUser basierend auf userInfoId
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.userInfoId.equals(authInfo.userId),
        );
        if (appUser != null) {
          authenticatedUserId = appUser.id;
          authSource = 'Client-Auth';

          // Client darf nur sein eigenes Foto hochladen
          if (appUser.email != userEmail) {
            session.log(
                '❌ Client-Auth FEHLER: Kann nur eigenes Foto hochladen (${appUser.email} ≠ $userEmail)',
                level: LogLevel.warning);
            return false;
          }

          session.log(
              '🔑 $authSource: Client-Upload für eigenes Profil $userEmail');
        } else {
          session.log(
              '❌ Client-Auth FEHLER: Kein AppUser für UserInfo.id=${authInfo.userId} gefunden!',
              level: LogLevel.error);
          return false;
        }
      } else {
        session.log('❌ Nicht eingeloggt - Foto-Upload verweigert',
            level: LogLevel.warning);
        return false;
      }
    }

    try {
      // Validierung: Foto-Größe prüfen (max 1MB)
      if (photoData.lengthInBytes > 1024 * 1024) {
        throw Exception('Foto ist zu groß (max 1MB erlaubt)');
      }

      // Validierung: Mindestgröße prüfen (min 1KB)
      if (photoData.lengthInBytes < 1024) {
        throw Exception('Foto ist zu klein (min 1KB erforderlich)');
      }

      // Benutzer finden
      final user = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(userEmail),
      );

      if (user == null) {
        throw Exception('Benutzer nicht gefunden');
      }

      // Foto speichern
      final updatedUser = user.copyWith(
        profilePhoto: photoData,
        photoUploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await AppUser.db.updateRow(session, updatedUser);

      session.log('✅ $authSource: Profilbild hochgeladen für User: $userEmail',
          level: LogLevel.info);
      return true;
    } catch (e) {
      session.log('❌ Fehler beim Foto-Upload: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Gibt das Profilbild eines Benutzers zurück
  Future<ByteData?> getProfilePhoto(Session session, String userEmail) async {
    // 🔑 UNIFIED AUTHENTICATION SYSTEM (Phase 3.1)
    int? authenticatedUserId;
    String authSource = '';

    // 1. ZUERST: Staff-Authentication prüfen (für Staff-App)
    final staffUserId = await _getAuthenticatedStaffUserId(session);
    if (staffUserId != null) {
      final hasPermission = await PermissionHelper.hasPermission(
          session, staffUserId, 'can_view_user_profiles');
      if (!hasPermission) {
        session.log(
            '❌ Fehlende Berechtigung: can_view_user_profiles (User: $staffUserId)',
            level: LogLevel.warning);
        return null;
      }

      // Staff-User gefunden
      authSource = 'Staff-Auth';
      session.log('🔑 $authSource: Staff-Zugriff auf Foto $userEmail');
    } else {
      // 2. FALLBACK: Client-App Authentication prüfen (für Client-App)
      final authInfo = await session.authenticated;
      if (authInfo != null) {
        // Finde AppUser basierend auf userInfoId
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.userInfoId.equals(authInfo.userId),
        );
        if (appUser != null) {
          authenticatedUserId = appUser.id;
          authSource = 'Client-Auth';

          // Client darf nur sein eigenes Foto sehen
          if (appUser.email != userEmail) {
            session.log(
                '❌ Client-Auth FEHLER: Kann nur eigenes Foto abrufen (${appUser.email} ≠ $userEmail)',
                level: LogLevel.warning);
            return null;
          }

          session.log(
              '🔑 $authSource: Client-Zugriff auf eigenes Foto $userEmail');
        } else {
          session.log(
              '❌ Client-Auth FEHLER: Kein AppUser für UserInfo.id=${authInfo.userId} gefunden!',
              level: LogLevel.error);
          return null;
        }
      } else {
        session.log('❌ Nicht eingeloggt - Foto-Zugriff verweigert',
            level: LogLevel.warning);
        return null;
      }
    }

    try {
      final user = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(userEmail),
      );

      if (user == null) {
        throw Exception('Benutzer nicht gefunden');
      }

      session.log('✅ $authSource: Profilbild abgerufen für $userEmail');
      return user.profilePhoto;
    } catch (e) {
      session.log('❌ Fehler beim Laden des Profilbilds: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Löscht das Profilbild eines Benutzers
  Future<bool> deleteProfilePhoto(Session session, String userEmail) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Foto-Löschung verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_user_profiles');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_user_profiles (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      final user = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(userEmail),
      );

      if (user == null) {
        throw Exception('Benutzer nicht gefunden');
      }

      final updatedUser = user.copyWith(
        profilePhoto: null,
        photoUploadedAt: null,
        updatedAt: DateTime.now(),
      );

      await AppUser.db.updateRow(session, updatedUser);

      session.log('Profilbild gelöscht für User: $userEmail',
          level: LogLevel.info);
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen des Profilbilds: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Genehmigt ein Profilbild (für Staff/Admin)
  Future<bool> approveProfilePhoto(
      Session session, String userEmail, int approvedByStaffId) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Foto-Genehmigung verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_approve_users');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_approve_users (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      final user = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(userEmail),
      );

      if (user == null) {
        throw Exception('Benutzer nicht gefunden');
      }

      if (user.profilePhoto == null) {
        throw Exception('Kein Profilbild vorhanden');
      }

      final updatedUser = user.copyWith(
        photoApprovedBy: approvedByStaffId,
        updatedAt: DateTime.now(),
      );

      await AppUser.db.updateRow(session, updatedUser);

      session.log(
          'Profilbild genehmigt für User: $userEmail von Staff: $approvedByStaffId',
          level: LogLevel.info);
      return true;
    } catch (e) {
      session.log('Fehler beim Genehmigen des Profilbilds: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // PRIVATE HILFSMETHODEN

  /// Prüft ob User minderjährig ist basierend auf Geburtsdatum
  bool _isUserMinor(DateTime? birthDate) {
    if (birthDate != null) {
      final age = DateTime.now().difference(birthDate).inDays / 365.25;
      return age < 18;
    }
    return false; // Default: nicht minderjährig wenn kein Geburtsdatum
  }
}
