# 🛒 POS Artikel-Management: Umfassende Roadmap

## **📋 Übersicht**

Das Ziel ist die Erweiterung des POS-Systems um ein vollständiges Artikel-Management mit:
- **Scanner-Integration** für Barcode-Erkennung
- **Open Food Facts API** für automatische Produktdaten
- **RBAC-basierte Verwaltung** für verschiedene Benutzerrollen
- **Nahtlose Integration** in das bestehende POS-System

---

## **🎯 Funktionale Anforderungen**

### **1. Artikel-Erfassung**
- ✅ **Hardware Barcode-Scanner Integration (Primär)**
  - Bestehende Scanner-Hardware verwenden (1D + 2D/QR-Codes)
  - Gleiche Scanner-Logik wie im aktuellen POS-System
  - Kamera-basiertes Scannen als Fallback
  - Manuelle Barcode-Eingabe als letzte Alternative

- ✅ **Open Food Facts Integration**
  - Automatische Produktdaten-Abfrage
  - Produktname, Beschreibung, Kategorie
  - Nährwerte, Allergene, Bilder
  - Fallback für unbekannte Produkte

- ✅ **Manuelle Artikel-Erstellung**
  - Eigene Produktdaten eingeben
  - Custom Kategorien
  - Preisgestaltung und Margen

### **2. Artikel-Verwaltung**
- ✅ **CRUD-Operationen** (Create, Read, Update, Delete)
- ✅ **Anpassbare Kategorien-Management**
  - Bestehende Kategorien bearbeiten/löschen
  - Neue Kategorien erstellen
  - Favoriten-Kategorie für wichtigste Artikel
  - Kategorie-Reihenfolge anpassbar
- ✅ **Preisgestaltung und Margen**
- ✅ **Lagerbestand-Tracking**
- ✅ **Artikel-Aktivierung/Deaktivierung**

### **3. Integration ins POS**
- ✅ **Neue Kategorie/Tab "Artikel hinzufügen"**
  - Nur sichtbar mit entsprechenden RBAC-Permissions
  - SuperUser/Admin/FacilityAdmin können Artikel erstellen
  - Normal Staff hat keinen Zugriff
- ✅ **Live-Anzeige neuer Artikel**
- ✅ **Anpassbare Kategorie-Filter**
- ✅ **Favoriten-Kategorie** für häufig verwendete Artikel
- ✅ **Suchfunktion**
- ✅ **Hardware-Scanner Integration** (gleiche Logik wie bestehendes POS)

---

## **🏗️ Technische Architektur**

### **Backend-Erweiterungen**

#### **1. Neue Datenbank-Modelle**
```yaml
# Product Model (erweitert)
Product:
  - id: int (Primary Key)
  - barcode: String? (Optional, für gescannte Artikel)
  - name: String
  - description: String?
  - category: String
  - price: double
  - cost_price: double? (Einkaufspreis)
  - margin_percentage: double?
  - stock_quantity: int?
  - min_stock_threshold: int?
  - is_active: bool
  - is_food_item: bool
  - open_food_facts_id: String? (Referenz zur API)
  - created_by_staff_id: int
  - created_at: DateTime
  - updated_at: DateTime
  - image_url: String?
  
# ProductCategory Model (neue Tabelle)
ProductCategory:
  - id: int (Primary Key)
  - name: String
  - color_hex: String
  - icon_name: String
  - is_active: bool
  - is_favorites: bool (Favoriten-Kategorie markieren)
  - is_system_category: bool (System-Kategorien vs. Custom)
  - sort_order: int
  - created_by_staff_id: int?
  - created_at: DateTime
  - updated_at: DateTime
  
# OpenFoodFactsCache Model (Cache für API-Daten)
OpenFoodFactsCache:
  - barcode: String (Primary Key)
  - cached_data: String (JSON)
  - cached_at: DateTime
  - is_valid: bool
```

