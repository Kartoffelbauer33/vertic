import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as auth;
import 'package:bcrypt/bcrypt.dart';
import '../generated/protocol.dart';
import '../helpers/permission_helper.dart';
import '../helpers/unified_auth_helper.dart';
import '../helpers/staff_auth_helper.dart';
import '../helpers/staff_email_helper.dart';

/// **Unified Authentication Endpoint**
///
/// Handles authentication for both Staff and Client applications using
/// Serverpod's native authentication system with EmailAuth.
class UnifiedAuthEndpoint extends Endpoint {

  // Staff Authentication Methods

  /// Store staff metadata for later linking with verified auth user
  Future<bool> storeStaffMetadata(
    Session session,
    CreateStaffUserWithEmailRequest request,
  ) async {
    try {
      session.log('Storing staff metadata for: ${request.email}');
      
      // Superuser-Passwort-Validierung falls erforderlich
      await _validateSuperuserPasswordIfNeeded(session, request);
      
      await _storeStaffMetadata(session, request, 0);
      session.log('Staff metadata stored for: ${request.email}');
      return true;
    } catch (e, stackTrace) {
      session.log('Error storing staff metadata: $e', level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// Link verified auth user to staff user
  Future<StaffUser> linkAuthUserToStaff(
    Session session,
    String email,
  ) async {
    try {
      session.log('Linking verified auth user to staff: $email');

      final emailAuth = await auth.EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );
      if (emailAuth == null) {
        throw Exception('Email address is not verified');
      }

      final metadata = await _getStaffMetadata(session, email);
      if (metadata == null) {
        throw Exception('Staff metadata not found for this email');
      }
      
      // Determine StaffLevel based on assigned roles
      var staffLevel = StaffUserType.values.firstWhere(
        (level) => level.name == (metadata['staffLevel'] as String?),
        orElse: () => StaffUserType.staff,
      );
      
      // Check if any superuser/admin role will be assigned
      final roleIds = (metadata['roleIds'] as List<dynamic>?)?.cast<int>();
      if (roleIds != null && roleIds.isNotEmpty) {
        final roles = await Role.db.find(
          session,
          where: (t) => t.id.inSet(roleIds.toSet()),
        );
        final hasSuperuserRole = roles.any((role) =>
          role.name.toLowerCase().contains('super') || 
          role.name.toLowerCase().contains('admin') ||
          role.isSystemRole
        );
        if (hasSuperuserRole) {
          staffLevel = StaffUserType.superUser;
        }
      }
      
      final staffUser = StaffUser(
        firstName: metadata['firstName'] as String? ?? 'Unbekannt',
        lastName: metadata['lastName'] as String? ?? 'Unbekannt', 
        email: email,
        passwordHash: '', // Managed by Serverpod Auth
        employeeId: metadata['employeeId'] as String?,
        staffLevel: staffLevel,
        phoneNumber: metadata['phoneNumber'] as String?,
        hallId: metadata['hallId'] as int?,
        facilityId: metadata['facilityId'] as int?,
        departmentId: metadata['departmentId'] as int?,
        contractType: metadata['contractType'] as String?,
        hourlyRate: metadata['hourlyRate'] as double?,
        monthlySalary: metadata['monthlySalary'] as double?,
        workingHours: metadata['workingHours'] as int?,
        employmentStatus: 'active',
        userInfoId: emailAuth.userId, // Link to Serverpod Auth UserInfo
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedStaffUser = await StaffUser.db.insertRow(session, staffUser);
      
      // 4. Assign roles if any were selected
      // roleIds already defined above for StaffLevel check
      session.log('Processing role assignments - roleIds: $roleIds');
      if (roleIds != null && roleIds.isNotEmpty) {
        session.log('Assigning ${roleIds.length} roles to staff user ${savedStaffUser.id}');
        for (final roleId in roleIds) {
          try {
            final roleAssignment = StaffUserRole(
              staffUserId: savedStaffUser.id!,
              roleId: roleId,
              assignedAt: DateTime.now(),
              assignedBy: savedStaffUser.id!, // Self-assigned during creation
              isActive: true,
              expiresAt: null,
              reason: 'Initial role assignment during staff creation',
            );
            await StaffUserRole.db.insertRow(session, roleAssignment);
            session.log('✅ Assigned role $roleId to staff user ${savedStaffUser.id}');
          } catch (e) {
            session.log('❌ Could not assign role $roleId: $e');
          }
        }
      } else {
        session.log('ℹ️ No roles to assign for staff user ${savedStaffUser.id}');
      }
      
      // 5. Cleanup metadata
      await _cleanupStaffMetadata(session, email);
      
      session.log('Staff user linked successfully with ${roleIds?.length ?? 0} roles: $email');
      return savedStaffUser;

    } catch (e, stackTrace) {
      session.log('❌ Error linking auth user to staff: $e', level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **STAFF: Create User with Email Verification (Legacy)**
  ///
  /// Old method - use storeStaffMetadata + EmailAuthController instead
  Future<bool> createStaffUserWithEmail(
    Session session,
    CreateStaffUserWithEmailRequest request,
  ) async {
    try {
      // 🔐 STAFF PERMISSION CHECK 
      final authUserId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      if (authUserId == null) {
        throw Exception('Authentifizierung erforderlich');
      }

      final hasPermission = await PermissionHelper.hasPermission(
          session, authUserId, 'can_create_staff_users');
      if (!hasPermission) {
        throw Exception('Fehlende Berechtigung: can_create_staff_users');
      }

      // 📋 **VALIDIERUNG**
      if (request.password.length < 8) {
        throw Exception('Passwort muss mindestens 8 Zeichen haben');
      }

      // 1. **E-Mail bereits existiert?**
      final existingEmailAuth = await auth.EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.email.equals(request.email),
      );
      if (existingEmailAuth != null) {
        throw Exception('E-Mail-Adresse bereits registriert');
      }

      // 2. **Standard Serverpod E-Mail-Verifizierung nutzen (wie Client-App)**
      final userName = '${request.firstName} ${request.lastName}';
      
      // ✅ Standard Serverpod createAccountRequest - genau wie Client-App!
      final success = await auth.Emails.createAccountRequest(
        session, 
        userName, 
        request.email, 
        request.password
      );
      
      if (!success) {
        throw Exception('E-Mail-Verifizierung konnte nicht gestartet werden');
      }

      // 3. **Staff-Metadaten temporär speichern für nach der Verifizierung**
      // Nutze eine einfache Map oder temporäre Tabelle
      await _storeStaffMetadata(session, request, authUserId);
      
      session.log('✅ Standard Serverpod E-Mail-Verifizierung gestartet für Staff: ${request.email}');
      
      return success;
    } catch (e, stackTrace) {
      session.log('❌ Staff-User-Erstellung fehlgeschlagen: $e', level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **Helper: Staff-Metadaten temporär speichern**
  Future<void> _storeStaffMetadata(
    Session session,
    CreateStaffUserWithEmailRequest request,
    int createdBy,
  ) async {
    // Store metadata as JSON in token field
    final metadataJson = {
      'firstName': request.firstName,
      'lastName': request.lastName,
      'employeeId': request.employeeId,
      'staffLevel': request.staffLevel.name,
      'phoneNumber': request.phoneNumber,
      'hallId': request.hallId,
      'facilityId': request.facilityId,
      'departmentId': request.departmentId,
      'contractType': request.contractType,
      'hourlyRate': request.hourlyRate,
      'monthlySalary': request.monthlySalary,
      'workingHours': request.workingHours,
      'roleIds': request.roleIds,
      'createdBy': createdBy,
    };
    
    final metadata = StaffVerificationToken(
      staffUserId: 0,
      email: request.email,
      token: jsonEncode(metadataJson), // JSON-encoded metadata
      tokenType: 'staff_metadata',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      isUsed: false,
      createdAt: DateTime.now(),
    );
    
    await StaffVerificationToken.db.insertRow(session, metadata);
    
    session.log('Staff metadata stored for: ${request.email}');
    session.log('  - firstName: ${request.firstName}');
    session.log('  - lastName: ${request.lastName}');
    session.log('  - roleIds: ${request.roleIds}');
    session.log('  - JSON: ${metadata.token}');
  }

  /// **Helper: Staff-Metadaten abrufen**
  Future<Map<String, dynamic>?> _getStaffMetadata(
    Session session,
    String email,
  ) async {
    try {
      // Find metadata token by email and type only (token now contains JSON)
      final metadata = await StaffVerificationToken.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email) & 
                     t.tokenType.equals('staff_metadata') &
                     t.isUsed.equals(false),
      );
      
      if (metadata == null) {
        session.log('No staff metadata found for: $email');
        return null;
      }
      
      // Decode JSON metadata
      try {
        final jsonData = jsonDecode(metadata.token);
        session.log('Staff metadata retrieved for: $email');
        session.log('  - Raw JSON: ${metadata.token}');
        session.log('  - firstName: ${jsonData['firstName']}');
        session.log('  - lastName: ${jsonData['lastName']}');
        session.log('  - roleIds: ${jsonData['roleIds']} (type: ${jsonData['roleIds'].runtimeType})');
        
        // Mark metadata as used
        await StaffVerificationToken.db.updateRow(
          session,
          metadata.copyWith(isUsed: true),
        );
        
        return jsonData as Map<String, dynamic>;
      } catch (e) {
        session.log('Failed to decode staff metadata JSON: $e');
        return null;
      }
    } catch (e) {
      session.log('Error retrieving staff metadata: $e');
      return null;
    }
  }

  /// **Helper: Staff-Metadaten bereinigen**
  Future<void> _cleanupStaffMetadata(Session session, String email) async {
    try {
      await StaffVerificationToken.db.deleteWhere(
        session,
        where: (t) => t.email.equals(email) & 
                     t.tokenType.equals('staff_metadata'),
      );
      session.log('🧹 Staff-Metadaten bereinigt für: $email');
    } catch (e) {
      session.log('⚠️ Fehler beim Bereinigen der Staff-Metadaten: $e');
    }
  }

  /// **Helper: Superuser-Passwort-Validierung**
  Future<void> _validateSuperuserPasswordIfNeeded(
    Session session,
    CreateStaffUserWithEmailRequest request,
  ) async {
    // Prüfe ob Superuser-Rollen zugewiesen werden sollen
    if (request.roleIds == null || request.roleIds!.isEmpty) {
      return; // Keine Rollen = keine Validierung nötig
    }

    // Lade die angeforderten Rollen
    final requestedRoles = await Role.db.find(
      session,
      where: (t) => t.id.inSet(request.roleIds!.toSet()),
    );

    // Prüfe ob eine Superuser-Rolle dabei ist
    final hasSuperuserRole = requestedRoles.any((role) =>
        role.name.toLowerCase().contains('super') || 
        role.name.toLowerCase().contains('admin') ||
        role.isSystemRole);

    if (!hasSuperuserRole) {
      return; // Keine Superuser-Rolle = keine Validierung nötig
    }

    // Superuser-Rolle erkannt - Passwort-Validierung erforderlich
    if (request.superuserPasswordConfirmation == null || 
        request.superuserPasswordConfirmation!.isEmpty) {
      throw Exception('Für die Zuweisung von Superuser-Rollen ist das aktuelle Superuser-Passwort erforderlich');
    }

    // Hole den aktuellen Staff-User (muss Superuser sein)
    final currentStaffUserId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (currentStaffUserId == null) {
      throw Exception('Keine gültige Staff-Authentifizierung gefunden');
    }

    final currentStaffUser = await StaffUser.db.findById(session, currentStaffUserId);
    if (currentStaffUser == null || currentStaffUser.staffLevel != StaffUserType.superUser) {
      throw Exception('Nur Superuser können neue Superuser erstellen');
    }

    // Validiere das eingegebene Passwort gegen das Superuser-Konto
    final superuserEmailAuth = await auth.EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(currentStaffUser.userInfoId!),
    );

    if (superuserEmailAuth == null) {
      throw Exception('Superuser-Authentifizierung nicht gefunden');
    }

    if (!_verifyPassword(request.superuserPasswordConfirmation!, superuserEmailAuth.hash)) {
      throw Exception('Ungültiges Superuser-Passwort');
    }

    session.log('✅ Superuser-Passwort erfolgreich validiert für neue Superuser-Erstellung');
  }

  /// **TEMPORÄRE METHODE - bis Modelle generiert sind**
  Future<bool> createStaffUserWithEmailTemp(
    Session session,
    String firstName,
    String lastName,
    String email,
    String password,
    String employeeId,
    StaffUserType staffLevel,
    String? phoneNumber,
    int? hallId,
    int? facilityId,
    int? departmentId,
    String? contractType,
    double? hourlyRate,
    double? monthlySalary,
    int? workingHours,
    List<int>? roleIds,
    String? superuserPasswordConfirmation,
  ) async {
    final request = CreateStaffUserWithEmailRequest(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      employeeId: employeeId.isEmpty ? null : employeeId,
      phoneNumber: phoneNumber,
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
    
    return await createStaffUserWithEmail(session, request);
  }

  /// **TEMPORÄRE METHODE - bis Modelle generiert sind**
  Future<StaffUser> verifyStaffUserEmailTemp(
    Session session,
    String email,
    String verificationCode,
  ) async {
    final request = VerifyStaffUserEmailRequest(
      email: email,
      verificationCode: verificationCode,
    );
    
    return await verifyStaffUserEmail(session, request);
  }

  /// **STAFF: Verify Email for Staff User (Standard Serverpod)**
  ///
  /// Bestätigt E-Mail mit Standard Serverpod und erstellt Staff-User
  Future<StaffUser> verifyStaffUserEmail(
    Session session,
    VerifyStaffUserEmailRequest request,
  ) async {
    try {
      // 1. **Standard Serverpod E-Mail-Validierung (wie Client-App)**
      // NOTE: This method is deprecated - use EmailAuthController.validateAccount() + linkAuthUserToStaff() instead
      throw Exception('This method is deprecated. Use EmailAuthController.validateAccount() on frontend + linkAuthUserToStaff() instead.');
    } catch (e, stackTrace) {
      session.log('❌ E-Mail-Bestätigung fehlgeschlagen: $e', level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
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

  /// **STAFF: Login with Email or Username - Simple method for frontend**
  ///
  /// Wrapper method for staffSignInFlexible - simplifies frontend integration
  Future<StaffLoginResponse> staffLogin(
    Session session,
    String emailOrUsername,
    String password,
  ) async {
    try {
      final result = await staffSignInFlexible(session, emailOrUsername, password);
      
      return StaffLoginResponse(
        success: result.success,
        message: result.message,
        staffUser: result.staffUser,
        staffToken: result.staffToken,
      );
    } catch (e, stackTrace) {
      session.log('❌ staffLogin fehlgeschlagen: $e', level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      
      return StaffLoginResponse(
        success: false,
        message: 'Login fehlgeschlagen: $e',
        staffUser: null,
        staffToken: null,
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

      // 🚫 CRITICAL FIX: Prüfe auch ob bereits AppUser mit dieser E-Mail existiert
      // (verhindert doppelte User durch Race Conditions)
      final existingEmailUser = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );

      if (existingEmailUser != null) {
        session.log(
            '❌ DUPLICATE EMAIL PREVENTED: AppUser mit E-Mail ${email} existiert bereits (ID: ${existingEmailUser.id})');

        // Verknüpfe den bestehenden User mit der aktuellen userInfoId wenn noch nicht gesetzt
        if (existingEmailUser.userInfoId == null) {
          final updatedUser = existingEmailUser.copyWith(
            userInfoId: authInfo.userId,
            updatedAt: DateTime.now(),
          );
          final savedUser = await AppUser.db.updateRow(session, updatedUser);
          session.log(
              '🔧 MIGRATION: Bestehender AppUser (ID: ${existingEmailUser.id}) mit UserInfo.id=${authInfo.userId} verknüpft');
          return savedUser;
        } else {
          session.log(
              '⚠️ E-Mail-Konflikt: AppUser ${existingEmailUser.id} bereits mit UserInfo.id=${existingEmailUser.userInfoId} verknüpft');
          return existingEmailUser;
        }
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
  
  /// **Debug: Test Superuser Password**
  Future<Map<String, dynamic>> debugSuperuserPassword(Session session) async {
    try {
      // Finde den Superuser
      final staffUser = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.employeeId.equals('superuser'),
      );
      
      if (staffUser == null) {
        return {'error': 'Superuser nicht gefunden'};
      }
      
      // Finde die Email-Auth
      final emailAuth = await auth.EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(staffUser.userInfoId!),
      );
      
      if (emailAuth == null) {
        return {'error': 'EmailAuth für Superuser nicht gefunden'};
      }
      
      // Teste verschiedene Passwörter
      final testPasswords = ['super123', 'vertic123', 'temp123'];
      final results = <String, bool>{};
      
      for (final testPw in testPasswords) {
        results[testPw] = _verifyPassword(testPw, emailAuth.hash);
      }
      
      return {
        'staffUser': {
          'id': staffUser.id,
          'email': staffUser.email,
          'employeeId': staffUser.employeeId,
          'userInfoId': staffUser.userInfoId,
        },
        'emailAuth': {
          'userId': emailAuth.userId,
          'email': emailAuth.email,
          'hashStart': emailAuth.hash.substring(0, 20) + '...',
        },
        'passwordTests': results,
        'correctPassword': results.entries.where((e) => e.value).map((e) => e.key).firstOrNull ?? 'UNKNOWN',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// **DEBUG: Set Superuser Password direkt**
  Future<Map<String, dynamic>> setSuperuserPassword(
    Session session,
    String newPassword,
  ) async {
    try {
      // Finde den Superuser
      final staffUser = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.employeeId.equals('superuser'),
      );
      
      if (staffUser == null) {
        return {'error': 'Superuser nicht gefunden'};
      }
      
      if (staffUser.userInfoId == null) {
        return {'error': 'Superuser hat keine userInfoId'};
      }
      
      // Hash das neue Passwort
      final newHash = _hashPassword(newPassword);
      
      // Update oder erstelle EmailAuth
      final existingAuth = await auth.EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(staffUser.userInfoId!),
      );
      
      if (existingAuth != null) {
        // Update existierenden Eintrag
        await auth.EmailAuth.db.updateRow(
          session,
          existingAuth.copyWith(hash: newHash),
        );
      } else {
        // Erstelle neuen Eintrag
        final newAuth = auth.EmailAuth(
          userId: staffUser.userInfoId!,
          email: staffUser.email,
          hash: newHash,
        );
        await auth.EmailAuth.db.insertRow(session, newAuth);
      }
      
      // Verifiziere das neue Passwort
      final verification = _verifyPassword(newPassword, newHash);
      
      return {
        'success': true,
        'message': 'Passwort gesetzt auf: $newPassword',
        'staffUser': {
          'id': staffUser.id,
          'email': staffUser.email,
          'employeeId': staffUser.employeeId,
        },
        'passwordVerification': verification,
        'newHashStart': newHash.substring(0, 20) + '...',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
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

      // Erstelle Superuser mit echter Email-Auth
      const superuserEmail = 'admin@vertic.local';
      const superuserPassword = 'super123';

      // 1. Create Serverpod UserInfo with real email
      final userInfo = auth.UserInfo(
        userIdentifier: superuserEmail,
        email: superuserEmail,
        userName: 'superuser',
        fullName: 'Admin Superuser',
        created: DateTime.now(),
        blocked: false,
        scopeNames: ['staff'],
      );

      final createdUserInfo = await auth.UserInfo.db.insertRow(session, userInfo);

      // 2. Create EmailAuth with real email
      final emailAuth = auth.EmailAuth(
        userId: createdUserInfo.id!,
        email: superuserEmail,
        hash: _hashPassword(superuserPassword),
      );

      await auth.EmailAuth.db.insertRow(session, emailAuth);

      // 3. Create StaffUser record
      final staffUser = StaffUser(
        userInfoId: createdUserInfo.id!,
        firstName: 'Admin',
        lastName: 'Superuser',
        email: superuserEmail,
        employeeId: 'superuser',
        staffLevel: StaffUserType.staff, // Default - Berechtigung über Rollen
        employmentStatus: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedStaffUser = await StaffUser.db.insertRow(session, staffUser);
      
      session.log('Superuser created with real email auth: $superuserEmail');

      // Initialize RBAC system
      await _initializeRBACForSuperuser(session, savedStaffUser.id!);

      return {
        'success': true,
        'message': 'Superuser created with real email authentication',
        'staffUser': savedStaffUser.toJson(),
      };
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


  /// **RBAC-System für Superuser initialisieren**
  Future<void> _initializeRBACForSuperuser(
      Session session, int staffUserId) async {
    try {
      session.log('🔐 Initialisiere RBAC-System für Superuser...');

      // RBAC-Operationen werden durchgeführt

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

  // ═══════════════════════════════════════════════════════════════
  // 📧 E-MAIL VERIFICATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// **Generiert sicheren Verification Code**
  Future<String> _generateVerificationCode() async {
    // 6-stelliger numerischer Code für einfache Eingabe
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// **Sendet Staff E-Mail-Verifizierung**
  Future<bool> _sendStaffVerificationEmail(
    Session session,
    String email,
    String fullName,
    String verificationCode,
  ) async {
    try {
      // Verwende StaffEmailHelper für konsistente E-Mail-Versendung
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      return await StaffEmailHelper.sendStaffVerificationEmail(
        session,
        email,
        firstName,
        lastName,
        verificationCode,
      );
    } catch (e) {
      session.log('❌ E-Mail-Versand fehlgeschlagen: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Resend Staff Verification Email**
  Future<UnifiedAuthResponse> resendStaffVerificationEmail(
    Session session,
    String email,
  ) async {
    try {
      // 1. Finde Staff-User mit pending_verification Status
      final staffUser = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email) & 
                     t.employmentStatus.equals('pending_verification'),
      );

      if (staffUser == null) {
        return UnifiedAuthResponse(
          success: false,
          message: 'Kein ausstehender Verifizierungsprozess für diese E-Mail gefunden',
          staffUser: null,
        );
      }

      // 2. Alten Token invalidieren
      await StaffVerificationToken.db.deleteWhere(
        session,
        where: (t) => t.staffUserId.equals(staffUser.id!) & 
                     t.tokenType.equals('email_verification') &
                     t.isUsed.equals(false),
      );

      // 3. Neuen Token erstellen
      final verificationCode = await _generateVerificationCode();
      final tokenExpiresAt = DateTime.now().add(const Duration(hours: 24));
      
      final verificationToken = StaffVerificationToken(
        staffUserId: staffUser.id!,
        email: email,
        token: verificationCode,
        tokenType: 'email_verification',
        expiresAt: tokenExpiresAt,
        isUsed: false,
        createdAt: DateTime.now(),
      );
      
      await StaffVerificationToken.db.insertRow(session, verificationToken);

      // 4. E-Mail erneut senden
      final emailSent = await _sendStaffVerificationEmail(
        session, 
        email, 
        '${staffUser.firstName} ${staffUser.lastName}',
        verificationCode,
      );

      return UnifiedAuthResponse(
        success: emailSent,
        message: emailSent 
          ? 'Bestätigungscode erneut gesendet'
          : 'E-Mail-Versand fehlgeschlagen',
        staffUser: staffUser,
        verificationCode: verificationCode,
      );
    } catch (e) {
      session.log('❌ resendStaffVerificationEmail Error: $e', level: LogLevel.error);
      return UnifiedAuthResponse(
        success: false,
        message: 'Fehler beim erneuten Senden: $e',
        staffUser: null,
      );
    }
  }
}
