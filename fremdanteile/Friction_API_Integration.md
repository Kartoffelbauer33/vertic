# 🔐 Friction API - Komplette Integrationsdokumentation

## 📡 **API Basis-Informationen**

### Base URL
```
https://api.apptive.ch
```

### Door ID (Partner ID)
```
27
```
*Diese Partner-ID ist spezifisch für eure Halle und wird bei allen Check-ins verwendet*

---

## 🔑 **API Endpoints**

### 1. Benutzerinformationen abrufen
```http
GET https://api.apptive.ch/user/{user_id}
```

**Request Header:**
- Keine speziellen Header erforderlich

**Response Format (Erfolg):**
```json
{
  "success": true,
  "response": [
    {
      "firstname": "Max",
      "lastname": "Mustermann",
      "email": "max@example.com"
    }
  ]
}
```

**Response Format (Fehler):**
```json
{
  "success": false,
  "error": "Fehlermeldung"
}
```

### 2. Check-in durchführen
```http
POST https://api.apptive.ch/checkin
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": "1353",
  "partner_id": 27,
  "security_code": "6eff9671-0ab1-3569-9a41-ae292c24301f"
}
```

**Response Format (Erfolg):**
```json
{
  "success": true,
  "response": {
    "firstname": "Max",
    "lastname": "Mustermann"
  }
}
```

**Response Format (Fehler):**
```json
{
  "success": false,
  "error": {
    "code": 400,
    "message": "QR Code ist ungültig oder kein Internet!"
  }
}
```

**Spezielle Fehlermeldungen:**
- `"Doppelcheckin Schutz ist aktiv"` - Benutzer bereits heute eingecheckt
- `"QR Code ist ungültig oder kein Internet!"` - Ungültiger Security-Code

---

## 📱 **vCard Format**

Friction QR-Codes enthalten vCard-Daten in folgendem Format:

```vcard
BEGIN:VCARD
VERSION:3.0
FN:Max Mustermann
N:Mustermann;Max;;;
EMAIL:max@example.com
NOTE:1353
ORG:6eff9671-0ab1-3569-9a41-ae292c24301f
END:VCARD
```

### Wichtige vCard-Felder:
- **`NOTE`**: Enthält die **User-ID** (z.B. "1353")
- **`ORG`**: Enthält den **Security-Code** (UUID-Format)
- **`EMAIL`**: E-Mail-Adresse des Benutzers
- **`N`**: Name im Format "Nachname;Vorname;;;"
- **`FN`**: Vollständiger Name

---

## 🔄 **Integrations-Ablauf**

### 1. QR-Code scannen
- Scanne den Friction QR-Code
- Parse die vCard-Daten
- Extrahiere `user_id` und `security_code`

### 2. Benutzerinformationen abrufen (Optional)
```dart
GET /user/{user_id}
```
- Dient zur Validierung und Anzeige der Benutzerdaten
- Nicht zwingend erforderlich für Check-in

### 3. Check-in durchführen
```dart
POST /checkin
{
  "user_id": "{user_id}",
  "partner_id": 27,
  "security_code": "{security_code}"
}
```

### 4. Response verarbeiten
- Bei `success: true` → Check-in erfolgreich
- Bei `success: false` → Fehlerbehandlung je nach Fehlermeldung

---

## 💻 **Flutter Beispiel-Implementation**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FrictionAPI {
  static const String baseUrl = "https://api.apptive.ch";
  static const int partnerId = 27;
  
  // vCard parsen
  static Map<String, String> parseVCard(String vCardData) {
    final lines = vCardData.split('\n');
    final result = <String, String>{};
    
    for (String line in lines) {
      if (line.startsWith('NOTE:')) {
        result['userId'] = line.substring(5).trim();
      } else if (line.startsWith('ORG:')) {
        result['securityCode'] = line.substring(4).trim();
      } else if (line.startsWith('EMAIL:')) {
        result['email'] = line.substring(6).trim();
      } else if (line.startsWith('N:')) {
        final nameParts = line.substring(2).split(';');
        if (nameParts.length >= 2) {
          result['lastname'] = nameParts[0].trim();
          result['firstname'] = nameParts[1].trim();
        }
      }
    }
    
    return result;
  }
  
  // Benutzerinformationen abrufen
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['response'] != null && data['response'].isNotEmpty) {
          return data['response'][0];
        }
      }
      return null;
    } catch (e) {
      print('Fehler beim Abrufen der Benutzerinformationen: $e');
      return null;
    }
  }
  
  // Check-in durchführen
  static Future<CheckinResult> checkinUser(String userId, String securityCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'partner_id': partnerId,
          'security_code': securityCode
        })
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final userInfo = data['response'] ?? {};
          return CheckinResult(
            success: true,
            firstname: userInfo['firstname'] ?? '',
            lastname: userInfo['lastname'] ?? '',
            message: 'Check-in erfolgreich'
          );
        } else {
          final error = data['error'] ?? {};
          final errorCode = error['code'] ?? 0;
          final errorMessage = error['message'] ?? 'Unbekannter Fehler';
          
          return CheckinResult(
            success: false,
            errorCode: errorCode,
            message: errorMessage,
            isAlreadyCheckedIn: errorMessage == "Doppelcheckin Schutz ist aktiv"
          );
        }
      } else {
        return CheckinResult(
          success: false,
          errorCode: response.statusCode,
          message: 'HTTP-Fehler: ${response.statusCode}'
        );
      }
    } catch (e) {
      return CheckinResult(
        success: false,
        message: 'Netzwerkfehler: $e'
      );
    }
  }
}

