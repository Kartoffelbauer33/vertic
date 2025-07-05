import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as auth;
import 'package:bcrypt/bcrypt.dart';
import '../generated/protocol.dart';
import '../helpers/permission_helper.dart';
import '../helpers/unified_auth_helper.dart';
import '../helpers/staff_auth_helper.dart';

/// 🎯 **UNIFIED AUTHENTICATION ENDPOINT (Phase 3.1)**
///
/// **ZIEL:** Beide Apps verwenden Serverpod 2.8 native Authentication
/// **LÖSUNG:** Staff = Username-basiert, Client = Email-basiert
/// **VORTEILE:** Einheitliche `session.authenticated` API für alle Endpoints
///
/// **ARCHITEKTUR (UPDATED):**
/// - Staff: Echte E-Mail-Adressen + Username für flexibles Login
/// - Client: Email wird normal in Serverpod gespeichert
/// - Getrennte Tabellen (StaffUser, AppUser) bleiben erhalten
/// - RBAC-System bleibt vollständig funktional
/// - Staff kann sich mit Username ODER E-Mail anmelden
class UnifiedAuthEndpoint extends Endpoint {
  /// **STAFF-DOMAIN für Fake-Emails (DEPRECATED)**
  /// Wird nicht mehr verwendet - Staff verwendet jetzt echte E-Mail-Adressen
  static const String staffDomain = '@staff.vertic.local';

  // ═══════════════════════════════════════════════════════════════
  // 🔐 STAFF AUTHENTICATION (Username-basiert)
  // ═══════════════════════════════════════════════════════════════

  /// **STAFF: Create User with Email Verification (Admin-managed)**
  ///
  /// Erstellt einen Staff-User mit E-Mail-Bestätigung (wie Client-System)
  /// Der User muss seine E-Mail bestätigen bevor er sich anmelden kann
  Future<UnifiedAuthResponse> createStaffUserWithEmail(
    Session session,
    String email,
    String username,
    String password,
    String firstName,
    String lastName,
    StaffUserType staffLevel,
  ) async {
    try {
      // 🔐 STAFF PERMISSION CHECK mit StaffAuthHelper
      final authUserId =
          await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      if (authUserId == null) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Authentifizierung erforderlich',
          staffUser: null,
        );
      }