#### **2. Neue Backend-Endpoints**
```yaml
# Artikel-Management
POST   /api/products                    # Neuen Artikel erstellen
GET    /api/products                    # Alle Artikel abrufen (mit Filter)
GET    /api/products/{id}               # Einzelnen Artikel abrufen
PUT    /api/products/{id}               # Artikel aktualisieren
DELETE /api/products/{id}               # Artikel löschen

# Barcode & Open Food Facts
POST   /api/products/scan               # Barcode scannen und Daten abrufen
GET    /api/products/barcode/{barcode}  # Artikel per Barcode finden
POST   /api/products/openfoodfacts      # Open Food Facts Daten abrufen

# Kategorien
GET    /api/product-categories          # Alle Kategorien
POST   /api/product-categories          # Neue Kategorie erstellen
PUT    /api/product-categories/{id}     # Kategorie aktualisieren
DELETE /api/product-categories/{id}     # Kategorie löschen

# Lagerbestand
PUT    /api/products/{id}/stock         # Lagerbestand aktualisieren
GET    /api/products/low-stock          # Artikel mit niedrigem Bestand
```

#### **3. Open Food Facts Integration**
```dart
class OpenFoodFactsService {
  static const String baseUrl = 'https://world.openfoodfacts.org/api/v0';
  
  Future<ProductData?> getProductByBarcode(String barcode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/product/$barcode.json'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        return ProductData.fromOpenFoodFacts(data['product']);
      }
    }
    return null;
  }
}

class ProductData {
  final String name;
  final String? description;
  final String? category;
  final String? imageUrl;
  final List<String> allergens;
  final Map<String, dynamic> nutritionFacts;
  
  static ProductData fromOpenFoodFacts(Map<String, dynamic> data) {
    return ProductData(
      name: data['product_name'] ?? 'Unbekanntes Produkt',
      description: data['generic_name'],
      category: data['categories']?.split(',').first.trim(),
      imageUrl: data['image_url'],
      allergens: (data['allergens_tags'] as List?)?.cast<String>() ?? [],
      nutritionFacts: data['nutriments'] ?? {},
    );
  }
}
```

### **Frontend-Erweiterungen**

#### **1. Scanner-Integration**
```dart
# Dependencies in pubspec.yaml (nur für Fallback)
dependencies:
  mobile_scanner: ^3.5.6        # Kamera-basiertes Scannen (Fallback)
  permission_handler: ^11.0.0    # Kamera-Permissions

# Scanner Service - Hardware Scanner First
class ArticleBarcodeScannerService {
  final BackgroundScannerService _hardwareScanner;
  
  // 1. Priorität: Hardware Scanner verwenden
  Future<String?> scanBarcode({bool allowCamera = true}) async {
    // Hardware Scanner ist bereits aktiv
    if (_hardwareScanner.isConnected) {
      // Scanner Input über bestehende Hardware-Logik abwarten
      return _waitForHardwareScanInput();
    }
    
    // 2. Fallback: Kamera Scanner
    if (allowCamera) {
      return _showCameraScannerDialog();
    }
    
    // 3. Letzter Fallback: Manuelle Eingabe
    return _showManualBarcodeInput();
  }
  
  Future<String?> _waitForHardwareScanInput() async {
    // Gleiche Logik wie im bestehenden POS-System
    // Scanner-Events über BackgroundScannerService abonnieren
  }
  
  Future<String?> _showCameraScannerDialog() async {
    // Kamera-Scanner nur als Fallback
    return showDialog<String>(
      context: context,
      builder: (context) => CameraScannerDialog(),
    );
  }
}
```

#### **2. Artikel-Management UI**

**A) POS-Integration (Inline)**
```dart
# Erweiterte POS-Seite mit "+" Button für neue Artikel
Widget _buildProductGrid() {
  return GridView.builder(
    children: [
      // Bestehende Artikel
      ...existingProducts.map((product) => _buildProductCard(product)),
      
      // "+" Button für neue Artikel (nur mit Permission)
      if (hasPermission('can_create_products'))
        _buildAddProductCard(),
    ],
  );
}

Widget _buildAddProductCard() {
  return Card(
    child: InkWell(
      onTap: () => _showAddProductDialog(),
      child: Column(
        children: [
          Icon(Icons.add, size: 32),
          Text('Neuen Artikel\nhinzufügen'),
        ],
      ),
    ),
  );
}
```

