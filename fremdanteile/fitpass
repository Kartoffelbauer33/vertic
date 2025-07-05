# Fitpass API Documentation

**Anbieter:** Fitpass AG  
**Kontakt:** waleed.elsayed@fitpass.ch

## Übersicht

Die Fitpass API ermöglicht die Integration von Fitpass-Mitgliedercheckins in Sportpartner-Systeme. Die API verwendet HMAC-Signaturen für sichere Kommunikation und verwaltet Check-in-Records für Fitpass-Mitglieder.

## Authentication & Security

### HMAC Signature

Alle Requests müssen mit einer HMAC-Signatur versehen werden:

- **Algorithm:** SHA256
- **Header:** `X-Fitpass-Signature`
- **Format:** Lowercase hexadecimal
- **Content:** HMAC digest des Payload-Contents

### Signature Generation Process

1. Konvertiere Payload zu String (ohne Whitespaces oder Zeilenumbrüche)
2. Erstelle HMAC-SHA256 Hash mit dem bereitgestellten Secret Key
3. Konvertiere zu lowercase hexadecimal
4. Sende im `X-Fitpass-Signature` Header

### Example Signature Generation (JavaScript)

```javascript
const crypto = require('crypto');

function generateSignature(payload, secretKey) {
  const payloadString = JSON.stringify(payload).replace(/\s/g, '');
  const hmac = crypto.createHmac('sha256', secretKey);
  hmac.update(payloadString);
  return hmac.digest('hex').toLowerCase();
}

// Usage
const signature = generateSignature(requestPayload, 'your_secret_key');
```

## API Endpoints

### 1. Add Check-in Record

**Zweck:** Fügt einen Check-in-Record für einen Sportpartner hinzu und validiert Fitpass-Mitgliederdaten.

#### Endpoint Details

```
POST https://rest-fitpass-ch.herokuapp.com/api/partner-user/sport-partners/addcheck-in/
```

#### Request Headers

```
Content-Type: application/json
X-Fitpass-Signature: {hmac_signature}
```

#### Request Payload

```json
{
  "current_checkin_code": "FP-XXXXXXXXXX",
  "sport_partner": 123,
  "user_id": 456,
  "allow_checkin": true
}
```

#### Parameter Beschreibung

| Parameter | Typ | Required | Beschreibung |
|-----------|-----|----------|--------------|
| `current_checkin_code` | string | ✅ | Checkin-Code vom Mitglieder-QR-Code (beginnt immer mit "FP-") |
| `sport_partner` | integer | ✅ | ID des Sportpartners (von Fitpass bereitgestellt) |
| `user_id` | integer | ✅ | User ID des Sportpartners (von Fitpass bereitgestellt) |
| `allow_checkin` | boolean | ❌ | Optional, default: true. Für Mehrfach-Türen-Systeme |

#### Parameter Details

**current_checkin_code:**
- Beginnt immer mit "FP-"
- Wird aus dem QR-Code des Fitpass-Mitglieds gescannt
- QR-Code wird nur angezeigt, wenn Mitglied gültiges Abo hat

**sport_partner:**
- Eindeutige ID des Sportpartners
- Wird von Fitpass vergeben und bereitgestellt

**user_id:**
- User ID des Sportpartner-Accounts
- Jeder Sportpartner hat einen User für Aktionen
- Wird von Fitpass bereitgestellt

**allow_checkin:**
- Optional (default: true)
- Nützlich für Mehrfach-Türen-Systeme
- Bei false: Zugang gewähren ohne Check-in-Record zu erstellen
- Beispiel: Eingangstür (false) vs. Trainingsbereich-Tür (true)

## Response Formats

### Successful Responses (HTTP 201)

**Struktur:**
- HTTP Status Code: 201
- Response Body: `error: false, status_code: 201`

#### Success Response - Access Granted

```json
{
  "message": "Success",
  "data": {
    "machine_grant_access": true,
    "user": {
      "id": 489479274924092,
      "firstname": "Test",
      "lastname": "User", 
      "city": "Basel",
      "avatar": null
    },
    "machine_message": "Viel Spass!",
    "status_code": 201
  },
  "error": false
}
```

#### Success Response - Go to Reception

```json
{
  "message": "Success",
  "data": {
    "machine_grant_access": false,
    "user": {
      "id": 489479274924092,
      "firstname": "Test",
      "lastname": "User",
      "city": "Basel", 
      "avatar": null
    },
    "machine_message": "Zum Empfang!",
    "status_code": 201
  },
  "error": false
}
```

