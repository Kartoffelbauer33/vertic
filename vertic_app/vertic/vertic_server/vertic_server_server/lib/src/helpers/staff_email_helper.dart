import 'package:serverpod/serverpod.dart';
import 'dart:io';

/// Helper für Staff E-Mail-Benachrichtigungen
class StaffEmailHelper {
  /// Sendet eine E-Mail-Verifizierung an einen Staff-User
  static Future<bool> sendStaffVerificationEmail(
    Session session,
    String email,
    String firstName,
    String lastName,
    String verificationCode,
  ) async {
    try {
      session.log('📧 Sende Staff-Verifizierungs-E-Mail an: $email');
      session.log('🔐 STAFF VERIFICATION CODE für $email: $verificationCode');
      
      // 🚀 DEVELOPMENT: Schreibe Code auch in Datei für einfachen Zugriff (Windows-kompatibel)
      try {
        // Windows-kompatible Pfade verwenden  
        final tempDir = Platform.isWindows ? 'C:\\temp' : '/tmp';
        final separator = Platform.isWindows ? '\\' : '/';
        final staffLogFile = '$tempDir${separator}vertic_staff_email_codes.txt';
        final generalLogFile = '$tempDir${separator}vertic_email_codes.txt';
        
        // Erstelle Verzeichnis falls nicht vorhanden (Windows)
        if (Platform.isWindows) {
          final dir = Directory('C:\\temp');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
        }
        
        final logContent = '''
=== STAFF EMAIL VERIFICATION ===
TIME: ${DateTime.now()}
NAME: $firstName $lastName
EMAIL: $email
CODE: $verificationCode
TYPE: Staff Account Creation
================================

''';
        await File(staffLogFile).writeAsString(
          logContent,
          mode: FileMode.append,
        );
        
        // Auch in normale Email-Code-Datei für Konsistenz
        await File(generalLogFile).writeAsString(
          'STAFF - EMAIL: $email\nCODE: $verificationCode\nTIME: ${DateTime.now()}\n\n',
          mode: FileMode.append,
        );
        
        session.log('✅ Code gespeichert in: $staffLogFile');
      } catch (e) {
        session.log('Konnte Staff-Email-Code nicht in Datei schreiben: $e');
      }

      // TODO: Hier würde die echte E-Mail-Versendung implementiert werden
      // z.B. mit einem SMTP-Service wie SendGrid, AWS SES, etc.
      
      // Beispiel E-Mail-Template:
      /*
      Betreff: Verifizieren Sie Ihr Vertic Staff-Konto
      
      Hallo $firstName $lastName,
      
      Ein Administrator hat ein Staff-Konto für Sie erstellt.
      Bitte verifizieren Sie Ihre E-Mail-Adresse mit folgendem Code:
      
      Verifizierungscode: $verificationCode
      
      Dieser Code ist 24 Stunden gültig.
      
      Nach der Verifizierung können Sie sich mit Ihrer E-Mail-Adresse
      oder Ihrem Benutzernamen anmelden.
      
      Mit freundlichen Grüßen
      Ihr Vertic-Team
      */
      
      return true;
    } catch (e) {
      session.log('❌ Fehler beim Senden der Staff-Verifizierungs-E-Mail: $e', 
                  level: LogLevel.error);
      return false;
    }
  }
  
  /// Sendet einen neuen Verifizierungscode an einen Staff-User
  static Future<bool> resendStaffVerificationEmail(
    Session session,
    String email,
    String firstName,
    String lastName,
    String verificationCode,
  ) async {
    try {
      session.log('📧 Sende neuen Staff-Verifizierungs-Code an: $email');
      session.log('🔐 NEUER STAFF CODE für $email: $verificationCode');
      
      // Verwende dieselbe Methode wie beim ersten Senden
      return await sendStaffVerificationEmail(
        session,
        email,
        firstName,
        lastName,
        verificationCode,
      );
    } catch (e) {
      session.log('❌ Fehler beim erneuten Senden des Staff-Verifizierungscodes: $e', 
                  level: LogLevel.error);
      return false;
    }
  }
  
  /// Sendet eine Willkommens-E-Mail nach erfolgreicher Verifizierung
  static Future<bool> sendStaffWelcomeEmail(
    Session session,
    String email,
    String firstName,
    String lastName,
    String? employeeId,
  ) async {
    try {
      session.log('📧 Sende Staff-Willkommens-E-Mail an: $email');
      
      // TODO: Implementiere echte E-Mail-Versendung
      
      // Beispiel E-Mail-Template:
      /*
      Betreff: Willkommen bei Vertic Staff
      
      Hallo $firstName $lastName,
      
      Ihr Staff-Konto wurde erfolgreich aktiviert!
      
      Sie können sich jetzt mit folgenden Zugangsdaten anmelden:
      - E-Mail: $email
      ${employeeId != null ? '- Benutzername: $employeeId' : ''}
      
      Bitte bewahren Sie Ihre Zugangsdaten sicher auf.
      
      Bei Fragen wenden Sie sich bitte an Ihren Administrator.
      
      Mit freundlichen Grüßen
      Ihr Vertic-Team
      */
      
      return true;
    } catch (e) {
      session.log('❌ Fehler beim Senden der Staff-Willkommens-E-Mail: $e', 
                  level: LogLevel.error);
      return false;
    }
  }
  
  /// Sendet eine Passwort-Reset-E-Mail an einen Staff-User
  static Future<bool> sendStaffPasswordResetEmail(
    Session session,
    String email,
    String firstName,
    String lastName,
    String resetCode,
  ) async {
    try {
      session.log('📧 Sende Staff-Passwort-Reset-E-Mail an: $email');
      session.log('🔐 STAFF PASSWORD RESET CODE für $email: $resetCode');
      
      // 🚀 DEVELOPMENT: Log für einfachen Zugriff
      try {
        await File('/tmp/vertic_staff_password_reset.txt').writeAsString(
          'EMAIL: $email\nRESET CODE: $resetCode\nTIME: ${DateTime.now()}\n\n',
          mode: FileMode.append,
        );
      } catch (e) {
        session.log('Konnte Staff-Reset-Code nicht in Datei schreiben: $e');
      }
      
      // TODO: Implementiere echte E-Mail-Versendung
      
      return true;
    } catch (e) {
      session.log('❌ Fehler beim Senden der Staff-Passwort-Reset-E-Mail: $e', 
                  level: LogLevel.error);
      return false;
    }
  }
}