**B) Admin-Dashboard Integration**
```dart
# Separate Artikel-Verwaltung im Admin-Bereich
class ProductManagementPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Artikel-Verwaltung')),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildCategoryTabs(),
          Expanded(child: _buildProductList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

#### **3. Artikel-Erstellung Dialog**
```dart
class AddProductDialog extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        child: Column(
          children: [
            // Scanner-Bereich
            Container(
              height: 200,
              child: _buildScannerSection(),
            ),
            
            // Produktdaten-Formular
            Expanded(
              child: _buildProductForm(),
            ),
            
            // Aktions-Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScannerSection() {
    return Column(
      children: [
        if (_isScanning)
          Expanded(child: BarcodeScanner(onBarcodeDetected: _onBarcodeScanned))
        else
          Column(
            children: [
              Icon(Icons.qr_code_scanner, size: 64),
              ElevatedButton(
                onPressed: () => setState(() => _isScanning = true),
                child: Text('Barcode scannen'),
              ),
              TextButton(
                onPressed: () => _showManualBarcodeDialog(),
                child: Text('Barcode manuell eingeben'),
              ),
            ],
          ),
      ],
    );
  }
}
```

---

## **🔐 RBAC-Integration**

### **Neue Permissions**
```yaml
# Artikel-Management Permissions
can_view_products          # Artikel anzeigen
can_create_products        # Neue Artikel erstellen
can_edit_products          # Artikel bearbeiten
can_delete_products        # Artikel löschen
can_manage_categories      # Kategorien verwalten
can_view_stock_levels      # Lagerbestände einsehen
can_edit_stock_levels      # Lagerbestände ändern
can_view_product_analytics # Verkaufsstatistiken
can_scan_barcodes         # Scanner verwenden
```

### **Rollen-Zuordnung**
```yaml
SuperUser:           # Alle Permissions
FacilityAdmin:       # Alle Permissions für ihre Standorte
HallAdmin:           # Begrenzte Permissions
  - can_view_products
  - can_scan_barcodes
  - can_view_stock_levels
  
Staff:               # Minimale Permissions  
  - can_view_products
  - can_scan_barcodes (optional)
