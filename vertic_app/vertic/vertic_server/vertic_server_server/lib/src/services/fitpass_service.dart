import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service für Fitpass API-Integration
class FitpassService {
  /// Extrahiert Check-in Code aus Fitpass QR-Code
  static String? extractCheckinCode(String qrCodeData) {
    // Fitpass QR-Codes beginnen mit "FP-"
    if (qrCodeData.startsWith('FP-')) {
      return qrCodeData;
    }
    return null;
  }

  /// Validiert Check-in bei Fitpass API
  static Future<ExternalCheckinResult> validateCheckin(
    Session session,
    ExternalProvider provider,
    String qrCodeData,
  ) async {
    try {
      // 1. API-Credentials entschlüsseln
      if (provider.apiCredentialsJson == null) {
        throw Exception('Fitpass benötigt API-Credentials');
      }
      final credentials = _decryptCredentials(provider.apiCredentialsJson!);

      // 2. Payload erstellen
      final payload = {
        'current_checkin_code': qrCodeData,
        'sport_partner': int.parse(provider.sportPartnerId!),
        'user_id': credentials['user_id'],
        'allow_checkin': true,
      };

      // 3. HMAC-Signatur generieren
      final signature =
          _generateHmacSignature(payload, credentials['secret_key']);

      // 4. API-Request
      final response = await http.post(
        Uri.parse(
            '${provider.apiBaseUrl}/api/partner-user/sport-partners/addcheck-in/'),
        headers: {
          'Content-Type': 'application/json',
          'X-Fitpass-Signature': signature,
        },
        body: jsonEncode(payload),
      );

      session.log(
          'Fitpass API Response: ${response.statusCode} - ${response.body}');

      // 5. Response verarbeiten
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['error'] == false) {
        // Erfolgreicher Check-in
        final data = responseData['data'];
        return ExternalCheckinResult(
          success: true,
          accessGranted: data['machine_grant_access'] == true,
          message: data['machine_message'] ?? 'Viel Spass!',
          userName: data['user'] != null
              ? '${data['user']['firstname']} ${data['user']['lastname']}'
              : null,
          userCity: data['user']?['city'],
          userAvatar: data['user']?['avatar'],
          providerName: 'fitpass',
          membershipType: 'Fitpass',
          statusCode: 201,
          externalStatusCode: data['status_code'],
          processingTimeMs: 0, // Wird später gesetzt
          isReEntry: false, // Wird später gesetzt
        );
      } else {
        // Fehler-Response
        final data = responseData['data'] ?? {};
        return ExternalCheckinResult(
          success: false,
          accessGranted: false,
          message: data['machine_message'] ??
              responseData['message'] ??
              'Unbekannter Fehler',
          providerName: 'fitpass',
          statusCode: response.statusCode,
          externalStatusCode: data['status_code'],
          processingTimeMs: 0,
          isReEntry: false,
          errorDetails: responseData['message'],
        );
      }
    } catch (e) {
      session.log('Fitpass API Fehler: $e', level: LogLevel.error);
      return ExternalCheckinResult(
        success: false,
        accessGranted: false,
        message: 'Technischer Fehler bei Fitpass-Validierung',
        providerName: 'fitpass',
        statusCode: 500,
        processingTimeMs: 0,
        isReEntry: false,
        errorDetails: e.toString(),
      );
    }
  }

  // Private Helper-Methoden

  static Map<String, dynamic> _decryptCredentials(String encryptedJson) {
    // TODO: Implementiere Entschlüsselung
    // Für jetzt: Annahme dass JSON bereits entschlüsselt ist
    return jsonDecode(encryptedJson);
  }

  static String _generateHmacSignature(
      Map<String, dynamic> payload, String secretKey) {
    // 1. Payload zu String ohne Whitespaces
    final payloadString = jsonEncode(payload).replaceAll(RegExp(r'\s'), '');

    // 2. HMAC-SHA256 Hash
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(payloadString);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    // 3. Lowercase hexadecimal
    return digest.toString().toLowerCase();
  }
}
