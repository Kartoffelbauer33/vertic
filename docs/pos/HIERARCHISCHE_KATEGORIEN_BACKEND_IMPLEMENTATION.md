# Hierarchische Kategorien - Backend Implementation

## Übersicht
Das Backend wurde erfolgreich um hierarchische Kategorie-Funktionen erweitert. Überkategorien (wie "Shop") können nun Unterkategorien (wie "Kleidung", "Schuhe") enthalten.

## 🔄 Datenbank-Schema Änderungen

### ProductCategory Modell Erweiterungen
```yaml
# vertic_server/lib/src/models/product_category.spy.yaml

# 🆕 HIERARCHIE-SUPPORT: Self-Relation für Parent-Child-Beziehung
parentCategory: ProductCategory?, relation(name=category_hierarchy, optional, onDelete=SetNull)
childCategories: List<ProductCategory>?, relation(name=category_hierarchy)

# 🆕 HIERARCHIE-EIGENSCHAFTEN
level: int, default=0          # Hierarchie-Level (0 = Top-Level, 1 = Sub, etc.)
hasChildren: bool, default=false # Hat Unterkategorien (Performance-Optimierung)
```

### Automatisch generierte Felder
- `parentCategoryId: int?` - Wird automatisch von Serverpod injiziert
- `id: int` - Primary Key für Self-Relations

### Indizes für Performance
```yaml
categories_parent_idx:
  fields: parentCategoryId
categories_level_idx:
  fields: level
categories_has_children_idx:
  fields: hasChildren
```

## 🛠️ Backend-Methoden

### 1. Top-Level-Kategorien abrufen
```dart
Future<List<ProductCategory>> getTopLevelCategories(
  Session session, {
  bool onlyActive = true,
  int? hallId,
})
```

**Funktionen:**
- Ruft alle Kategorien ohne Parent ab (`parentCategoryId == null`)
- Filter nach aktiven Kategorien optional
- Hallen-spezifische Filterung
- Automatische Sortierung nach `displayOrder`

**Query-Logik:**
```dart
where: (t) => t.parentCategoryId.equals(null) & t.isActive.equals(true)
```

### 2. Unter-Kategorien abrufen
```dart
Future<List<ProductCategory>> getSubCategories(
  Session session,
  int parentCategoryId, {
  bool onlyActive = true,
})
```

**Funktionen:**
- Ruft alle Kategorien mit bestimmtem Parent ab
- Performance-optimiert für spezifische Parent-ID
- Aktiv/Inaktiv-Filterung möglich

### 3. Top-Level-Kategorie erstellen
```dart
Future<ProductCategory> createTopLevelCategory(
  Session session,
  String name, {
  String? description,
  String? colorHex,
  String? iconName,
  int? hallId,
  int displayOrder = 0,
})
```

**Eigenschaften:**
- `level: 0` (Top-Level)
- `parentCategoryId: null`
- `hasChildren: false` (initial)
- Staff-Berechtigung erforderlich: `can_create_products`

### 4. Unter-Kategorie erstellen
```dart
Future<ProductCategory> createSubCategory(
  Session session,
  String name,
  int parentCategoryId, {
  String? description,
  String? colorHex,
  String? iconName,
  int? hallId,
  int displayOrder = 0,
})
```

**Logik:**
- Validiert Parent-Kategorie existiert
- `level: parentCategory.level + 1`
- Erbt Eigenschaften vom Parent (Farbe, Icon, Hall)
- Aktualisiert Parent: `hasChildren = true`

### 5. Komplette Hierarchie abrufen
```dart
Future<Map<String, dynamic>> getCategoryHierarchy(
  Session session, {
  bool onlyActive = true,
  int? hallId,
})
```

**Rückgabe-Struktur:**
```json
{
  "topCategoryId": {
    "category": ProductCategory,
    "productCount": 15,
    "directProductCount": 3,
    "subCategories": [
      {
        "category": ProductCategory,
        "productCount": 5
      }
    ]
  }
}
```

## 🔐 Sicherheit & Berechtigungen

### Authentication
- Alle Methoden erfordern Staff-Authentication
- `StaffAuthHelper.getAuthenticatedStaffUserId(session)`