```

---

## **📱 UX/UI Konzept**

### **1. POS-Integration (Hauptfokus)**
```
┌─────────────────────────────────────────┐
│ [Hallen-Tickets] [Vertic Universal]     │
│ [Produkte ⭐] [Getränke] [Snacks]       │ 
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ [🍎 Apfel]  [🥤 Cola]   [🍫 Riegel] [+] │
│ [🍌 Banane] [🧃 Saft]   [🍪 Keks]     │
│ [🥕 Karotte][💧 Wasser] [🥜 Nüsse]     │
└─────────────────────────────────────────┘
```

**"+" Button Workflow:**
1. Klick auf "+" → Scanner-Dialog öffnet sich
2. Barcode scannen → Open Food Facts Abfrage
3. Produktdaten anzeigen → Preis/Kategorie anpassen
4. Speichern → Sofort im POS verfügbar

### **2. Admin-Dashboard**
```
Artikel-Verwaltung
┌─────────────────────────────────────────┐
│ [🔍 Suche] [📊 Kategorien] [📈 Reports] │
├─────────────────────────────────────────┤
│ Produktliste:                           │
│ ☑️ Apfel (🍎) - 1.50€ [📝] [🗑️]        │
│ ☑️ Cola (🥤) - 2.00€ [📝] [🗑️]         │  
│ ❌ Riegel (🍫) - 1.80€ [📝] [🗑️]       │
├─────────────────────────────────────────┤
│ [+ Neuen Artikel hinzufügen]            │
└─────────────────────────────────────────┘
```

---

## **🚀 Implementation Roadmap**

### **Phase 1: Foundation (1-2 Wochen)**
1. ✅ **Backend-Modelle erstellen**
   - Product Model erweitern
   - ProductCategory Model
   - Migrations ausführen

2. ✅ **Basis-Endpoints implementieren**
   - CRUD für Products
   - CRUD für Categories
   - RBAC-Integration

3. ✅ **Scanner-Dependencies hinzufügen**
   - mobile_scanner Package
   - Permissions Setup

### **Phase 2: Scanner & API (1-2 Wochen)**
1. ✅ **Open Food Facts Integration**
   - Service-Klasse erstellen
   - Cache-System implementieren
   - Error-Handling

2. ✅ **Scanner-UI entwickeln**
   - Barcode-Scanner Widget
   - Manual Input Fallback
   - Permission Handling

### **Phase 3: POS-Integration (1 Woche)**
1. ✅ **Inline Artikel-Erstellung**
   - "+" Button im Product Grid
   - Scanner-Dialog
   - Sofortige POS-Integration

2. ✅ **UI/UX Optimierung**
   - Product Cards Design
   - Loading States
   - Error Messages

### **Phase 4: Admin-Dashboard (1-2 Wochen)**
1. ✅ **Separate Artikel-Verwaltung**
   - ProductManagementPage
   - Bulk-Operations
   - Advanced Filtering

2. ✅ **Analytics & Reports**
   - Verkaufsstatistiken
   - Lagerbestand-Reports
   - Popular Products

### **Phase 5: Erweiterte Features (Optional)**
1. ✅ **Lagerbestand-Management**
   - Stock Tracking
   - Low Stock Alerts
   - Automatic Reordering

2. ✅ **Advanced Scanner Features**
   - Batch Scanning
   - Custom Barcode Generation
   - Inventory Scanning

---

## **💡 Empfehlungen**

### **Primärer Ansatz: POS-Integration**
**Warum:** 
- ✅ Direkter Workflow ohne Context-Switch
- ✅ Sofortige Verfügbarkeit neuer Artikel
- ✅ Intuitive Bedienung für Staff

**Implementierung:**
1. "+" Button in jeder Produkt-Kategorie
2. Scanner-Dialog mit Open Food Facts
3. Minimale Daten-Eingabe (nur Preis anpassen)
4. Sofort einscannen und verkaufen

### **Sekundärer Ansatz: Admin-Dashboard**
**Warum:**
- ✅ Detaillierte Verwaltung für Admins
- ✅ Bulk-Operations
- ✅ Analytics und Reports

**Integration:**
- RBAC-basierte Navigation
- Separate Management-Seite
- Import/Export Funktionen

### **Hybrid-Lösung (Empfohlen)**
```
Staff/POS:     Schnelles Hinzufügen via Scanner
Admins:        Detaillierte Verwaltung im Dashboard
SuperUser:     Beide Optionen verfügbar
```

---

## **🔧 Technische Überlegungen**

### **Performance**
- **Caching:** Open Food Facts Daten lokal speichern
- **Lazy Loading:** Produktbilder erst bei Bedarf laden
- **Pagination:** Große Produktlisten aufteilen

### **Offline-Support**
- **Local Storage:** Häufig verwendete Produktdaten
- **Sync:** Automatische Synchronisation bei Verbindung
- **Fallback:** Manuelle Eingabe wenn API nicht verfügbar

### **Security**
- **Input Validation:** Alle Benutzereingaben validieren
- **Rate Limiting:** Open Food Facts API-Aufrufe begrenzen
- **Permissions:** Granulare RBAC-Kontrolle

### **Monitoring**
- **API Usage:** Open Food Facts Aufrufe tracken
- **Error Tracking:** Scanner-Fehler und API-Ausfälle
- **Performance Metrics:** Ladezeiten und User Experience

---

## **🎯 Nächste Schritte**

1. **📝 Entscheidung treffen**: POS-Integration vs. Admin-Dashboard vs. Hybrid
2. **🗄️ Backend erweitern**: Product Model und Endpoints implementieren
3. **📱 Scanner testen**: mobile_scanner Package integrieren
4. **🌐 API Setup**: Open Food Facts Service entwickeln
5. **🎨 UI Prototyp**: Scanner-Dialog und Product Cards designen

**Empfehlung:** Mit **POS-Integration** starten für sofortigen Nutzen, später **Admin-Dashboard** für erweiterte Verwaltung hinzufügen. 