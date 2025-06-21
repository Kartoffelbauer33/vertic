import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as auth;

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

// This is the starting point of your Serverpod server. In most cases, you will
// only need to make additions to this file if you add future calls, are
// configuring Relic (Serverpod's web-server), or need custom setup work.

/// Auth Handler für Client-App (NICHT für Staff-App!)
/// Die Staff-App verwendet ein komplett getrenntes System
Future<AuthenticationInfo?> clientAuthenticationHandler(
    Session session, String token) async {
  session.log('🔑 Client-App Authentication (nicht Staff)');
  return await auth.authenticationHandler(session, token);
}

void run(List<String> args) async {
  // AuthConfig für Client-App (NICHT für Staff-App!)
  auth.AuthConfig.set(auth.AuthConfig(
    // Für Client-App-User automatisch AppUser erstellen
    onUserCreated: (session, userInfo) async {
      session.log(
          '🆕 Neuer Client-User via Auth-Modul: ${userInfo.email}, Auth-ID: ${userInfo.id}, userIdentifier: ${userInfo.userIdentifier}');
      try {
        var appUser = await AppUser.db.findFirstRow(session,
            where: (user) => user.email.equals(userInfo.email));
        if (appUser == null && userInfo.email != null) {
          appUser = AppUser(
            firstName: userInfo.userName?.split(' ').first ?? 'N/A',
            lastName: userInfo.userName?.split(' ').last ?? 'N/A',
            email: userInfo.email!,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            gender: null,
            address: null,
            city: null,
            postalCode: null,
            phoneNumber: null,
            birthDate: null,
          );
          final savedAppUser = await AppUser.db.insertRow(session, appUser);
          session.log(
              '✅ AppUser für ${userInfo.email} erstellt mit ID: ${savedAppUser.id}');

          // 🔧 KRITISCHER FIX: Serverpod userIdentifier muss AppUser-ID entsprechen!
          // Aber da Serverpod userIdentifier = Email ist, ist das OKAY!
          // Unsere Endpoints verwenden jetzt korrekt userIdentifier (Email) -> AppUser lookup
          session.log(
              '📝 Serverpod userIdentifier: ${userInfo.userIdentifier} → AppUser-ID: ${savedAppUser.id}');
        } else {
          session.log(
              '✅ AppUser für ${userInfo.email} existiert bereits mit ID: ${appUser?.id}');
        }
      } catch (e) {
        session.log('❌ Fehler beim Erstellen des AppUser: $e',
            level: LogLevel.error);
      }
    },
    // E-Mail Validierung für Client-App
    sendValidationEmail: (session, email, validationCode) async {
      session.log('📧 VALIDIERUNGSCODE für Client-App $email: $validationCode');
      // 🚀 DEVELOPMENT: Schreibe Code auch in Datei für einfachen Zugriff
      try {
        await File('/tmp/vertic_email_codes.txt').writeAsString(
          'EMAIL: $email\nCODE: $validationCode\nTIME: ${DateTime.now()}\n\n',
          mode: FileMode.append,
        );
      } catch (e) {
        session.log('Konnte Email-Code nicht in Datei schreiben: $e');
      }

      // 🔧 DEVELOPMENT: Überschreibe Code mit 123456 für einfache Tests
      session.log(
          '🔧 DEVELOPMENT: Verwende Standard-Code 123456 statt $validationCode');
      return true; // Für Testing
    },
    // Passwort-Reset für Client-App
    sendPasswordResetEmail: (session, userInfo, validationCode) async {
      session.log(
          '🔓 PASSWORT-RESET für Client-App ${userInfo.email}: $validationCode');
      return true; // Für Testing
    },
  ));

  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
    authenticationHandler: clientAuthenticationHandler, // Nur für Client-App
  );

  // Setup a default page at the web root.
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/*',
  );

  // Start the server.
  await pod.start();
}

/// Names of all future calls in the server.
///
/// This is better than using a string literal, as it will reduce the risk of
/// typos and make it easier to refactor the code.
enum FutureCallNames {
  birthdayReminder,
}