// Result-Klasse für Check-in Response
class CheckinResult {
  final bool success;
  final String firstname;
  final String lastname;
  final String message;
  final int errorCode;
  final bool isAlreadyCheckedIn;
  
  CheckinResult({
    required this.success,
    this.firstname = '',
    this.lastname = '',
    required this.message,
    this.errorCode = 0,
    this.isAlreadyCheckedIn = false
  });
}

// Verwendungsbeispiel
class FrictionScanner {
  static Future<void> processFrictionQR(String qrData) async {
    // 1. vCard parsen
    final vCardData = FrictionAPI.parseVCard(qrData);
    final userId = vCardData['userId'];
    final securityCode = vCardData['securityCode'];
    
    if (userId == null || securityCode == null) {
      print('Ungültiger QR-Code: User-ID oder Security-Code fehlt');
      return;
    }
    
    // 2. Optional: Benutzerinformationen abrufen
    final userInfo = await FrictionAPI.getUserInfo(userId);
    if (userInfo != null) {
      print('Benutzer: ${userInfo['firstname']} ${userInfo['lastname']}');
      print('E-Mail: ${userInfo['email']}');
    }
    
    // 3. Check-in durchführen
    final result = await FrictionAPI.checkinUser(userId, securityCode);
    
    if (result.success) {
      print('✅ Check-in erfolgreich: ${result.firstname} ${result.lastname}');
    } else if (result.isAlreadyCheckedIn) {
      print('ℹ️ Bereits eingecheckt: ${result.message}');
    } else {
      print('❌ Check-in fehlgeschlagen: ${result.message}');
    }
  }
}
```

---

## 🧪 **Test-Daten**

Für Tests kannst du folgende echte Daten aus euren Logs verwenden:

```dart
// Test User 1
final testUserId1 = "1353";
final testSecurityCode1 = "6eff9671-0ab1-3569-9a41-ae292c24301f";

// Test User 2  
final testUserId2 = "1402";
final testSecurityCode2 = "f2851925-fe46-3259-b642-845285eace5d";

// Test User 3
final testUserId3 = "1080";
final testSecurityCode3 = "029ad2db-265d-3639-99d9-d5057779fdfb";
```

**Test vCard:**
```vcard
BEGIN:VCARD
VERSION:3.0
FN:Angelina Tschoegl
N:Tschoegl;Angelina;;;
EMAIL:hola@yoya.at
NOTE:1353
ORG:6eff9671-0ab1-3569-9a41-ae292c24301f
END:VCARD
```

---

## ⚠️ **Wichtige Hinweise**

### Authentifizierung
- **Keine API-Keys erforderlich**: Die Friction API benötigt keine zusätzlichen Authentifizierungs-Header
- **Security-Code als Authentifizierung**: Der Security-Code aus der vCard dient als spezifische Authentifizierung

### Timeouts & Performance
- **Empfohlene Timeouts**: 5s für GET-Requests, 10s für POST-Requests
- **Retry-Logik**: Bei Netzwerkfehlern sollte ein Retry-Mechanismus implementiert werden

### Fehlerbehandlung
- **Doppel-Check-in**: Behandle "Doppelcheckin Schutz ist aktiv" als Info, nicht als Fehler
- **Netzwerkfehler**: Implementiere Offline-Handling falls erforderlich
- **Ungültige QR-Codes**: Validiere vCard-Format vor API-Aufrufen

### Partner-ID
- **Fest kodiert**: Partner-ID 27 ist spezifisch für eure Location
- **Nicht ändern**: Diese ID ist in der Friction-Datenbank hinterlegt

---

## 📞 **Support & Troubleshooting**

### Häufige Probleme:
1. **"QR Code ist ungültig"** → Security-Code ist abgelaufen oder falsch
2. **Timeout-Fehler** → Internetverbindung prüfen
3. **HTTP 500** → Friction-Server temporär nicht verfügbar

### Debug-Informationen:
Logge für Debugging immer:
- User-ID aus vCard
- HTTP Status Codes
- Vollständige Error Messages
- Response-Zeiten

---

*Erstellt: $(date)*
*Basiert auf: Scanner_Fastlane Codebase Analysis* 