### Error Responses (HTTP 400)

**Struktur:**
- HTTP Status Code: 400
- Response Body: `error: true`

#### Error Response Examples

**Member existiert nicht (Status Code 100):**
```json
{
  "message": "User with this checkin code does not exist",
  "data": {
    "machine_grant_access": false,
    "machine_message": "Member existiert nicht",
    "status_code": 100
  },
  "error": true
}
```

**Partner existiert nicht (Status Code 101):**
```json
{
  "message": "Partner does not exist",
  "data": {
    "machine_grant_access": false,
    "machine_message": "Partner existiert nicht", 
    "status_code": 101
  },
  "error": true
}
```

**Benutzer nicht aktiv (Status Code 102):**
```json
{
  "message": "User is not active",
  "data": {
    "machine_grant_access": false,
    "machine_message": "Benutzer ist nicht aktiv",
    "status_code": 102
  },
  "error": true
}
```

**Kein Abo (Status Code 103):**
```json
{
  "message": "User has no subscription", 
  "data": {
    "machine_grant_access": false,
    "machine_message": "Benutzer hat kein Abo",
    "status_code": 103
  },
  "error": true
}
```

**Abo ungültig (Status Code 104):**
```json
{
  "message": "Subscription is not valid",
  "data": {
    "machine_grant_access": false,
    "machine_message": "Abo ist ungültig",
    "status_code": 104
  },
  "error": true
}
```

**Abo abgelaufen (Status Code 105):**
```json
{
  "message": "Your subscription is ended",
  "data": {
    "machine_grant_access": false,
    "machine_message": "Abo ist ungültig", 
    "status_code": 105
  },
  "error": true
}
```

**Partner nicht aktiv (Status Code 106):**
```json
{
  "message": "Partner is not active",
  "data": {
    "machine_grant_access": false,
    "machine_message": "Partner ist nicht aktiv",
    "status_code": 106
  },
  "error": true
}
```

**Doppelter Check-in (Status Code 107):**
```json
{
  "message": "You cannot checkin in the same partner twice per day",
  "data": {
    "machine_grant_access": false,
    "machine_message": "Doppelter Eintritt",
    "status_code": 107
  },
  "error": true
}
```

## Response Fields

### Core Response Fields

| Feld | Typ | Beschreibung |
|------|-----|--------------|
| `message` | string | Technische Fehlerbeschreibung (EN) |
| `data` | object | Hauptdaten-Container |
| `error` | boolean | true bei Fehlern, false bei Erfolg |

### Data Object Fields

| Feld | Typ | Beschreibung |
|------|-----|--------------|
| `machine_grant_access` | boolean | **Hauptentscheidung:** Tür öffnen (true) oder nicht (false) |
| `machine_message` | string | **Benutzer-Nachricht:** Übersetzt, für Anzeige geeignet |
| `status_code` | integer | **Status Code:** Spezifischer Grund für Entscheidung |
| `user` | object | **Mitgliederdaten:** Nur bei erfolgreichen Responses |

### User Object Fields

| Feld | Typ | Beschreibung |
|------|-----|--------------|
| `id` | integer | Eindeutige Mitglieder-ID |
| `firstname` | string | Vorname |
| `lastname` | string | Nachname |
| `city` | string | Stadt |
| `avatar` | string/null | Profilbild-URL oder null |

## Status Codes Übersicht

| Code | Bedeutung | Action |
|------|-----------|--------|
| 201 | Erfolg | Gemäß `machine_grant_access` handeln |
| 100 | Member existiert nicht | Zutritt verweigern |
| 101 | Partner existiert nicht | Zutritt verweigern |
| 102 | Benutzer nicht aktiv | Zutritt verweigern |
| 103 | Kein Abo | Zutritt verweigern |
| 104 | Abo ungültig | Zutritt verweigern |
| 105 | Abo abgelaufen | Zutritt verweigern |
| 106 | Partner nicht aktiv | Zutritt verweigern |
| 107 | Doppelter Check-in | Zutritt verweigern |

## Besondere Logik

### Re-Entry Logic (3-Stunden-Regel)

Wenn ein Mitglied innerhalb von 3 Stunden nach dem ersten Check-in erneut eintritt:
- `machine_grant_access: true`
- **KEIN** neuer Check-in-Record wird erstellt
- Ermöglicht WC-Pausen etc. ohne Rezeptionsbesuch

### Erstbesuch-Logik