### Autorisierung
- **Lesen:** Automatisch erlaubt für authentifizierte Staff
- **Erstellen:** `can_create_products` berechtigung erforderlich
- **Bearbeiten:** `can_edit_products` berechtigung erforderlich
- **Löschen:** `can_delete_products` berechtigung erforderlich

### Datenvalidierung
- Name-Eindeutigkeit wird geprüft
- Parent-Kategorie-Existenz wird validiert
- Leere Namen werden abgelehnt
- SQL-Injection durch Serverpod ORM verhindert

## 📊 Performance-Optimierungen

### Effizienter Query-Aufbau
```dart
// Direkter Parent-Filter für Unter-Kategorien
where: (t) => t.parentCategoryId.equals(parentCategoryId)

// Kombinierte Filter für bessere Performance
where: (t) => 
  t.parentCategoryId.equals(null) & 
  t.isActive.equals(true) &
  t.hallId.equals(hallId)
```

### hasChildren Flag
- Vermeidet unnötige Sub-Queries
- Wird automatisch beim Erstellen von Unterkategorien gesetzt
- Ermöglicht schnelle UI-Entscheidungen (Expand-Buttons)

### Indexierung
- `parentCategoryId` Index für schnelle Hierarchie-Lookups
- `level` Index für Level-basierte Queries
- `hasChildren` Index für UI-Performance

## 🔄 Migration

### Schema-Änderungen
- Neue Felder werden mit Defaults hinzugefügt
- Bestehende Kategorien erhalten `level: 0`
- `parentCategoryId` bleibt `null` für bestehende Daten
- `hasChildren` wird initial auf `false` gesetzt

### Datenintegrität
- Foreign Key Constraints für Self-Relations
- `onDelete: SetNull` verhindert Waisenkategorien
- Transaktionale Sicherheit bei Hierarchie-Änderungen

## 📈 Logging & Monitoring

### Debug-Informationen
```dart
session.log('🏗️ ProductManagement: getTopLevelCategories() - START');
session.log('   Filter: onlyActive=$onlyActive, hallId=$hallId');
session.log('✅ ProductManagement: ${categories.length} Top-Level-Kategorien abgerufen in ${duration.inMilliseconds}ms');
```

### Error-Tracking
- Vollständige Stack-Traces bei Fehlern
- Performance-Monitoring mit Zeitstempel
- Strukturierte Session-Logs für Debugging

## 🧪 Testing

### Empfohlene Tests
1. **Top-Level-Kategorien ohne Parent**
2. **Unter-Kategorien mit korrektem Parent**
3. **Hierarchie-Tiefe-Limits**
4. **Berechtigung-Validierung**
5. **Parent-Kind-Beziehung-Integrität**
6. **Performance bei tiefen Hierarchien**

### Test-Daten Setup
```dart
// Top-Level: "Shop" (Level 0)
final shopCategory = await createTopLevelCategory(session, "Shop");

// Sub-Level: "Kleidung" (Level 1)
final clothingCategory = await createSubCategory(
  session, "Kleidung", shopCategory.id!
);

// Sub-Sub-Level: "T-Shirts" (Level 2)  
final tshirtCategory = await createSubCategory(
  session, "T-Shirts", clothingCategory.id!
);
```

## 🚀 Next Steps

1. **Migration ausführen:** `dart run bin/main.dart --apply-migrations`
2. **Frontend aktualisieren:** Management-Page & POS-System 
3. **Tests implementieren:** Unit & Integration Tests
4. **Performance monitoring:** Produktive Überwachung einrichten

## 📝 Verwendung im Frontend

### Management Page
```dart
// Top-Level-Kategorien laden
final topCategories = await client.productManagement.getTopLevelCategories();

// Unter-Kategorien laden
final subCategories = await client.productManagement.getSubCategories(parentId);

// Neue Überkategorie erstellen
final newTopCategory = await client.productManagement.createTopLevelCategory(
  "Shop", 
  colorHex: "#FF5722", 
  iconName: "shopping_bag"
);
```

### POS System
```dart
// Komplette Hierarchie für Navigation
final hierarchy = await client.productManagement.getCategoryHierarchy();

// Breadcrumb-Navigation implementieren
final currentPath = buildBreadcrumbPath(currentCategory);
```

---

**Status:** ✅ Backend Implementation Abgeschlossen  
**Migration:** 🔄 In Ausführung  
**Frontend Integration:** 📋 Bereit für Aktualisierung 