# 🚀 VERTIC FREMDANBIETER-INTEGRATION - QUICK START

## 📋 SETUP CHECKLIST

### 1. Database Migration ausführen ✅
```bash
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod create-migration  # Bereits erledigt: 20250623123748409
```

### 2. Dependencies installieren ✅
```bash
dart pub get
```

### 3. Permissions hinzufügen
```sql
-- SQL-Script ausführen:
\i vertic_app/vertic/SQL/ADD_EXTERNAL_PROVIDER_PERMISSIONS.sql
```

### 4. Code generieren ✅
```bash
serverpod generate
```

## 🎯 ERSTE SCHRITTE

### A) Provider konfigurieren (Admin)

```dart
// 1. Fitpass Provider erstellen
final fitpassProvider = ExternalProvider(
  providerName: 'fitpass',
  displayName: 'Fitpass Premium',
  hallId: 1, // Ihre Hall-ID
  isActive: true,
  apiBaseUrl: 'https://rest-fitpass-ch.herokuapp.com',
  apiCredentialsJson: jsonEncode({
    'secret_key': 'your_fitpass_secret_key',
    'user_id': 456,  // Von Fitpass erhalten
  }),
  sportPartnerId: '123',  // Von Fitpass erhalten
  allowReEntry: true,
  reEntryWindowHours: 3,
  createdBy: staffUserId,
  createdAt: DateTime.now().toUtc(),
);

// 2. Provider speichern
await client.externalProvider.configureProvider(fitpassProvider);
```

### B) Check-in testen (Staff-App)

```dart
// 1. QR-Code scannen
String qrCode = 'FP-ABC123XYZ';  // Vom Fitpass-Mitglied

// 2. Check-in verarbeiten
final result = await client.externalProvider.processExternalCheckin(
  qrCode, 
  hallId: 1,
);

// 3. Ergebnis anzeigen
if (result.accessGranted) {
  showSuccessDialog(result.message, result.userName);
  openDoor();
} else {
  showErrorDialog(result.message);
}
```

### C) Mitgliedschaft verknüpfen (Client-App)

```dart
// 1. User scannt Fremdanbieter QR-Code
String qrCode = await scanQRCode();

// 2. Verknüpfungsrequest
final request = ExternalMembershipRequest(
  providerName: 'fitpass',  // Wird automatisch erkannt
  qrCodeData: qrCode,
  notes: 'Verknüpft über App',
);

// 3. Verknüpfung speichern
final response = await client.externalProvider.linkExternalMembership(request);

if (response.success) {
  showSnackBar('Fitpass erfolgreich verknüpft!');
} else {
  showError(response.message);
}
```

## 🔧 ENTWICKLER-APIS

### ExternalProviderEndpoint Methoden

```dart
// ✅ BEREITS IMPLEMENTIERT

// Check-in mit externem QR-Code (Staff-App)
Future<ExternalCheckinResult> processExternalCheckin(
  String qrCodeData, 
  int hallId
);

// Externe Mitgliedschaft verknüpfen (Client-App)  
Future<ExternalMembershipResponse> linkExternalMembership(
  ExternalMembershipRequest request
);

// Provider für Halle laden
Future<List<ExternalProvider>> getHallProviders(int hallId);

// User-Mitgliedschaften laden
Future<List<UserExternalMembership>> getUserMemberships(int userId);

// Provider konfigurieren (Admin)
Future<ExternalProvider> configureProvider(ExternalProvider config);

// Statistiken abrufen (Admin)
Future<List<ExternalProviderStats>> getProviderStats(
  int hallId, 
  DateTime? startDate, 
  DateTime? endDate
);

// Mitgliedschaft entfernen
Future<bool> removeMembership(int membershipId);
```

## 🎨 UI-INTEGRATION BEISPIELE

### Staff-App QR-Scanner erweitern

```dart
class QRScannerPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRScannerWidget(
        onQRCodeScanned: (qrCode) async {
          // Erst prüfen: Interner oder externer QR-Code?
          if (qrCode.startsWith('FP-') || qrCode.contains('BEGIN:VCARD')) {
            // Externer Provider Check-in
            await processExternalCheckin(qrCode);
          } else {
            // Normaler Vertic Check-in
            await processInternalCheckin(qrCode);
          }
        },
      ),
    );
  }
}
```

