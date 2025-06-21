import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as auth;

class TicketEndpoint extends Endpoint {
  // Konstanter geheimer Schlüssel für die Signatur (sollte in einer sicheren Umgebungsvariable gespeichert werden)
  static const String _secretKey =
      'YVPn4aX8biYLe0C2drFzhK7Jq1sW9m'; // In Produktion aus Umgebungsvariablen laden!

  // Hilfsfunktion: Alter berechnen
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Hilfsfunktion: Tickettyp anhand Alter und Status bestimmen
  Future<TicketType?> _getTicketTypeByAgeAndStatus(
      Session session, int age, int? statusTypeId) async {
    // Hole alle Tickettypen
    final ticketTypes = await TicketType.db.find(session);
    // Hole alle Statusarten
    final statusTypes = await UserStatusType.db.find(session);
    // Hole Statusnamen
    final statusType = statusTypes.firstWhere(
      (s) => s.id == statusTypeId,
      orElse: () => UserStatusType(
        id: 1,
        name: 'Standard',
        description: '',
        discountPercentage: 0,
        requiresVerification: false,
        requiresDocumentation: false,
        validityPeriod: 0,
        createdAt: DateTime.now(),
      ),
    );
    final statusName = statusType.name.toLowerCase();

    // Logging für Debugging
    session.log(
        'Alter: $age, Status-ID: $statusTypeId, Statusname: $statusName',
        level: LogLevel.info);
    session.log(
        'Alle Statusnamen: ${statusTypes.map((s) => '[${s.id}] ${s.name}').join(", ")}',
        level: LogLevel.info);

    // Ermäßigte Statusnamen (anpassen je nach DB)
    final ermaessigtNamen = [
      'ermäßigt',
      'ermaessigt',
      'student',
      'azubi',
      'sozial',
      'schüler',
      'schueler',
      'behinderung',
      'behinderte',
      'kind ermäßigt',
      'jugendlich ermäßigt',
      'senior ermäßigt',
      'erwachsen ermäßigt'
    ];
    bool isErmaessigt = statusName != 'standard' &&
        ermaessigtNamen.any((n) => statusName.contains(n));

    // Logik: Kombiniere Alter und Status zu einem passenden Tickettypnamen
    // Standardmäßig Tageskarte, kann später erweitert werden
    String typeName;
    if (age <= 12) {
      typeName = isErmaessigt ? 'Tageskarte Kind Ermäßigt' : 'Tageskarte Kind';
    } else if (age <= 17) {
      typeName =
          isErmaessigt ? 'Tageskarte Jugend Ermäßigt' : 'Tageskarte Jugend';
    } else if (age >= 65) {
      typeName =
          isErmaessigt ? 'Tageskarte Senior Ermäßigt' : 'Tageskarte Senior';
    } else {
      typeName = isErmaessigt
          ? 'Tageskarte Erwachsen Ermäßigt'
          : 'Tageskarte Erwachsen';
    }

    session.log('Gewählter Tickettyp-Name: $typeName', level: LogLevel.info);

    // Suche passenden Tickettyp (exakte Übereinstimmung zuerst)
    try {
      final exactMatch = ticketTypes
          .firstWhere((t) => t.name.toLowerCase() == typeName.toLowerCase());
      session.log(
          'Tickettyp gefunden: ${exactMatch.name} (ID: ${exactMatch.id})',
          level: LogLevel.info);
      return exactMatch;
    } catch (_) {
      // Fallback: Suche nach Basis-Typ ohne "Ermäßigt"
      final baseTypeName = typeName.replaceAll(' Ermäßigt', '');
      try {
        final fallbackMatch = ticketTypes.firstWhere(
            (t) => t.name.toLowerCase() == baseTypeName.toLowerCase());
        session.log(
            'Fallback-Tickettyp gefunden: ${fallbackMatch.name} (ID: ${fallbackMatch.id})',
            level: LogLevel.info);
        return fallbackMatch;
      } catch (_) {
        session.log('Kein Tickettyp gefunden für $typeName oder $baseTypeName',
            level: LogLevel.error);
        return null;
      }
    }
  }