Manche Sportpartner verlangen Rezeptionsbesuch beim ersten Mal:
- `machine_grant_access: false` trotz gültigem Abo
- Spezielle `machine_message` (z.B. "Zum Empfang!")
- Check-in-Record **WIRD** erstellt

## Implementation Example

### Complete JavaScript Implementation

```javascript
const crypto = require('crypto');

class FitpassAPI {
  constructor(secretKey, sportPartner, userId) {
    this.secretKey = secretKey;
    this.sportPartner = sportPartner;
    this.userId = userId;
    this.baseUrl = 'https://rest-fitpass-ch.herokuapp.com/api/partner-user/sport-partners';
  }

  generateSignature(payload) {
    const payloadString = JSON.stringify(payload).replace(/\s/g, '');
    const hmac = crypto.createHmac('sha256', this.secretKey);
    hmac.update(payloadString);
    return hmac.digest('hex').toLowerCase();
  }

  async addCheckin(checkinCode, allowCheckin = true) {
    const payload = {
      current_checkin_code: checkinCode,
      sport_partner: this.sportPartner,
      user_id: this.userId,
      allow_checkin: allowCheckin
    };

    const signature = this.generateSignature(payload);

    try {
      const response = await fetch(`${this.baseUrl}/addcheck-in/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Fitpass-Signature': signature
        },
        body: JSON.stringify(payload)
      });

      const result = await response.json();
      
      return {
        success: response.status === 201,
        statusCode: response.status,
        data: result
      };
    } catch (error) {
      throw new Error(`API Request failed: ${error.message}`);
    }
  }

  processCheckinResult(result) {
    const { data } = result;
    
    return {
      grantAccess: data.machine_grant_access,
      message: data.machine_message,
      user: data.user || null,
      statusCode: data.status_code,
      shouldDisplayUser: !!data.user
    };
  }
}

// Usage Example
async function handleFitpassCheckin(qrCode) {
  const api = new FitpassAPI('your_secret_key', 123, 456);
  
  try {
    // Extract checkin code from QR code
    const checkinCode = extractCheckinCode(qrCode); // Your QR parsing logic
    
    if (!checkinCode.startsWith('FP-')) {
      throw new Error('Invalid Fitpass QR Code');
    }

    const result = await api.addCheckin(checkinCode);
    const processed = api.processCheckinResult(result);

    if (processed.grantAccess) {
      // Open door
      openDoor();
      
      // Display welcome message
      displayMessage(processed.message);
      
      // Show user info if available
      if (processed.shouldDisplayUser) {
        displayUserInfo(processed.user);
      }
    } else {
      // Deny access and show error message
      displayErrorMessage(processed.message);
    }

  } catch (error) {
    console.error('Fitpass checkin failed:', error);
    displayErrorMessage('Technischer Fehler. Bitte an der Rezeption melden.');
  }
}
```

### Multi-Door System Example

```javascript
// Entrance door (no checkin record)
async function handleEntranceDoor(qrCode) {
  const checkinCode = extractCheckinCode(qrCode);
  const result = await api.addCheckin(checkinCode, false); // allow_checkin: false
  
  const processed = api.processCheckinResult(result);
  if (processed.grantAccess) {
    openEntranceDoor();
    displayMessage("Willkommen! Bitte zum Trainingsbereich.");
  } else {
    displayErrorMessage(processed.message);
  }
}

// Training area door (with checkin record) 
async function handleTrainingDoor(qrCode) {
  const checkinCode = extractCheckinCode(qrCode);
  const result = await api.addCheckin(checkinCode); // allow_checkin: true (default)
  
  const processed = api.processCheckinResult(result);
  if (processed.grantAccess) {
    openTrainingDoor();
    displayMessage(processed.message);
    displayUserInfo(processed.user);
  } else {
    displayErrorMessage(processed.message);
  }
}
```

## Support

Bei Fragen oder Support wenden Sie sich an:
- **E-Mail:** waleed.elsayed@fitpass.ch
- **Firma:** Fitpass AG

## Integration Checklist

- [ ] HMAC-Signatur korrekt implementiert
- [ ] QR-Code Parsing für "FP-" Codes
- [ ] Error Handling für alle Status Codes
- [ ] User Interface für Nachrichten
- [ ] Profilbild-Anzeige (falls `avatar` vorhanden)
- [ ] Multi-Door Logic (falls erforderlich)
- [ ] Re-Entry Logic verstanden
- [ ] Secret Key sicher gespeichert
- [ ] Test-Implementierung durchgeführt