### Client-App Fremdanbieter-Tab

```dart
class ExternalProvidersTab extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserExternalMembership>>(
      future: client.externalProvider.getUserMemberships(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView(
            children: [
              // Bereits verknüpfte Provider
              ...snapshot.data!.map((membership) => 
                ExternalProviderTile(membership: membership)
              ),
              
              // Neuen Provider hinzufügen
              AddProviderButton(
                onPressed: () => _showAddProviderDialog(),
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## 📊 MONITORING & DEBUGGING

### Logs überprüfen

```bash
# Server-Logs filtern
grep "🔗 External" logs/server.log

# Check-in-Erfolg verfolgen  
grep "accessGranted: true" logs/server.log

# Fehler analysieren
grep "ERROR.*External" logs/server.log
```

### Datenbank-Queries

```sql
-- Aktive Provider pro Halle
SELECT h.name, p.provider_name, p.display_name, p.is_active
FROM external_providers p
JOIN halls h ON p.hall_id = h.id
WHERE p.is_active = true;

-- Check-in-Statistiken heute
SELECT 
    p.provider_name,
    COUNT(*) as checkins_today,
    SUM(CASE WHEN l.access_granted THEN 1 ELSE 0 END) as successful_checkins
FROM external_checkin_logs l
JOIN user_external_memberships m ON l.membership_id = m.id  
JOIN external_providers p ON m.provider_id = p.id
WHERE DATE(l.checkin_at) = CURRENT_DATE
GROUP BY p.provider_name;

-- Mitgliedschaften pro User
SELECT 
    u.email,
    p.provider_name,
    m.external_user_id,
    m.total_checkins,
    m.last_checkin_at
FROM user_external_memberships m
JOIN app_users u ON m.user_id = u.id
JOIN external_providers p ON m.provider_id = p.id  
WHERE m.is_active = true
ORDER BY m.last_checkin_at DESC;
```

## 🐛 TROUBLESHOOTING

### Häufige Fehler

**1. "Provider nicht verfügbar"**
```dart
// Prüfen: Provider für diese Halle konfiguriert?
final providers = await client.externalProvider.getHallProviders(hallId);
print('Verfügbare Provider: ${providers.map((p) => p.providerName)}');
```

**2. "Bereits verknüpft"**  
```sql
-- Prüfen: Welcher User hat diese externe ID?
SELECT u.email, m.external_user_id 
FROM user_external_memberships m
JOIN app_users u ON m.user_id = u.id  
WHERE m.external_user_id = 'FP-ABC123';
```

**3. "API-Fehler"**
```dart
// Credentials prüfen
final provider = await ExternalProvider.db.findById(session, providerId);
print('API URL: ${provider.apiBaseUrl}');
print('Credentials: ${provider.apiCredentialsJson}'); // Nur für Debug!
```

## 🎯 NÄCHSTE SCHRITTE

### Phase 2: Staff-App Integration
1. QR-Scanner in `vertic_project/vertic_staff_app/lib/pages/` erweitern
2. Check-in-UI anpassen für externe Provider
3. Provider-Management-Page erstellen

### Phase 3: Client-App Integration  
1. Fremdanbieter-Tab in `vertic_project/vertic_client_app/lib/pages/` hinzufügen
2. QR-Scanner für Verknüpfung implementieren
3. Status-Anzeigen und Management-UI

### Phase 4: Admin-Features
1. Provider-Konfiguration in Staff-Management-UI
2. Analytics-Dashboard für externe Provider
3. Export-Funktionen für Check-in-Daten

## 📞 SUPPORT

Bei Fragen oder Problemen:
1. 📖 Vollständige Dokumentation: `VERTIC_FREMDANBIETER_INTEGRATION_GUIDE.md`
2. 💾 Datenbank-Schema: Migration `20250623123748409`
3. 🔍 Code-Referenz: `ExternalProviderEndpoint` und Services

---

**🎉 Happy Coding! Das Fremdanbieter-System ist ready-to-use!** 