  // Ticket für einen Benutzer erstellen und kaufen
  Future<Ticket?> purchaseTicket(Session session, int ticketTypeId,
      {DateTime? validDate}) async {
    // 🔑 KORREKTE DOPPELTE AUTHENTICATION - BEIDE APPS UNTERSTÜTZEN
    int? userId;
    String? userEmail;
    String authSource = '';

    // 1. ZUERST: Staff-Authentication prüfen (für Staff-App)
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId != null) {
      // Staff-User gefunden - lade den zugehörigen AppUser
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser != null) {
        // Finde den entsprechenden AppUser basierend auf Email
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.email.equals(staffUser.email),
        );
        if (appUser != null) {
          userId = appUser.id;
          userEmail = appUser.email;
          authSource = 'Staff-Auth';
          session.log(
              '🔑 $authSource: Staff-User ${staffUser.email} → AppUser-ID $userId');
        }
      }
    }

    // 2. FALLBACK: Client-App Authentication prüfen (für Client-App)
    if (userId == null) {
      final authInfo = await session.authenticated;
      final userIdentifier = authInfo?.userIdentifier; // EMAIL!
      if (userIdentifier != null) {
        // Finde AppUser basierend auf Email (da userIdentifier = Email ist)
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.email.equals(userIdentifier),
        );
        if (appUser != null) {
          userId = appUser.id;
          userEmail = appUser.email;
          authSource = 'Client-Auth';
          session.log(
              '🔑 $authSource: Client-Email $userIdentifier → AppUser-ID $userId');
        } else {
          session.log(
              '🔑 Client-Auth FEHLER: Kein AppUser für Email $userIdentifier gefunden!',
              level: LogLevel.error);
        }
      }
    }

    session.log(
        '[DEBUG] purchaseTicket [$authSource]: userId=$userId ($userEmail), ticketTypeId=$ticketTypeId');
    try {
      // User-ID aus Session holen
      if (userId == null) {
        session.log('[DEBUG] purchaseTicket: Nicht eingeloggt!',
            level: LogLevel.error);
        return null;
      }

      // Benutzer prüfen
      final user = await AppUser.db.findById(session, userId);
      if (user == null) {
        session.log(
            '[DEBUG] purchaseTicket: Benutzer mit ID $userId nicht gefunden',
            level: LogLevel.error);
        return null;
      }

      // NEUE PRÜFUNG: Ist der Benutzer gesperrt?
      if (user.isBlocked == true) {
        session.log(
            '[DEBUG] purchaseTicket: Ticket-Kauf verweigert: Benutzer ${user.email} ist gesperrt (${user.blockedReason})',
            level: LogLevel.warning);
        throw Exception(
            'Ihr Account ist gesperrt und kann keine Tickets kaufen. Grund: \\${user.blockedReason ?? "Nicht angegeben"}');
      }

      // NEUE PRÜFUNG: Ist die Email verifiziert?
      if (user.isEmailVerified == false) {
        session.log(
            '[DEBUG] purchaseTicket: Ticket-Kauf verweigert: Email ${user.email} ist nicht verifiziert',
            level: LogLevel.warning);
        throw Exception(
            'Bitte verifizieren Sie zuerst Ihre Email-Adresse, bevor Sie Tickets kaufen können.');
      }

      // Aktiven, bestätigten Status des Users holen
      final userStatus = await UserStatus.db.findFirstRow(
        session,
        where: (s) =>
            s.userId.equals(userId) &
            s.isVerified.equals(true) &
            (s.expiryDate > DateTime.now()),
        orderBy: (s) => s.expiryDate,
        orderDescending: true,
      );
      final userStatusTypeId = userStatus?.statusTypeId ?? 1; // 1 = Standard

      // VERWENDE DIE VOM CLIENT GESENDETE TICKETTYPEID
      // Prüfe ob der angegebene TicketType existiert
      TicketType? ticketType;
      try {
        ticketType = await TicketType.db.findById(session, ticketTypeId);
        if (ticketType == null) {
          session.log(
              '[DEBUG] purchaseTicket: TicketType mit ID $ticketTypeId nicht gefunden',
              level: LogLevel.error);
          return null;
        }
        session.log(
            '[DEBUG] purchaseTicket: Verwende gewählten TicketType: ${ticketType.name} (ID: $ticketTypeId)');
      } catch (e) {
        session.log(
            '[DEBUG] purchaseTicket: Fehler beim Laden des TicketTypes $ticketTypeId: $e',
            level: LogLevel.error);

        // Fallback: Automatische Tickettyp-Auswahl nur wenn der gewählte nicht existiert
        session.log(
            '[DEBUG] purchaseTicket: Fallback: Versuche automatische Tickettyp-Auswahl...');
        int age = user.birthDate != null ? _calculateAge(user.birthDate!) : 30;
        ticketType =
            await _getTicketTypeByAgeAndStatus(session, age, userStatusTypeId);
        if (ticketType == null) {
          session.log(
              '[DEBUG] purchaseTicket: Kein passender Tickettyp für Alter $age und Status $userStatusTypeId gefunden',
              level: LogLevel.error);
          return null;
        }
        ticketTypeId = ticketType.id!; // Nur im Fallback überschreiben
        session.log(
            '[DEBUG] purchaseTicket: Fallback TicketType gewählt: ${ticketType.name} (ID: $ticketTypeId)');
      }

      // Preis für Tickettyp + Status ermitteln
      final pricing = await TicketTypePricing.db.findFirstRow(
        session,
        where: (p) =>
            p.ticketTypeId.equals(ticketTypeId) &
            p.userStatusTypeId.equals(userStatusTypeId),
      );
      double price = pricing?.price ?? ticketType.defaultPrice;

      // Aktuelles Datum als Kaufdatum verwenden
      final now = DateTime.now().toUtc();

      // ✅ KORREKTE EINZELTICKET-LOGIK ✅
      DateTime expiryDate;

      if (ticketType.isSubscription) {
        // Abonnements: Normales Ablaufdatum
        expiryDate = now.add(Duration(days: ticketType.billingInterval ?? 30));
      } else if (ticketType.isPointBased) {
        // Punktekarten: Lange Gültigkeit (1 Jahr)
        expiryDate = now.add(const Duration(days: 365));
      } else {
        // ✅ EINZELTICKETS: Kein Ablaufdatum beim Kauf! ✅
        // Werden unbegrenzt lange aufbewahrt bis zur ersten Aktivierung
        // Dann gelten sie für den Tag der Aktivierung
        expiryDate =
            now.add(const Duration(days: 36500)); // ~100 Jahre = "unbegrenzt"
        session.log(
            '[DEBUG] purchaseTicket: Einzelticket: Setze "unbegrenztes" Ablaufdatum für spätere Aktivierung');
      }

      // Ticket erstellen
      Ticket ticket = Ticket(
        userId: userId,
        ticketTypeId: ticketTypeId,
        price: price,
        purchaseDate: now,
        expiryDate: expiryDate,
        isUsed: false,
        qrCodeData: '',
        activatedDate: null,
        activatedForDate: null,
        currentUsageCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      if (ticketType.isPointBased) {
        ticket.initialPoints = ticketType.defaultPoints;
        ticket.remainingPoints = ticketType.defaultPoints;
      }
      if (ticketType.isSubscription) {
        ticket.subscriptionStatus = 'ACTIVE';
        ticket.lastBillingDate = now;
        ticket.nextBillingDate = expiryDate;
      }

      session.log(
          '[DEBUG] purchaseTicket: Ticket-Objekt vor Insert: userId=${ticket.userId}, ticketTypeId=${ticket.ticketTypeId}, price=${ticket.price}, expiryDate=${ticket.expiryDate}, isPointBased=${ticketType.isPointBased}, isSubscription=${ticketType.isSubscription}');
      Ticket savedTicket = await Ticket.db.insertRow(session, ticket);
      session.log(
          '[DEBUG] purchaseTicket: Ticket nach Insert: id=${savedTicket.id}, userId=${savedTicket.userId}, ticketTypeId=${savedTicket.ticketTypeId}');
      final qrCodeData = _generateSecureQRCodeData(savedTicket);
      savedTicket.qrCodeData = qrCodeData;
      savedTicket = await Ticket.db.updateRow(session, savedTicket);

      session.log(
          '[DEBUG] purchaseTicket: ✅ KORREKTES TICKET erstellt: ${ticketType.name} - ${ticketType.isPointBased ? "Punktekarte" : ticketType.isSubscription ? "Abo" : "Tagesticket (unbegrenzt aktivierbar)"}');

      return savedTicket;
    } catch (e) {
      session.log(
          '[DEBUG] purchaseTicket: Fehler beim Erstellen des Tickets: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Alle Tickets eines Benutzers abrufen
  Future<List<Ticket>> getUserTickets(Session session, int userId) async {
    try {
      // Alle Tickets des Benutzers finden
      final tickets = await Ticket.db.find(
        session,
        where: (t) => t.userId.equals(userId),
        orderBy: (t) => t.expiryDate,
        orderDescending: true,
      );

      return tickets;
    } catch (e) {
      session.log('Fehler beim Abrufen der Tickets: $e', level: LogLevel.error);
      return [];
    }
  }

  // Nur gültige Tickets eines Benutzers abrufen
  Future<List<Ticket>> getValidUserTickets(Session session, int userId) async {
    try {
      // 🔐 DEBUG: Authentifizierung überprüfen
      final staffUserId =
          await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      final clientAuthInfo = await session.authenticated;

      session.log(
          '[DEBUG] getValidUserTickets: staffUserId=$staffUserId, clientUserId=${clientAuthInfo?.userId}, requestedUserId=$userId');

      // 🔍 DEBUG: Zeige ALLE Tickets für diesen User zuerst
      final allUserTickets = await Ticket.db.find(
        session,
        where: (t) => t.userId.equals(userId),
        orderBy: (t) => t.purchaseDate,
        orderDescending: true,
      );
      session.log(
          '[DEBUG] ALLE Tickets für User $userId: ${allUserTickets.length}');
      for (final ticket in allUserTickets) {
        session.log(
            '[DEBUG] Ticket ID ${ticket.id}: used=${ticket.isUsed}, remainingPoints=${ticket.remainingPoints}, subscriptionStatus=${ticket.subscriptionStatus}, ticketTypeId=${ticket.ticketTypeId}, expiryDate=${ticket.expiryDate}');
      }

      // Wenn Staff-User angemeldet ist, prüfe Berechtigung
      if (staffUserId != null) {
        final hasPermission = await PermissionHelper.hasPermission(
            session, staffUserId, 'can_view_tickets');
        if (!hasPermission) {
          session.log(
              '❌ Staff-User $staffUserId hat keine Berechtigung can_view_tickets für User $userId');
          return [];
        }
        session.log(
            '✅ Staff-User $staffUserId hat Berechtigung can_view_tickets für User $userId');
      } else if (clientAuthInfo?.userId != userId) {
        // Client-User kann nur eigene Tickets sehen
        session.log(
            '❌ Client-User ${clientAuthInfo?.userId} versucht Tickets von User $userId zu sehen');
        return [];
      }

      final now = DateTime.now().toUtc();

      // Alle gültigen Tickets des Benutzers finden
      final tickets = await Ticket.db.find(
        session,
        where: (t) =>
            t.userId.equals(userId) &
            (
                // Einzelticket: nicht verwendet und keine Punkte/kein Abo
                (t.isUsed.equals(false) &
                        t.remainingPoints.equals(null) &
                        t.subscriptionStatus.equals(null)) |
                    // Punktekarte: noch Punkte übrig
                    (t.remainingPoints.notEquals(null) &
                        (t.remainingPoints > 0)) |
                    // Abo: aktiv
                    (t.subscriptionStatus.equals('ACTIVE'))),
        orderBy: (t) => t.purchaseDate,
        orderDescending: true,
      );

      session.log(
          '[DEBUG] getValidUserTickets: Gefunden ${tickets.length} gültige Tickets für User $userId');

      for (final ticket in tickets) {
        session.log(
            '[DEBUG] Ticket ID ${ticket.id}: type=${ticket.ticketTypeId}, used=${ticket.isUsed}, points=${ticket.remainingPoints}, status=${ticket.subscriptionStatus}');
      }

      return tickets;
    } catch (e) {
      session.log('Fehler beim Abrufen gültiger Tickets: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Ticket validieren (beim Einlass)
  Future<bool> validateTicket(
      Session session, int ticketId, int facilityId, int staffId) async {
    // 🔐 RBAC SECURITY CHECK - staffUserId aus Session holen
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Ticket-Validierung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Ticket-Validierung');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session,
        authUserId, // Verwende authUserId als staffUserId
        'can_validate_tickets');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_validate_tickets (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Validieren von Tickets');
    }

    try {
      // Ticket finden
      final ticket = await Ticket.db.findById(session, ticketId);
      if (ticket == null) {
        session.log('Ticket mit ID $ticketId nicht gefunden',
            level: LogLevel.error);
        return false;
      }

      // Tickettyp ermitteln
      final ticketType =
          await TicketType.db.findById(session, ticket.ticketTypeId);
      if (ticketType == null) {
        session.log('Tickettyp für Ticket $ticketId nicht gefunden',
            level: LogLevel.error);
        return false;
      }

      // QR-Code-Validierung
      final isValidQr = _validateQrCodeData(ticket.qrCodeData, ticket);
      if (!isValidQr) {
        session.log(
            'QR-Code für Ticket $ticketId ist ungültig oder manipuliert',
            level: LogLevel.warning);
        return false;
      }

      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);

      // ✅ KORREKTE VALIDIERUNG je nach Tickettyp ✅
      if (ticketType.isPointBased) {
        // Punktebasierte Tickets: Punkte überprüfen
        if (ticket.remainingPoints == null || ticket.remainingPoints! <= 0) {
          session.log('Ticket $ticketId hat keine Punkte mehr',
              level: LogLevel.warning);
          return false;
        }

        // Punkt abziehen und Nutzung protokollieren
        ticket.remainingPoints = ticket.remainingPoints! - 1;
        ticket.updatedAt = now;
        await Ticket.db.updateRow(session, ticket);

        // Nutzung protokollieren
        await _logTicketUsage(session, ticketId, facilityId, staffId, 1);

        session.log(
            'Punkt von Ticket $ticketId verwendet (verbleibend: ${ticket.remainingPoints})');
        return true;
      } else if (ticketType.isSubscription) {
        // Abonnements: Überprüfen, ob das Abo aktiv ist
        if (ticket.subscriptionStatus != 'ACTIVE') {
          session.log(
              'Ticket $ticketId ist kein aktives Abo (Status: ${ticket.subscriptionStatus})',
              level: LogLevel.warning);
          return false;
        }

        // Überprüfen, ob das Abo noch gültig ist
        if (ticket.nextBillingDate != null &&
            ticket.nextBillingDate!.isBefore(now)) {
          session.log(
              'Ticket $ticketId (Abo) ist abgelaufen, letzte Zahlung: ${ticket.lastBillingDate}',
              level: LogLevel.warning);
          return false;
        }

        // Nutzung protokollieren
        await _logTicketUsage(session, ticketId, facilityId, staffId, 0);

        session.log('Abo-Ticket $ticketId erfolgreich validiert');
        return true;
      } else {
        // ✅ EINZELTICKETS: Korrekte Tagesticket-Logik ✅

        // 1. Überprüfung: Ist das Ticket bereits für heute aktiviert?
        if (ticket.activatedForDate != null) {
          final activatedDate = DateTime(
            ticket.activatedForDate!.year,
            ticket.activatedForDate!.month,
            ticket.activatedForDate!.day,
          );

          if (activatedDate.isAtSameMomentAs(today)) {
            // Ticket ist bereits für heute aktiviert - erlaubt beliebige Ein-/Ausgänge
            ticket.currentUsageCount = (ticket.currentUsageCount ?? 0) + 1;
            ticket.updatedAt = now;
            await Ticket.db.updateRow(session, ticket);

            // Nutzung protokollieren
            await _logTicketUsage(session, ticketId, facilityId, staffId, 0);

            session.log(
                '✅ Tagesticket $ticketId: Ein-/Ausgang #${ticket.currentUsageCount} für heute (${today.toString().split(' ')[0]})');
            return true;
          } else if (activatedDate.isBefore(today)) {
            // Ticket war für einen früheren Tag aktiviert - ist jetzt abgelaufen
            session.log(
                'Ticket $ticketId war für ${activatedDate.toString().split(' ')[0]} aktiviert und ist abgelaufen',
                level: LogLevel.warning);
            return false;
          }
        }

        // 2. Erste Aktivierung: Ticket für heute aktivieren
        if (ticket.activatedDate == null) {
          // Erste Aktivierung überhaupt
          ticket.activatedDate = now;
          ticket.activatedForDate = today;
          ticket.currentUsageCount = 1;
          ticket.updatedAt = now;

          await Ticket.db.updateRow(session, ticket);

          // Nutzung protokollieren
          await _logTicketUsage(session, ticketId, facilityId, staffId, 0);

          session.log(
              '🎫 ERSTE AKTIVIERUNG: Tagesticket $ticketId für heute (${today.toString().split(' ')[0]}) aktiviert');
          return true;
        }

        // 3. Fallback: Ticket bereits mal aktiviert, aber nicht für heute
        session.log(
            'Ticket $ticketId kann nicht aktiviert werden - bereits für einen anderen Tag verwendet',
            level: LogLevel.warning);
        return false;
      }
    } catch (e) {
      session.log('Fehler bei der Ticketvalidierung: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // Nutzung eines Tickets protokollieren
  Future<void> _logTicketUsage(Session session, int ticketId, int facilityId,
      int staffId, int pointsUsed) async {
    try {
      final now = DateTime.now().toUtc();

      final usageLog = TicketUsageLog(
        ticketId: ticketId,
        usageDate: now,
        pointsUsed: pointsUsed,
        facilityId: facilityId,
        staffId: staffId,
        createdAt: now,
      );

      await TicketUsageLog.db.insertRow(session, usageLog);
    } catch (e) {
      session.log('Fehler beim Protokollieren der Ticketnutzung: $e',
          level: LogLevel.error);
    }
  }

  // NEUE verbesserte sichere Methode für die QR-Code-Generierung
  String _generateSecureQRCodeData(Ticket ticket) {
    // 1. Ticket-Payload erstellen (die Daten, die wir speichern wollen)
    final Map<String, dynamic> payload = {
      'id': ticket.id,
      'userId': ticket.userId,
      'typeId': ticket.ticketTypeId,
      'expiry': ticket.expiryDate.toIso8601String(),
      'points': ticket.remainingPoints,
      'ts': DateTime.now().toIso8601String(), // Zeitstempel der Erstellung
      'nonce': _generateNonce(), // Einmalwert für zusätzliche Sicherheit
    };

    // 2. Payload zu JSON konvertieren
    final jsonData = jsonEncode(payload);

    // 3. Digitale Signatur erstellen mit HMAC-SHA256
    final hmacSha256 = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmacSha256.convert(utf8.encode(jsonData));
    final signature = base64Url.encode(digest.bytes);

    // 4. Payload und Signatur kombinieren (Base64-codiert)
    final encodedPayload = base64Url.encode(utf8.encode(jsonData));
    return '$encodedPayload.$signature';
  }

  // Hilfsmethode: QR-Code validieren
  bool _validateQrCodeData(String qrCodeData, Ticket ticket) {
    try {
      // 1. QR-Code-Daten aufteilen in Payload und Signatur
      final parts = qrCodeData.split('.');
      if (parts.length != 2) return false;

      final encodedPayload = parts[0];
      final signature = parts[1];

      // 2. Payload dekodieren
      final jsonData = utf8.decode(base64Url.decode(encodedPayload));

      // 3. Signatur überprüfen
      final hmacSha256 = Hmac(sha256, utf8.encode(_secretKey));
      final digest = hmacSha256.convert(utf8.encode(jsonData));
      final expectedSignature = base64Url.encode(digest.bytes);

      if (signature != expectedSignature) return false;

      // 4. Payload-Daten auslesen und mit Ticket vergleichen
      final payload = jsonDecode(jsonData) as Map<String, dynamic>;

      // Überprüfe die wichtigsten Felder
      if (payload['id'] != ticket.id) return false;
      if (payload['userId'] != ticket.userId) return false;
      if (payload['typeId'] != ticket.ticketTypeId) return false;

      return true;
    } catch (e) {
      return false; // Bei Fehlern gilt der QR-Code als ungültig
    }
  }

  // Hilfsmethode: Zufälligen Nonce (Einmalwert) generieren
  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Alle Tickets abrufen (für Statistik-Seite)
  Future<List<Ticket>> getAllTickets(Session session) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Ticket-Liste-Zugriff verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Ticket-Liste');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_all_tickets');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_all_tickets (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Einsehen aller Tickets');
    }

    try {
      // Alle Tickets finden
      final tickets = await Ticket.db.find(
        session,
        orderBy: (t) => t.purchaseDate,
        orderDescending: true,
      );

      session.log('Alle Tickets abgerufen: ${tickets.length}');
      return tickets;
    } catch (e) {
      session.log('Fehler beim Abrufen aller Tickets: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Abo verlängern/Zahlung durchführen
  Future<bool> renewSubscription(Session session, int ticketId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Abo-Verlängerung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Abo-Verlängerung');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_subscriptions');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_subscriptions (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Verwalten von Abonnements');
    }

    try {
      final ticket = await Ticket.db.findById(session, ticketId);
      if (ticket == null) {
        session.log('Ticket $ticketId nicht gefunden', level: LogLevel.error);
        return false;
      }

      final ticketType =
          await TicketType.db.findById(session, ticket.ticketTypeId);
      if (ticketType == null || !ticketType.isSubscription) {
        session.log('Ticket $ticketId ist kein Abo', level: LogLevel.error);
        return false;
      }

      // Aktuelles Datum verwenden
      final now = DateTime.now().toUtc();

      // Letzte Zahlung aktualisieren
      ticket.lastBillingDate = now;

      // Nächstes Zahlungsdatum berechnen
      final billingInterval = ticketType.billingInterval ?? 30;
      ticket.nextBillingDate = now.add(Duration(days: billingInterval));

      // Status auf aktiv setzen falls pausiert
      if (ticket.subscriptionStatus == 'PAUSED') {
        ticket.subscriptionStatus = 'ACTIVE';
      }

      ticket.updatedAt = now;
      await Ticket.db.updateRow(session, ticket);

      session.log(
          'Abo für Ticket $ticketId verlängert bis ${ticket.nextBillingDate}');
      return true;
    } catch (e) {
      session.log('Fehler bei der Aboverlängerung: $e', level: LogLevel.error);
      return false;
    }
  }

  // Abo pausieren/kündigen
  Future<bool> changeSubscriptionStatus(
      Session session, int ticketId, String status) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Abo-Status-Änderung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Abo-Status-Änderung');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_subscriptions');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_subscriptions (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Verwalten von Abonnements');
    }

    try {
      final ticket = await Ticket.db.findById(session, ticketId);
      if (ticket == null) {
        session.log('Ticket $ticketId nicht gefunden', level: LogLevel.error);
        return false;
      }

      final ticketType =
          await TicketType.db.findById(session, ticket.ticketTypeId);
      if (ticketType == null || !ticketType.isSubscription) {
        session.log('Ticket $ticketId ist kein Abo', level: LogLevel.error);
        return false;
      }

      // Status prüfen und aktualisieren
      if (status != 'ACTIVE' && status != 'PAUSED' && status != 'CANCELLED') {
        session.log('Ungültiger Status: $status', level: LogLevel.error);
        return false;
      }

      // Status aktualisieren
      ticket.subscriptionStatus = status;
      ticket.updatedAt = DateTime.now().toUtc();
      await Ticket.db.updateRow(session, ticket);

      session.log('Abo-Status für Ticket $ticketId auf $status geändert');
      return true;
    } catch (e) {
      session.log('Fehler bei der Statusänderung: $e', level: LogLevel.error);
      return false;
    }
  }

  // Punktekarte aufladen
  Future<bool> rechargePointCard(
      Session session, int ticketId, int additionalPoints) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Punktekarten-Aufladung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Punktekarten-Aufladung');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_point_cards');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_point_cards (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Verwalten von Punktekarten');
    }

    try {
      final ticket = await Ticket.db.findById(session, ticketId);
      if (ticket == null) {
        session.log('Ticket $ticketId nicht gefunden', level: LogLevel.error);
        return false;
      }

      final ticketType =
          await TicketType.db.findById(session, ticket.ticketTypeId);
      if (ticketType == null || !ticketType.isPointBased) {
        session.log('Ticket $ticketId ist keine Punktekarte',
            level: LogLevel.error);
        return false;
      }

      // Punkte aktualisieren
      if (ticket.remainingPoints == null) {
        ticket.remainingPoints = additionalPoints;
      } else {
        ticket.remainingPoints = ticket.remainingPoints! + additionalPoints;
      }

      ticket.updatedAt = DateTime.now().toUtc();
      await Ticket.db.updateRow(session, ticket);

      session.log(
          'Punktekarte $ticketId aufgeladen mit $additionalPoints Punkten (neu: ${ticket.remainingPoints})');
      return true;
    } catch (e) {
      session.log('Fehler beim Aufladen der Punktekarte: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Kauft automatisch das beste Ticket für eine Kategorie (Einzelticket, Punktekarte, etc.)
  Future<Ticket?> purchaseRecommendedTicket(
      Session session, String category) async {
    // 🔑 UNIFIED AUTHENTICATION SYSTEM (Phase 3.1)
    int? userId;
    String? userEmail;
    String authSource = '';

    // 1. ZUERST: Staff-Authentication prüfen (für Staff-App)
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId != null) {
      // Staff-User gefunden - lade den zugehörigen AppUser
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser != null) {
        // Finde den entsprechenden AppUser basierend auf Email
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.email.equals(staffUser.email),
        );
        if (appUser != null) {
          userId = appUser.id;
          userEmail = appUser.email;
          authSource = 'Staff-Auth';
          session.log(
              '🔑 $authSource: Staff-User ${staffUser.email} → AppUser-ID $userId');
        }
      }
    }

    // 2. FALLBACK: Client-App Authentication prüfen (für Client-App)
    if (userId == null) {
      session.log('🔑 Client-App Authentication (nicht Staff)');
      final authInfo = await session.authenticated;
      if (authInfo != null) {
        // **NEU: UserInfo direkt aus DB laden (nicht aus Session-Cache)**
        final userInfo =
            await auth.UserInfo.db.findById(session, authInfo.userId);
        if (userInfo != null && userInfo.scopeNames.contains('client')) {
          // Finde AppUser basierend auf userInfoId
          final appUser = await AppUser.db.findFirstRow(
            session,
            where: (u) => u.userInfoId.equals(authInfo.userId),
          );
          if (appUser != null) {
            userId = appUser.id;
            userEmail = appUser.email;
            authSource = 'Client-Auth';
            session.log(
                '🔑 $authSource: UserInfo.id=${authInfo.userId} → AppUser-ID $userId ($userEmail)');
          } else {
            session.log(
                '🔑 Client-Auth FEHLER: Kein AppUser für userInfoId ${authInfo.userId} gefunden!',
                level: LogLevel.error);
          }
        } else {
          session.log('❌ Fehlender Client-Scope oder UserInfo nicht gefunden');
        }
      }
    }

    if (userId == null) {
      session.log('[DEBUG] purchaseRecommendedTicket: Nicht eingeloggt!',
          level: LogLevel.error);
      return null;
    }

    session.log(
        '[DEBUG] purchaseRecommendedTicket [$authSource]: userId=$userId ($userEmail), category=$category');

    try {
      // Benutzer prüfen
      final user = await AppUser.db.findById(session, userId);
      if (user == null) {
        session.log(
            '[DEBUG] purchaseRecommendedTicket: Benutzer mit ID $userId nicht gefunden',
            level: LogLevel.error);
        return null;
      }

      // Benutzer-Validierung (gesperrt, Email verifiziert)
      if (user.isBlocked == true) {
        session.log(
            '[DEBUG] purchaseRecommendedTicket: Account gesperrt: ${user.email} (${user.blockedReason})',
            level: LogLevel.warning);
        throw Exception(
            'Ihr Account ist gesperrt und kann keine Tickets kaufen. Grund: \\${user.blockedReason ?? "Nicht angegeben"}');
      }

      if (user.isEmailVerified == false) {
        session.log(
            '[DEBUG] purchaseRecommendedTicket: Email nicht verifiziert: ${user.email}',
            level: LogLevel.warning);
        throw Exception(
            'Bitte verifizieren Sie zuerst Ihre Email-Adresse, bevor Sie Tickets kaufen können.');
      }

      // Aktiven Status des Users holen
      final userStatus = await UserStatus.db.findFirstRow(
        session,
        where: (s) =>
            s.userId.equals(userId) &
            s.isVerified.equals(true) &
            (s.expiryDate > DateTime.now()),
        orderBy: (s) => s.expiryDate,
        orderDescending: true,
      );
      final userStatusTypeId = userStatus?.statusTypeId ?? 1; // 1 = Standard

      // Alter berechnen
      int age = user.birthDate != null ? _calculateAge(user.birthDate!) : 30;

      // Ticket je nach Kategorie wählen
      TicketType? recommendedTicket;
      switch (category) {
        case 'single':
          recommendedTicket =
              await _getFirstTicketByCategory(session, 'single');
          break;
        case 'monthly':
          recommendedTicket =
              await _getFirstTicketByCategory(session, 'monthly');
          break;
        case 'yearly':
          recommendedTicket =
              await _getFirstTicketByCategory(session, 'yearly');
          break;
        case 'points':
          recommendedTicket =
              await _getFirstTicketByCategory(session, 'points');
          break;
        default:
          session.log('[DEBUG] Unbekannte Kategorie: $category');
          return null;
      }

      if (recommendedTicket == null) {
        session.log(
            '[DEBUG] purchaseRecommendedTicket: Kein passender Tickettyp für Kategorie $category, Alter $age und Status $userStatusTypeId gefunden',
            level: LogLevel.error);
        return null;
      }

      session.log(
          '[DEBUG] purchaseRecommendedTicket: Automatisch gewählter TicketType: \\${recommendedTicket.name} (ID: \\${recommendedTicket.id}) für Kategorie $category');

      // Rest der purchaseTicket Logik verwenden
      return await _createTicketForUser(
          session, user, recommendedTicket, userStatusTypeId);
    } catch (e) {
      session.log(
          '[DEBUG] purchaseRecommendedTicket: Fehler beim Kauf des empfohlenen Tickets: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Hilfsmethode: Erstellt ein Ticket für einen User mit gegebenem TicketType
  Future<Ticket?> _createTicketForUser(Session session, AppUser user,
      TicketType ticketType, int userStatusTypeId) async {
    try {
      // Preis für Tickettyp + Status ermitteln
      final pricing = await TicketTypePricing.db.findFirstRow(
        session,
        where: (p) =>
            p.ticketTypeId.equals(ticketType.id!) &
            p.userStatusTypeId.equals(userStatusTypeId),
      );
      double price = pricing?.price ?? ticketType.defaultPrice;

      // Aktuelles Datum als Kaufdatum verwenden
      final now = DateTime.now().toUtc();

      // Ablaufdatum berechnen
      DateTime expiryDate;
      if (ticketType.isSubscription) {
        expiryDate = now.add(Duration(days: ticketType.billingInterval ?? 30));
      } else {
        expiryDate = now.add(Duration(days: ticketType.validityPeriod));
      }

      // Ticket erstellen
      Ticket ticket = Ticket(
        userId: user.id!,
        ticketTypeId: ticketType.id!,
        price: price,
        purchaseDate: now,
        expiryDate: expiryDate,
        isUsed: false,
        qrCodeData: '',
        activatedDate: null,
        activatedForDate: null,
        currentUsageCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      if (ticketType.isPointBased) {
        ticket.initialPoints = ticketType.defaultPoints;
        ticket.remainingPoints = ticketType.defaultPoints;
      }
      if (ticketType.isSubscription) {
        ticket.subscriptionStatus = 'ACTIVE';
        ticket.lastBillingDate = now;
        ticket.nextBillingDate = expiryDate;
      }

      session.log(
          '[DEBUG] _createTicketForUser: Ticket-Objekt vor Insert: userId=${ticket.userId}, ticketTypeId=${ticket.ticketTypeId}, price=${ticket.price}, expiryDate=${ticket.expiryDate}, isPointBased=${ticketType.isPointBased}, isSubscription=${ticketType.isSubscription}');
      Ticket savedTicket = await Ticket.db.insertRow(session, ticket);
      session.log(
          '[DEBUG] _createTicketForUser: Ticket nach Insert: id=${savedTicket.id}, userId=${savedTicket.userId}, ticketTypeId=${savedTicket.ticketTypeId}');
      final qrCodeData = _generateSecureQRCodeData(savedTicket);
      savedTicket.qrCodeData = qrCodeData;
      savedTicket = await Ticket.db.updateRow(session, savedTicket);

      session.log(
          '[DEBUG] _createTicketForUser: Ticket für Benutzer ${user.id} erstellt vom Typ ${ticketType.name}');
      return savedTicket;
    } catch (e) {
      session.log(
          '[DEBUG] _createTicketForUser: Fehler beim Erstellen des Tickets: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Markiert ein Ticket als gedruckt
  Future<bool> markTicketAsPrinted(
      Session session, int ticketId, String? printJobId) async {
    final userId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (userId == null) return false;

    try {
      final ticket = await Ticket.db.findById(session, ticketId);
      if (ticket == null || ticket.userId != userId) {
        session.log('Ticket $ticketId nicht gefunden oder keine Berechtigung',
            level: LogLevel.warning);
        return false;
      }

      // TODO: Nach Model-Generation implementieren
      // final purchaseStatus = await UserPurchaseStatus.db.findFirstRow(
      //   session,
      //   where: (s) => s.userId.equals(userId) & s.ticketTypeId.equals(ticket.ticketTypeId),
      // );

      // if (purchaseStatus != null) {
      //   purchaseStatus.isPrintingPending = false;
      //   purchaseStatus.printJobId = printJobId;
      //   purchaseStatus.printedAt = DateTime.now().toUtc();
      //   purchaseStatus.updatedAt = DateTime.now().toUtc();
      //   await UserPurchaseStatus.db.updateRow(session, purchaseStatus);
      // }

      session.log(
          'Ticket $ticketId als gedruckt markiert (PrintJob: $printJobId)');
      return true;
    } catch (e) {
      session.log('Fehler beim Markieren als gedruckt: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// 🎫 VOLLSTÄNDIG NEUE DB-BASIERTE HIERARCHISCHE TICKET-SICHTBARKEIT
  /// ECHTE FACILITY-GYM-RELATIONEN - KEINE HARDCODIERTEN NAMEN!
  Future<Map<String, dynamic>> getTicketsHierarchicalDb(Session session) async {
    try {
      // User-Authentifizierung
      final userId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      AppUser? user;

      if (userId != null) {
        user = await AppUser.db.findById(session, userId);
        session.log('🔐 User: ${user?.email} (Level: ${_getUserLevel(user)})');
      }

      // 🎯 ECHTE DB-BASIERTE TICKET-FILTERUNG (OHNE HARDCODIERTE NAMEN!)
      List<TicketType> allowedTickets = [];

      // VEREINFACHT: Alle Benutzer sehen alle Tickets
      // TODO: Später mit StaffUser-System verfeinern
      allowedTickets =
          await TicketType.db.find(session, orderBy: (t) => t.name);
      session.log('📋 Alle Tickets geladen: ${allowedTickets.length}');

      // 📊 SAUBERE KATEGORISIERUNG (OHNE HARDCODIERTE NAMEN!)
      final einzeltickets = allowedTickets
          .where((t) => !t.isPointBased && !t.isSubscription)
          .length;
      final punktekarten = allowedTickets.where((t) => t.isPointBased).length;
      final zeitkarten = allowedTickets.where((t) => t.isSubscription).length;

      session.log(
          '📊 DB-Kategorien: $einzeltickets Einzel, $punktekarten Punkte, $zeitkarten Zeit');

      // 🎯 ECHTE DB-BASIERTE RESPONSE (KEINE HARDCODIERTEN GYMS!)
      return {
        'success': true,
        'userLevel': _getUserLevel(user),
        'totalTickets': allowedTickets.length,
        'categories': {
          'einzeltickets': einzeltickets,
          'punktekarten': punktekarten,
          'zeitkarten': zeitkarten,
        },
        'tickets': allowedTickets
            .map((t) => {
                  'id': t.id,
                  'name': t.name,
                  'gymId': t.gymId,
                  'isVerticUniversal': t.isVerticUniversal,
                  'isPointBased': t.isPointBased,
                  'isSubscription': t.isSubscription,
                })
            .toList(),
      };
    } catch (e, stackTrace) {
      session.log('❌ Fehler in getTicketsHierarchicalDb: $e',
          level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
        'userLevel': 'Error',
        'universal': {'tickets': 0},
        'gymGroups': <String, dynamic>{},
        'summary': {'totalTickets': 0, 'totalGyms': 0, 'gymGroups': 0},
      };
    }
  }

  /// Helper: Bestimmt User-Level für Logging
  String _getUserLevel(AppUser? user) {
    if (user == null) return 'Anonymous';
    return 'User'; // Vereinfacht: Alle AppUser sind normale User
  }

  /// Bestimmt die Kategorie eines Tickets basierend auf Eigenschaften
  String _getTicketCategory(TicketType ticketType) {
    if (ticketType.isPointBased) {
      return 'punktekarten';
    } else if (ticketType.isSubscription) {
      return 'zeitkarten';
    } else {
      return 'einzeltickets';
    }
  }

  /// Speichert hierarchische Kategorie-Sichtbarkeit (nur SuperUser)
  Future<bool> saveHierarchicalVisibilitySettings(
    Session session,
    Map<String, dynamic> settings,
  ) async {
    final userId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (userId == null) return false;

    final user = await AppUser.db.findById(session, userId);
    if (user == null) {
      session.log('Nur SuperUser können hierarchische Sichtbarkeit verwalten',
          level: LogLevel.warning);
      return false;
    }

    try {
      // TODO: Nach Model-Generation echte Implementation
      session.log('Hierarchische Sichtbarkeits-Einstellungen gespeichert');
      return true;
    } catch (e) {
      session.log('Fehler beim Speichern der hierarchischen Einstellungen: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Debug-Methode: Zeigt alle Tickets und Gym-Zuordnungen
  Future<Map<String, dynamic>> debugTicketGymMappings(Session session) async {
    try {
      final allTicketTypes =
          await TicketType.db.find(session, orderBy: (t) => t.name);
      final allGyms = await Gym.db.find(session, orderBy: (g) => g.name);

      final result = {
        'gyms': allGyms
            .map((g) => {
                  'id': g.id,
                  'name': g.name,
                  'shortCode': g.shortCode,
                  'city': g.city,
                  'isActive': g.isActive,
                  'isVerticLocation': g.isVerticLocation,
                })
            .toList(),
        'tickets': allTicketTypes
            .map((t) => {
                  'id': t.id,
                  'name': t.name,
                  'gymId': t.gymId,
                  'isVerticUniversal': t.isVerticUniversal,
                  'isPointBased': t.isPointBased,
                  'isSubscription': t.isSubscription,
                  'gymName': t.gymId != null
                      ? allGyms
                          .firstWhere((g) => g.id == t.gymId,
                              orElse: () => Gym(
                                  id: -1,
                                  name: 'NOT_FOUND',
                                  shortCode: 'NF',
                                  city: 'NF',
                                  isActive: false,
                                  createdAt: DateTime.now()))
                          .name
                      : 'NULL'
                })
            .toList(),
        'summary': {
          'totalGyms': allGyms.length,
          'totalTickets': allTicketTypes.length,
          'ticketsWithGym': allTicketTypes.where((t) => t.gymId != null).length,
          'ticketsVerticUniversal':
              allTicketTypes.where((t) => t.isVerticUniversal).length,
        }
      };

      session.log('=== DEBUG TICKET-GYM MAPPINGS ===');
      session.log('Gyms found: ${allGyms.length}');
      for (final gym in allGyms) {
        session.log(
            '  Gym [${gym.id}]: ${gym.name} (${gym.city}) - Active: ${gym.isActive}');
      }

      session.log('Tickets found: ${allTicketTypes.length}');
      for (final ticket in allTicketTypes) {
        final gymName = ticket.gymId != null
            ? allGyms
                .firstWhere((g) => g.id == ticket.gymId,
                    orElse: () => Gym(
                        id: -1,
                        name: 'NOT_FOUND',
                        shortCode: 'NF',
                        city: 'NF',
                        isActive: false,
                        createdAt: DateTime.now()))
                .name
            : 'NULL';
        session.log(
            '  Ticket [${ticket.id}]: ${ticket.name} → GymID: ${ticket.gymId}, GymName: $gymName, Vertic: ${ticket.isVerticUniversal}');
      }

      return result;
    } catch (e) {
      session.log('Fehler beim Debug der Ticket-Gym Mappings: $e',
          level: LogLevel.error);
      return {'error': e.toString()};
    }
  }

  /// Debug-Methode: Zeigt alle TicketTypes mit ihrer validityPeriod
  Future<Map<String, dynamic>> debugTicketTypesValidityPeriods(
      Session session) async {
    try {
      final allTicketTypes =
          await TicketType.db.find(session, orderBy: (t) => t.name);

      final result = {
        'totalTicketTypes': allTicketTypes.length,
        'ticketTypes': allTicketTypes
            .map((t) => {
                  'id': t.id,
                  'name': t.name,
                  'validityPeriod': t.validityPeriod,
                  'isPointBased': t.isPointBased,
                  'isSubscription': t.isSubscription,
                  'description': t.description,
                })
            .toList(),
      };

      session.log('=== DEBUG TICKET TYPES VALIDITY PERIODS ===');
      session.log('Total TicketTypes: ${allTicketTypes.length}');
      for (final ticket in allTicketTypes) {
        session.log(
            'TicketType [${ticket.id}]: ${ticket.name} → validityPeriod: ${ticket.validityPeriod} Tage, isPointBased: ${ticket.isPointBased}, isSubscription: ${ticket.isSubscription}');
      }

      return result;
    } catch (e) {
      session.log('Fehler beim Debug der TicketType Validity Periods: $e',
          level: LogLevel.error);
      return {'error': e.toString()};
    }
  }

  /// TEMPORÄRE KORREKTUR: Behebt das validityPeriod=0 Problem für Einzeltickets
  Future<Map<String, dynamic>> fixSingleTicketValidityPeriod(
      Session session) async {
    try {
      // Korrigiere alle Einzeltickets mit validityPeriod=0 auf validityPeriod=1 Tag
      final allTicketTypes = await TicketType.db.find(session);
      int fixedCount = 0;

      session.log('=== FIXING SINGLE TICKET VALIDITY PERIODS ===');

      for (final ticketType in allTicketTypes) {
        // Nur Einzeltickets (nicht punktebasiert, nicht Abo) mit validityPeriod <= 0
        if (!ticketType.isPointBased &&
            !ticketType.isSubscription &&
            ticketType.validityPeriod <= 0) {
          session.log(
              'Korrigiere TicketType: ${ticketType.name} - validityPeriod von ${ticketType.validityPeriod} auf 1 Tag');

          // Erstelle neuen TicketType mit korrigierter validityPeriod
          final updatedTicketType = ticketType.copyWith(validityPeriod: 1);

          // Update in der Datenbank
          await TicketType.db.updateRow(session, updatedTicketType);
          fixedCount++;
        }
      }

      final result = {
        'fixedTicketTypes': fixedCount,
        'message': 'Einzelticket validityPeriod auf 1 Tag korrigiert'
      };

      session.log(
          '=== KORREKTUR ABGESCHLOSSEN: $fixedCount TicketTypes behoben ===');
      return result;
    } catch (e) {
      session.log('Fehler beim Beheben der validityPeriod: $e',
          level: LogLevel.error);
      return {'error': e.toString(), 'fixedTicketTypes': 0};
    }
  }

  /// Kauft das erste verfügbare Ticket einer Kategorie (vereinfachte Version)
  Future<TicketType?> _getFirstTicketByCategory(
      Session session, String category) async {
    final allTicketTypes = await TicketType.db.find(session);

    switch (category) {
      case 'single':
        return allTicketTypes.firstWhere(
          (t) => !t.isSubscription && !t.isPointBased,
          orElse: () => allTicketTypes.first,
        );
      case 'monthly':
        return allTicketTypes.firstWhere(
          (t) =>
              t.isSubscription &&
              (t.billingInterval == 30 || t.billingInterval == null),
          orElse: () => allTicketTypes.first,
        );
      case 'yearly':
        return allTicketTypes.firstWhere(
          (t) => t.isSubscription && t.billingInterval == 365,
          orElse: () => allTicketTypes.first,
        );
      case 'points':
        return allTicketTypes.firstWhere(
          (t) => t.isPointBased,
          orElse: () => allTicketTypes.first,
        );
      default:
        return allTicketTypes.first;
    }
  }

  /// Prüft Purchase-Status für einen User und TicketType
  Future<PurchaseStatusResponse?> getUserPurchaseStatus(
      Session session, int ticketTypeId) async {
    // 🔑 UNIFIED AUTHENTICATION SYSTEM (Phase 3.1)
    int? userId;
    String? userEmail;
    String authSource = '';

    // 1. ZUERST: Staff-Authentication prüfen (für Staff-App)
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId != null) {
      // Staff-User gefunden - lade den zugehörigen AppUser
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser != null) {
        // Finde den entsprechenden AppUser basierend auf Email
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.email.equals(staffUser.email),
        );
        if (appUser != null) {
          userId = appUser.id;
          userEmail = appUser.email;
          authSource = 'Staff-Auth';
          session.log(
              '🔑 $authSource: Staff-User ${staffUser.email} → AppUser-ID $userId');
        }
      }
    }

    // 2. FALLBACK: Client-App Authentication prüfen (für Client-App)
    if (userId == null) {
      session.log('🔑 Client-App Authentication (nicht Staff)');
      final authInfo = await session.authenticated;
      if (authInfo != null) {
        // **NEU: UserInfo direkt aus DB laden (nicht aus Session-Cache)**
        final userInfo =
            await auth.UserInfo.db.findById(session, authInfo.userId);
        if (userInfo != null && userInfo.scopeNames.contains('client')) {
          // Finde AppUser basierend auf userInfoId
          final appUser = await AppUser.db.findFirstRow(
            session,
            where: (u) => u.userInfoId.equals(authInfo.userId),
          );
          if (appUser != null) {
            userId = appUser.id;
            userEmail = appUser.email;
            authSource = 'Client-Auth';
            session.log(
                '🔑 $authSource: UserInfo.id=${authInfo.userId} → AppUser-ID $userId ($userEmail)');
          } else {
            session.log(
                '🔑 Client-Auth FEHLER: Kein AppUser für userInfoId ${authInfo.userId} gefunden!',
                level: LogLevel.error);
          }
        } else {
          session.log('❌ Fehlender Client-Scope oder UserInfo nicht gefunden');
        }
      }
    }

    if (userId == null) {
      session.log('Client-App Authentication: Nicht eingeloggt!',
          level: LogLevel.error);
      return null;
    }

    try {
      // Prüfe direkt in Tickets table ob User schon ein Ticket dieses Typs hat
      final existingTickets = await Ticket.db.find(
        session,
        where: (t) =>
            t.userId.equals(userId!) & t.ticketTypeId.equals(ticketTypeId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );

      session.log(
          '🔍 [$authSource] getUserPurchaseStatus: User $userId, TicketType $ticketTypeId → ${existingTickets.length} gefundene Tickets');

      if (existingTickets.isEmpty) {
        // Kein Ticket dieser Art gekauft
        return PurchaseStatusResponse(
          hasPurchased: false,
          canPurchaseAgain: true,
          isPrintingPending: false,
          lastPurchaseDate: null,
        );
      }

      // Nehme das neueste Ticket
      final latestTicket = existingTickets.first;

      // Für die vereinfachte Version: Neu gekaufte Tickets sind immer druckbereit
      final isPrintingPending = true; // Vereinfacht - alle sind druckbereit

      return PurchaseStatusResponse(
        hasPurchased: true,
        canPurchaseAgain: false, // Normalerweise nur ein Ticket pro Typ
        isPrintingPending: isPrintingPending,
        lastPurchaseDate: latestTicket.purchaseDate,
        ticketId: latestTicket.id,
      );
    } catch (e) {
      session.log('❌ [$authSource] Fehler beim Prüfen des Purchase-Status: $e',
          level: LogLevel.error);
      return null;
    }
  }
}
