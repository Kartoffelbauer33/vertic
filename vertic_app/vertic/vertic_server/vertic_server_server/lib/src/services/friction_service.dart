import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service für Friction (Apptive) API-Integration
/// Gemäß offizieller Dokumentation: KEINE API-Credentials erforderlich!
class FrictionService {
  /// Extrahiert User-ID aus Friction vCard QR-Code
  static String? extractUserId(String qrCodeData) {
    try {
      // vCard Format parsen
      if (!qrCodeData.contains('BEGIN:VCARD')) return null;

      // NOTE Feld finden (enthält die Mitglieder ID)
      final noteMatch = RegExp(r'NOTE:(.+)').firstMatch(qrCodeData);
      return noteMatch?.group(1)?.trim();
    } catch (e) {
      return null;
    }
  }

  /// Extrahiert Security Key aus Friction vCard QR-Code
  static String? extractSecurityKey(String qrCodeData) {
    try {
      // ORG Feld finden (enthält den Security Key)
      final orgMatch = RegExp(r'ORG:(.+)').firstMatch(qrCodeData);
      return orgMatch?.group(1)?.trim();
    } catch (e) {
      return null;
    }
  }

  /// Validiert Check-in bei Friction API
  /// WICHTIG: Friction API benötigt KEINE API-Credentials!
  static Future<ExternalCheckinResult> validateCheckin(
    Session session,
    ExternalProvider provider,
    String qrCodeData,
  ) async {
    try {
      // 1. QR-Code-Daten extrahieren
      final userId = extractUserId(qrCodeData);
      final securityKey = extractSecurityKey(qrCodeData);

      if (userId == null || securityKey == null) {
        return ExternalCheckinResult(
          success: false,
          accessGranted: false,
          message: 'Ungültiger Friction QR-Code',
          providerName: 'friction',
          statusCode: 400,
          processingTimeMs: 0,
          isReEntry: false,
        );
      }

      // 2. API-Request Payload (KEINE Credentials erforderlich!)
      // Gemäß Dokumentation: nur user_id, partner_id, security_code
      final payload = {
        'user_id': userId,
        'partner_id':
            int.parse(provider.doorId ?? '27'), // Default Partner-ID 27
        'security_code': securityKey,
      };

      // 3. API-Request an korrekten Endpoint
      final response = await http.post(
        Uri.parse('${provider.apiBaseUrl}/checkin'), // Korrekter Endpoint!
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      session.log(
          'Friction API Response: ${response.statusCode} - ${response.body}');

      // 4. Response verarbeiten gemäß Dokumentation
      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        // Erfolgreicher Check-in
        final userData = responseData['response'] ?? {};
        return ExternalCheckinResult(
          success: true,
          accessGranted: true,
          message: 'Check-in erfolgreich',
          userName:
              '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}',
          userCity: null, // Friction liefert keine Stadt
          userAvatar: null, // Friction liefert kein Avatar
          providerName: 'friction',
          membershipType: 'Friction Access',
          statusCode: 200,
          processingTimeMs: 0,
          isReEntry: false,
        );
      } else {
        // Fehler beim Check-in
        final error = responseData['error'] ?? {};
        final errorMessage = error['message'] ?? 'Check-in fehlgeschlagen';
        final isDoubleCheckin =
            errorMessage == "Doppelcheckin Schutz ist aktiv";

        return ExternalCheckinResult(
          success: false,
          accessGranted: false,
          message: errorMessage,
          providerName: 'friction',
          statusCode: error['code'] ?? 400,
          processingTimeMs: 0,
          isReEntry: isDoubleCheckin, // Re-Entry erkennen
          errorDetails: errorMessage,
        );
      }
    } catch (e) {
      session.log('Friction API Fehler: $e', level: LogLevel.error);
      return ExternalCheckinResult(
        success: false,
        accessGranted: false,
        message: 'Technischer Fehler bei Friction-Validierung',
        providerName: 'friction',
        statusCode: 500,
        processingTimeMs: 0,
        isReEntry: false,
        errorDetails: e.toString(),
      );
    }
  }

  /// Optional: Benutzerinformationen abrufen (für Vorab-Validierung)
  static Future<Map<String, dynamic>?> getUserInfo(
    Session session,
    ExternalProvider provider,
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${provider.apiBaseUrl}/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['response'] != null &&
            data['response'].isNotEmpty) {
          return data['response'][0];
        }
      }
      return null;
    } catch (e) {
      session.log('Friction getUserInfo Fehler: $e', level: LogLevel.error);
      return null;
    }
  }
}