      final hasPermission = await PermissionHelper.hasPermission(
          session, authUserId, 'can_create_staff_users');
      if (!hasPermission) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Fehlende Berechtigung: can_create_staff_users',
          staffUser: null,
        );
      }

      // 1. **Prüfe ob Username bereits existiert**
      final existingStaff = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.employeeId.equals(username),
      );

      if (existingStaff != null) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Username bereits vergeben',
          staffUser: null,
        );
      }

      // 2. **Prüfe ob E-Mail bereits existiert**
      final existingEmailAuth = await auth.EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );

      if (existingEmailAuth != null) {
        return UnifiedAuthResponse(
          success: false,
          message: 'E-Mail-Adresse bereits registriert',
          staffUser: null,
        );
      }

      // 3. **UserInfo erstellen mit E-Mail-Bestätigung erforderlich**
      final userInfo = auth.UserInfo(
        userIdentifier: email, // Echte Email als userIdentifier
        email: email,
        userName: username,
        fullName: '$firstName $lastName',
        created: DateTime.now(),
        blocked: true, // 🔒 BLOCKED bis E-Mail bestätigt wird!
        scopeNames: ['staff'], // Staff-Scope für Berechtigungsunterscheidung
      );

      final createdUserInfo =
          await auth.UserInfo.db.insertRow(session, userInfo);

      // 4. **EmailAuth für Password erstellen**
      final emailAuth = auth.EmailAuth(
        userId: createdUserInfo.id!,
        email: email,
        hash: _hashPassword(password),
      );

      await auth.EmailAuth.db.insertRow(session, emailAuth);

      // 5. **StaffUser in eigener Tabelle erstellen (PENDING bis E-Mail bestätigt)**
      final staffUser = StaffUser(
        userInfoId: createdUserInfo.id!, // 🔗 Verknüpfung zu Serverpod Auth
        firstName: firstName,
        lastName: lastName,
        email: email, // Echte Email
        employeeId: username,
        staffLevel: staffLevel,
        employmentStatus:
            'pending_verification', // 📧 Warten auf E-Mail-Bestätigung
        createdAt: DateTime.now(),
        createdBy: authUserId,
      );

      final savedStaffUser = await StaffUser.db.insertRow(session, staffUser);

      // 6. **E-Mail-Bestätigungstoken erstellen (vereinfacht für Entwicklung)**
      final verificationCode = 'STAFF_${DateTime.now().millisecondsSinceEpoch}';

      session.log(
          '✅ Staff-User erstellt (pending verification): $username ($email) → UserInfo.id=${createdUserInfo.id}');
      session
          .log('📧 E-Mail-Bestätigung erforderlich - Code: $verificationCode');

      return UnifiedAuthResponse(
        success: true,
        message: 'Staff-User erstellt. E-Mail-Bestätigung erforderlich.',
        staffUser: savedStaffUser,
        userInfoId: createdUserInfo.id,
        requiresEmailVerification: true,
        verificationCode: verificationCode,
      );
    } catch (e, stackTrace) {
      session.log('❌ Staff-User-Erstellung fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return UnifiedAuthResponse(
        success: false,
        message: 'Fehler beim Erstellen: $e',
        staffUser: null,
      );
    }
  }

  /// **STAFF: Verify Email for Staff User**
  ///
  /// Bestätigt die E-Mail-Adresse eines Staff-Users und aktiviert den Account
  Future<UnifiedAuthResponse> verifyStaffEmail(
    Session session,
    String email,
    String verificationCode,
  ) async {
    try {
      // Vereinfachte Verifizierung für Entwicklung
      // TODO: Echte E-Mail-Verifizierung implementieren
      if (!verificationCode.startsWith('STAFF_')) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Ungültiger Bestätigungscode',
          staffUser: null,
        );
      }

      // UserInfo entsperren
      final emailAuth = await auth.EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );

      if (emailAuth == null) {
        return UnifiedAuthResponse(
          success: false,
          message: 'E-Mail-Adresse nicht gefunden',
          staffUser: null,
        );
      }

      final userInfo = await auth.UserInfo.db.findById(
        session,
        emailAuth.userId,
      );

      if (userInfo != null) {
        await auth.UserInfo.db.updateRow(
          session,
          userInfo.copyWith(blocked: false),
        );
      }

      // StaffUser auf aktiv setzen
      final staffUser = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(emailAuth.userId),
      );

      if (staffUser == null) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Staff-User nicht gefunden',
          staffUser: null,
        );
      }

      final activatedStaffUser = await StaffUser.db.updateRow(
        session,
        staffUser.copyWith(
          employmentStatus: 'active',
          emailVerifiedAt: DateTime.now(),
        ),
      );

      session.log(
          '✅ Staff-User E-Mail bestätigt und aktiviert: ${staffUser.employeeId} ($email)');

      return UnifiedAuthResponse(
        success: true,
        message: 'E-Mail erfolgreich bestätigt. Account ist jetzt aktiv.',
        staffUser: activatedStaffUser,
        userInfoId: userInfo?.id,
      );
    } catch (e, stackTrace) {
      session.log('❌ E-Mail-Bestätigung fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return UnifiedAuthResponse(
        success: false,
        message: 'Fehler bei E-Mail-Bestätigung: $e',
        staffUser: null,
      );
    }
  }

  /// **STAFF: Sign In with Username or Email**
  ///
  /// Staff kann sich mit Username ODER E-Mail anmelden
  /// Flexibles Login-System für beide Varianten
  Future<UnifiedAuthResponse> staffSignInFlexible(
    Session session,
    String usernameOrEmail,
    String password,
  ) async {
    try {
      session.log('🔐 Staff-Login (Flexibel): $usernameOrEmail');

      auth.EmailAuth? emailAuth;
      StaffUser? staffUser;

      // 1. **Prüfe ob es eine E-Mail-Adresse ist**
      if (usernameOrEmail.contains('@')) {
        // Login mit E-Mail
        emailAuth = await auth.EmailAuth.db.findFirstRow(
          session,
          where: (t) => t.email.equals(usernameOrEmail),
        );

        if (emailAuth != null) {
          staffUser = await StaffUser.db.findFirstRow(
            session,
            where: (t) =>
                t.userInfoId.equals(emailAuth!.userId) &
                t.employmentStatus.equals('active'),
          );
        }
      } else {
        // Login mit Username - suche über StaffUser
        staffUser = await StaffUser.db.findFirstRow(
          session,
          where: (t) =>
              t.employeeId.equals(usernameOrEmail) &
              t.employmentStatus.equals('active'),
        );

        if (staffUser != null) {
          emailAuth = await auth.EmailAuth.db.findFirstRow(
            session,
            where: (t) => t.userId.equals(staffUser!.userInfoId),
          );
        }
      }

      if (emailAuth == null || staffUser == null) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Benutzer nicht gefunden',
          staffUser: null,
        );
      }

      // 2. **Password validieren**
      if (!_verifyPassword(password, emailAuth.hash)) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Ungültige Anmeldedaten',
          staffUser: null,
        );
      }

      // 3. **Login-Zeitstempel aktualisieren**
      await StaffUser.db.updateRow(
        session,
        staffUser.copyWith(lastLoginAt: DateTime.now()),
      );

      // 4. **Staff-Token für andere Endpoints erstellen**
      final staffToken = _generateStaffToken(staffUser.id!, emailAuth.userId);
      await StaffAuthHelper.setStaffSession(
        session,
        staffUser.id!,
        staffToken,
      );

      session.log(
          '✅ Staff-Login erfolgreich: ${staffUser.employeeId} (${staffUser.email}) → UserInfo.id=${emailAuth.userId}');
      session.log('🔐 Staff-Token erstellt für weitere API-Calls');

      return UnifiedAuthResponse(
        success: true,
        message: 'Login erfolgreich',
        staffUser: staffUser,
        userInfoId: emailAuth.userId,
        staffToken: staffToken,
      );
    } catch (e, stackTrace) {
      session.log('❌ Staff-Login (Flexibel) fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return UnifiedAuthResponse(
        success: false,
        message: 'Authentifizierung fehlgeschlagen',
        staffUser: null,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 👤 CLIENT AUTHENTICATION (Email-basiert)
  // ═══════════════════════════════════════════════════════════════

  /// **CLIENT: Register with Email (Normal Serverpod Flow)**
  ///
  /// Client registriert sich mit Email + Passwort
  /// Normale Serverpod Email-Verifikation
  Future<bool> clientSignUpUnified(
    Session session,
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      session.log('📧 Client-Registrierung (Unified): $email');

      // 1. **UserInfo für Client erstellen**
      final userInfo = auth.UserInfo(
        userIdentifier: email, // Email als userIdentifier für Clients
        email: email,
        userName: '$firstName $lastName',
        fullName: '$firstName $lastName',
        created: DateTime.now(),
        blocked: false,
        scopeNames: ['client'], // Client-Scope für Berechtigungsunterscheidung
      );

      // 2. **User erstellen**
      final createdUserInfo =
          await auth.UserInfo.db.insertRow(session, userInfo);

      // 3. **Password-Hash erstellen und speichern**
      final emailAuth = auth.EmailAuth(
        userId: createdUserInfo.id!,
        email: email,
        hash: _hashPassword(password),
      );

      await auth.EmailAuth.db.insertRow(session, emailAuth);

      // 4. **AppUser in eigener Tabelle erstellen**
      final appUser = AppUser(
        userInfoId: createdUserInfo.id!, // 🔗 Verknüpfung zu Serverpod Auth
        firstName: firstName,
        lastName: lastName,
        email: email,
        isEmailVerified:
            true, // ✅ Email ist verifiziert nach manueller Registrierung
        createdAt: DateTime.now(),
      );

      await AppUser.db.insertRow(session, appUser);

      session.log(
          '✅ Client-Registrierung erfolgreich: $email → UserInfo.id=${createdUserInfo.id}');
      return true;
    } catch (e, stackTrace) {
      session.log('❌ Client-Registrierung fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return false;
    }
  }

  /// **CLIENT: Sign In with Email (Normal Serverpod Flow)**
  Future<bool> clientSignInUnified(
    Session session,
    String email,
    String password,
  ) async {
    try {
      session.log('📧 Client-Login (Unified): $email');

      // 1. **Email-Auth finden**
      final emailAuth = await auth.EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );

      if (emailAuth == null) {
        session.log('❌ Client-Login fehlgeschlagen: Email nicht gefunden');
        return false;
      }

      // 2. **Password validieren**
      if (!_verifyPassword(password, emailAuth.hash)) {
        session.log('❌ Client-Login fehlgeschlagen: Ungültiges Passwort');
        return false;
      }

      // 3. **AppUser Login-Zeitstempel aktualisieren**
      final appUser = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(emailAuth.userId),
      );

      if (appUser != null) {
        await AppUser.db.updateRow(
          session,
          appUser.copyWith(lastLoginAt: DateTime.now()),
        );
      }

      session.log(
          '✅ Client-Login erfolgreich: $email (UserInfo.id=${emailAuth.userId})');
      return true;
    } catch (e, stackTrace) {
      session.log('❌ Client-Login (Unified) fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📱 CLIENT AUTHENTICATION (Email-basiert)
  // ═══════════════════════════════════════════════════════════════

  /// **CLIENT: Get Current User Profile**
  ///
  /// Ersetzt getUserProfileByEmail() für Client-App
  /// Verwendet Serverpod 2.8 native Authentication
  Future<AppUser?> getCurrentUserProfile(Session session) async {
    try {
      // 1. **Serverpod Auth prüfen**
      final authInfo = await session.authenticated;
      if (authInfo == null) {
        session.log('❌ getCurrentUserProfile: Nicht authentifiziert');
        return null;
      }

      // 2. **UserInfo direkt aus DB laden (nicht aus Session-Cache)**
      // PROBLEM GEFUNDEN: session.authenticated liefert gecachte Daten!
      final userInfo =
          await auth.UserInfo.db.findById(session, authInfo.userId);
      if (userInfo == null) {
        session.log(
            '❌ getCurrentUserProfile: UserInfo nicht gefunden für ID=${authInfo.userId}');
        return null;
      }

      // 3. **Client-Scope prüfen (aus DB, nicht aus Cache)**
      if (!userInfo.scopeNames.contains('client')) {
        session.log(
            '❌ getCurrentUserProfile: Fehlender Client-Scope - Current Scopes: ${userInfo.scopeNames}');
        return null;
      }

      // 4. **AppUser aus Datenbank laden**
      final appUser = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(authInfo.userId),
      );

      if (appUser == null) {
        session.log(
            '❌ getCurrentUserProfile: AppUser nicht gefunden für UserInfo.id=${authInfo.userId}');
        return null;
      }

      session
          .log('✅ getCurrentUserProfile: AppUser geladen für ${appUser.email}');
      return appUser;
    } catch (e, stackTrace) {
      session.log('❌ getCurrentUserProfile fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return null;
    }
  }

  /// **CLIENT: Update Profile**
  ///
  /// Ersetzt saveExtendedProfile() für authentifizierte Clients
  Future<AppUser?> updateClientProfile(
    Session session,
    String firstName,
    String lastName,
    String? parentEmail,
    DateTime? birthDate,
    String? gender,
    String? address,
    String? city,
    String? postalCode,
    String? phoneNumber,
  ) async {
    try {
      // 1. **Serverpod Auth prüfen**
      final authInfo = await session.authenticated;
      if (authInfo == null) {
        session.log('❌ updateClientProfile: Nicht authentifiziert');
        return null;
      }

      // 2. **UserInfo direkt aus DB laden (nicht aus Session-Cache)**
      final userInfo =
          await auth.UserInfo.db.findById(session, authInfo.userId);
      if (userInfo == null) {
        session.log(
            '❌ updateClientProfile: UserInfo nicht gefunden für ID=${authInfo.userId}');
        return null;
      }

      // 3. **Client-Scope prüfen (aus DB, nicht aus Cache)**
      if (!userInfo.scopeNames.contains('client')) {
        session.log(
            '❌ updateClientProfile: Fehlender Client-Scope - Current Scopes: ${userInfo.scopeNames}');
        return null;
      }

      // 4. **Bestehenden AppUser laden**
      final existingUser = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(authInfo.userId),
      );

      if (existingUser == null) {
        session.log(
            '❌ updateClientProfile: AppUser nicht gefunden für UserInfo.id=${authInfo.userId}');
        return null;
      }

      // 5. **Profil aktualisieren**
      final updatedUser = existingUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        parentEmail: parentEmail,
        birthDate: birthDate,
        gender: gender,
        address: address,
        city: city,
        postalCode: postalCode,
        phoneNumber: phoneNumber,
        updatedAt: DateTime.now(),
      );

      final savedUser = await AppUser.db.updateRow(session, updatedUser);

      session.log(
          '✅ updateClientProfile: Profil aktualisiert für ${savedUser.email}');
      return savedUser;
    } catch (e, stackTrace) {
      session.log('❌ updateClientProfile fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return null;
    }
  }

  /// **CLIENT: Register New User (Email-basiert)**
  ///
  /// Verknüpft Serverpod Email-Auth mit AppUser-Profil
  /// Wird NACH Email-Validierung aufgerufen
  Future<AppUser?> completeClientRegistration(
    Session session,
    String firstName,
    String lastName,
    String? parentEmail,
    DateTime? birthDate,
    String? gender,
    String? address,
    String? city,
    String? postalCode,
    String? phoneNumber,
  ) async {
    try {
      // 1. **Serverpod Auth prüfen (muss bereits angemeldet sein)**
      final authInfo = await session.authenticated;
      if (authInfo == null) {
        session.log('❌ completeClientRegistration: Nicht authentifiziert');
        return null;
      }

      // Email aus UserInfo laden
      final authUserInfo =
          await auth.UserInfo.db.findById(session, authInfo.userId);
      if (authUserInfo?.email == null) {
        session.log('❌ completeClientRegistration: Keine Email in UserInfo');
        return null;
      }
      final email = authUserInfo!.email!;

      // 2. **Prüfe ob bereits AppUser existiert**
      final existingUser = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(authInfo.userId),
      );

      if (existingUser != null) {
        session.log(
            '⚠️ completeClientRegistration: AppUser bereits vorhanden für ${email}');
        return existingUser;
      }

      // 3. **Erstelle neuen AppUser**
      final appUser = AppUser(
        userInfoId: authInfo.userId, // 🔗 Verknüpfung zu Serverpod Auth
        firstName: firstName,
        lastName: lastName,
        email: email,
        parentEmail: parentEmail,
        birthDate: birthDate,
        gender: gender,
        address: address,
        city: city,
        postalCode: postalCode,
        phoneNumber: phoneNumber,
        isEmailVerified:
            true, // ✅ Nach Serverpod createAccount ist Email verifiziert!
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedUser = await AppUser.db.insertRow(session, appUser);

      // 4. **Setze Client-Scope in UserInfo**
      final userInfo =
          await auth.UserInfo.db.findById(session, authInfo.userId);
      if (userInfo != null) {
        session.log(
            '🔧 SCOPE-DEBUG: Setze Client-Scope für UserInfo.id=${userInfo.id}, bisherige Scopes: ${userInfo.scopeNames}');

        final updatedUserInfo = userInfo.copyWith(scopeNames: ['client']);
        await auth.UserInfo.db.updateRow(session, updatedUserInfo);

        // Verifikation: Prüfe ob Scope korrekt gesetzt wurde
        final verifyUserInfo =
            await auth.UserInfo.db.findById(session, authInfo.userId);
        session.log(
            '🔍 SCOPE-VERIFY: Nach Update für UserInfo.id=${verifyUserInfo?.id}, Scopes: ${verifyUserInfo?.scopeNames}');
      } else {
        session.log(
            '❌ SCOPE-ERROR: Kein UserInfo gefunden für authInfo.userId=${authInfo.userId}');
      }

      session.log(
          '✅ completeClientRegistration: AppUser erstellt für ${email} (UserInfo.id=${authInfo.userId})');
      return savedUser;
    } catch (e, stackTrace) {
      session.log('❌ completeClientRegistration fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔧 UNIFIED HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// **Get All Staff Users (Admin-only)**
  ///
  /// Ersetzt staffUserTemp.getAllStaffUsers()
  /// Lädt alle Staff-User für Admin-Interface
  Future<List<StaffUser>> getAllStaffUsers(Session session) async {
    try {
      // 🔐 ADMIN PERMISSION CHECK
      final authUserId =
          await UnifiedAuthHelper.getAuthenticatedUserId(session);
      if (authUserId == null) {
        session.log('❌ getAllStaffUsers: Nicht authentifiziert');
        return [];
      }

      final hasPermission = await PermissionHelper.hasPermission(
          session, authUserId, 'can_view_staff_users');
      if (!hasPermission) {
        session.log('❌ getAllStaffUsers: Fehlende Berechtigung');
        return [];
      }

      // Lade alle aktiven Staff-User
      final staffUsers = await StaffUser.db.find(
        session,
        where: (t) => t.employmentStatus.equals('active'),
        orderBy: (t) => t.lastName,
      );

      session
          .log('✅ getAllStaffUsers: ${staffUsers.length} Staff-User geladen');
      return staffUsers;
    } catch (e, stackTrace) {
      session.log('❌ getAllStaffUsers fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return [];
    }
  }

  /// **Unified Authentication Info Helper**
  ///
  /// Ersetzt die komplizierte Hybrid-Authentication-Logic
  /// Gibt einheitliche User-Info basierend auf Serverpod Auth zurück
  Future<Map<String, dynamic>> getUnifiedAuthInfo(Session session) async {
    return await UnifiedAuthHelper.debugAuthStatus(session);
  }

  /// **Debug: Zeigt aktuelle Auth-Status**
  Future<Map<String, dynamic>> debugAuthStatus(Session session) async {
    return await UnifiedAuthHelper.debugAuthStatus(session);
  }

  /// **ADMIN: Erstelle Superuser für Testzwecke**
  ///
  /// Erstellt einen Superuser ohne Authentifizierung (nur für Setup)
  Future<Map<String, dynamic>> createSuperuser(Session session) async {
    try {
      session.log('🔧 Erstelle Superuser für Setup...');

      // Prüfe ob bereits ein Superuser existiert
      final existingSuperuser = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.employeeId.equals('superuser'),
      );

      if (existingSuperuser != null) {
        return {
          'success': false,
          'message': 'Superuser bereits vorhanden',
          'staffUser': existingSuperuser.toJson(),
        };
      }

      // Erstelle Superuser direkt (ohne Auth-Check für Setup)
      final result = await _createStaffUserDirect(
        session,
        'superuser', // username
        'super123', // password
        'Admin', // firstName
        'Superuser', // lastName
        'admin@vertic.local', // realEmail
        StaffUserType.superUser, // staffLevel
      );

      if (result['success'] == true) {
        session.log('✅ Superuser erfolgreich erstellt');

        // Weise alle Permissions zu (RBAC-System initialisieren)
        await _initializeRBACForSuperuser(session, result['staffUser']['id']);

        return {
          'success': true,
          'message': 'Superuser erstellt und RBAC initialisiert',
          'staffUser': result['staffUser'],
        };
      } else {
        return result;
      }
    } catch (e, stackTrace) {
      session.log('❌ Superuser-Erstellung fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return {
        'success': false,
        'message': 'Fehler beim Erstellen des Superusers: $e',
        'staffUser': null,
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔒 PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// **Production Password-Hash mit bcrypt**
  String _hashPassword(String password) {
    // 🔐 ECHTES BCRYPT HASHING - Production Ready!
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// **Password-Verifikation mit bcrypt**
  bool _verifyPassword(String password, String hash) {
    try {
      // 1. Echter bcrypt Hash - verwende BCrypt.checkpw()
      if (hash.startsWith('\$2b\$') || hash.startsWith('\$2a\$')) {
        return BCrypt.checkpw(password, hash);
      }

      // 2. Legacy Hash-Format (nur für Migration)
      if (hash.startsWith('hash_')) {
        return hash == 'hash_$password';
      }

      // 3. Unbekanntes Hash-Format
      return false;
    } catch (e) {
      // Bei jedem bcrypt Fehler: Login verweigern
      return false;
    }
  }

  /// **Staff-Token generieren**
  String _generateStaffToken(int staffUserId, int userInfoId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'staff_${staffUserId}_${userInfoId}_$timestamp';
  }

  /// **Staff-User direkt erstellen (ohne Auth-Check für Setup)**
  Future<Map<String, dynamic>> _createStaffUserDirect(
    Session session,
    String username,
    String password,
    String firstName,
    String lastName,
    String? realEmail,
    StaffUserType staffLevel,
  ) async {
    try {
      // 1. **Fake-Email für Serverpod generieren**
      final fakeEmail = username + staffDomain;

      // 2. **Prüfe ob Username bereits existiert**
      final existingStaff = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.employeeId.equals(username),
      );

      if (existingStaff != null) {
        return {
          'success': false,
          'message': 'Username bereits vergeben',
          'staffUser': null,
        };
      }

      // 3. **Erstelle UserInfo direkt in der Datenbank**
      final userInfo = auth.UserInfo(
        userIdentifier: fakeEmail, // Fake-Email als userIdentifier
        email: fakeEmail,
        userName: username,
        fullName: '$firstName $lastName',
        created: DateTime.now(),
        blocked: false,
        scopeNames: ['staff'], // Staff-Scope für Berechtigungsunterscheidung
      );

      final createdUserInfo =
          await auth.UserInfo.db.insertRow(session, userInfo);

      // 4. **Erstelle EmailAuth für Password**
      final emailAuth = auth.EmailAuth(
        userId: createdUserInfo.id!,
        email: fakeEmail,
        hash: _hashPassword(password),
      );

      await auth.EmailAuth.db.insertRow(session, emailAuth);

      // 5. **StaffUser in eigener Tabelle erstellen (ohne createdBy für Setup)**
      final staffUser = StaffUser(
        userInfoId: createdUserInfo.id!, // 🔗 Verknüpfung zu Serverpod Auth
        firstName: firstName,
        lastName: lastName,
        email: realEmail ?? fakeEmail, // Echte Email oder Fake-Email
        employeeId: username,
        staffLevel: staffLevel,
        employmentStatus: 'active',
        createdAt: DateTime.now(),
        // createdBy: null für Setup-User
      );

      final savedStaffUser = await StaffUser.db.insertRow(session, staffUser);

      session.log(
          '✅ Staff-User direkt erstellt: $username → UserInfo.id=${createdUserInfo.id}');

      return {
        'success': true,
        'message': 'Staff-User erfolgreich erstellt',
        'staffUser': savedStaffUser.toJson(),
      };
    } catch (e, stackTrace) {
      session.log('❌ Direkte Staff-User-Erstellung fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return {
        'success': false,
        'message': 'Fehler beim Erstellen: $e',
        'staffUser': null,
      };
    }
  }

  /// **RBAC-System für Superuser initialisieren**
  Future<void> _initializeRBACForSuperuser(
      Session session, int staffUserId) async {
    try {
      session.log('🔐 Initialisiere RBAC-System für Superuser...');

      // Importiere PermissionHelper für RBAC-Operationen
      final permissionHelper = PermissionHelper();

      // Hole alle verfügbaren Permissions
      final allPermissions = await Permission.db.find(session);
      session.log('📋 Gefundene Permissions: ${allPermissions.length}');

      if (allPermissions.isEmpty) {
        session.log(
            '⚠️ Keine Permissions gefunden - RBAC-System muss erst initialisiert werden');
        return;
      }

      // Weise alle Permissions dem Superuser zu
      int assignedCount = 0;
      for (final permission in allPermissions) {
        try {
          // Prüfe ob Permission bereits zugewiesen ist
          final existing = await StaffUserPermission.db.findFirstRow(
            session,
            where: (t) =>
                t.staffUserId.equals(staffUserId) &
                t.permissionId.equals(permission.id!),
          );

          if (existing == null) {
            // Permission zuweisen
            final assignment = StaffUserPermission(
              staffUserId: staffUserId,
              permissionId: permission.id!,
              grantedAt: DateTime.now(),
              grantedBy: staffUserId, // Self-granted für Superuser
            );

            await StaffUserPermission.db.insertRow(session, assignment);
            assignedCount++;
          }
        } catch (e) {
          session.log(
              '⚠️ Permission ${permission.name} konnte nicht zugewiesen werden: $e');
        }
      }

      session.log(
          '✅ RBAC-System initialisiert: $assignedCount Permissions zugewiesen');
    } catch (e, stackTrace) {
      session.log('❌ RBAC-Initialisierung fehlgeschlagen: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
    }
  }
}
