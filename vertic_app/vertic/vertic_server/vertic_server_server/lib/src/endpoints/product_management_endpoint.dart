import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../helpers/staff_auth_helper.dart';
import '../helpers/permission_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Product Management Endpoint für POS Artikel-Verwaltung
class ProductManagementEndpoint extends Endpoint {
  // ==================== BASIC CRUD OPERATIONS ====================

  /// Alle aktiven Produkte abrufen (mit optionaler Kategorie-Filter)
  Future<List<Product>> getProducts(
    Session session, {
    int? categoryId,
    int? hallId,
    bool onlyActive = true,
  }) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    // Permission prüfen
    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_view_products',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Anzeigen von Produkten');
    }

    try {
      // Query-Builder für flexible Filter
      var queryBuilder = Product.db.find(session);

      if (onlyActive) {
        queryBuilder = Product.db.find(
          session,
          where: (t) => t.isActive.equals(true),
        );
      }

      if (categoryId != null) {
        queryBuilder = Product.db.find(
          session,
          where: (t) =>
              t.isActive.equals(onlyActive) & t.categoryId.equals(categoryId),
        );
      }

      if (hallId != null) {
        queryBuilder = Product.db.find(
          session,
          where: (t) => t.isActive.equals(onlyActive) & t.hallId.equals(hallId),
        );
      }

      final products = await queryBuilder;
      session.log('${products.length} Produkte abgerufen');
      return products;
    } catch (e) {
      session.log('Fehler beim Abrufen der Produkte: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Einzelnes Produkt per ID abrufen
  Future<Product?> getProduct(Session session, int productId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_view_products',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Anzeigen von Produkten');
    }

    return await Product.db.findById(session, productId);
  }

  /// Neues Produkt erstellen
  Future<Product> createProduct(
    Session session,
    String name,
    double price, {
    String? description,
    String? barcode,
    int? categoryId,
    int? hallId,
    double? costPrice,
    int? stockQuantity,
    bool isFoodItem = false,
  }) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_create_products',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Erstellen von Produkten');
    }

    try {
      // Prüfe ob Barcode bereits existiert
      if (barcode != null && barcode.isNotEmpty) {
        final existingProduct = await Product.db.find(
          session,
          where: (t) => t.barcode.equals(barcode),
          limit: 1,
        );
        if (existingProduct.isNotEmpty) {
          throw Exception('Produkt mit Barcode $barcode existiert bereits');
        }
      }

      final newProduct = Product(
        name: name,
        description: description,
        categoryId: categoryId,
        price: price,
        barcode: barcode,
        hallId: hallId,
        costPrice: costPrice,
        marginPercentage:
            costPrice != null ? ((price - costPrice) / costPrice * 100) : null,
        stockQuantity: stockQuantity,
        isActive: true,
        isFoodItem: isFoodItem,
        createdByStaffId: staffUserId,
        createdAt: DateTime.now(),
      );

      final savedProduct = await Product.db.insertRow(session, newProduct);
      session.log(
          'Neues Produkt erstellt: ${savedProduct.name} (ID: ${savedProduct.id})');
      return savedProduct;
    } catch (e) {
      session.log('Fehler beim Erstellen des Produkts: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Produkt aktualisieren
  Future<Product> updateProduct(
    Session session,
    int productId,
    Map<String, dynamic> updates,
  ) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_edit_products',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Bearbeiten von Produkten');
    }

    try {
      final existingProduct = await Product.db.findById(session, productId);
      if (existingProduct == null) {
        throw Exception('Produkt mit ID $productId nicht gefunden');
      }

      // Update-Fields setzen
      final updatedProduct = existingProduct.copyWith(
        name: updates['name'] ?? existingProduct.name,
        description: updates['description'] ?? existingProduct.description,
        price: updates['price'] ?? existingProduct.price,
        costPrice: updates['costPrice'] ?? existingProduct.costPrice,
        stockQuantity:
            updates['stockQuantity'] ?? existingProduct.stockQuantity,
        isActive: updates['isActive'] ?? existingProduct.isActive,
        updatedAt: DateTime.now(),
      );

      final savedProduct = await Product.db.updateRow(session, updatedProduct);
      session.log(
          'Produkt aktualisiert: ${savedProduct.name} (ID: ${savedProduct.id})');
      return savedProduct;
    } catch (e) {
      session.log('Fehler beim Aktualisieren des Produkts: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Produkt löschen (Soft Delete - isActive auf false setzen)
  Future<void> deleteProduct(Session session, int productId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_delete_products',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Löschen von Produkten');
    }

    try {
      final product = await Product.db.findById(session, productId);
      if (product == null) {
        throw Exception('Produkt mit ID $productId nicht gefunden');
      }

      // Soft Delete - setze isActive auf false
      final updatedProduct = product.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await Product.db.updateRow(session, updatedProduct);
      session.log('Produkt deaktiviert: ${product.name} (ID: $productId)');
    } catch (e) {
      session.log('Fehler beim Löschen des Produkts: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  // ==================== BARCODE SCANNING ====================

  /// Produkt per Barcode finden
  Future<Product?> getProductByBarcode(Session session, String barcode) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_scan_product_barcodes',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Scannen von Barcodes');
    }

    try {
      final products = await Product.db.find(
        session,
        where: (t) => t.barcode.equals(barcode) & t.isActive.equals(true),
        limit: 1,
      );

      return products.isNotEmpty ? products.first : null;
    } catch (e) {
      session.log('Fehler beim Suchen nach Barcode $barcode: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Barcode scannen und Produktdaten abrufen (mit Open Food Facts Integration)
  Future<BarcodeScanResponse> scanBarcode(
      Session session, String barcode) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_scan_product_barcodes',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Scannen von Barcodes');
    }

    session.log('🔍 Barcode-Scan gestartet für: $barcode');

    try {
      // 1. Zuerst in der lokalen Datenbank suchen
      session.log('📊 Suche in lokaler Datenbank...');
      final existingProduct = await getProductByBarcode(session, barcode);
      if (existingProduct != null) {
        session
            .log('✅ Produkt in lokaler DB gefunden: ${existingProduct.name}');
        return BarcodeScanResponse(
          found: true,
          source: 'local',
          barcode: barcode,
          productId: existingProduct.id,
          productName: existingProduct.name,
          productPrice: existingProduct.price,
        );
      }
      session.log('❌ Produkt nicht in lokaler DB gefunden');

      // 2. Im Open Food Facts Cache suchen
      session.log('🗂️ Suche in Open Food Facts Cache...');
      final cachedData = await _getCachedOpenFoodFactsData(session, barcode);
      if (cachedData != null) {
        session.log('✅ Produkt im Cache gefunden: ${cachedData['name']}');
        return BarcodeScanResponse(
          found: true,
          source: 'cache',
          barcode: barcode,
          openFoodFactsName: cachedData['name'],
          openFoodFactsDescription: cachedData['description'],
          openFoodFactsCategories: cachedData['categories'],
          openFoodFactsImageUrl: cachedData['imageUrl'],
          openFoodFactsBrand: cachedData['brand'],
          openFoodFactsIngredients: cachedData['ingredients'],
          openFoodFactsNutritionGrade: cachedData['nutritionGrade'],
        );
      }
      session.log('❌ Produkt nicht im Cache gefunden');

      // 3. Open Food Facts API abfragen
      session.log('🌐 Abfrage bei Open Food Facts API...');
      final openFoodFactsData = await _queryOpenFoodFacts(session, barcode);
      if (openFoodFactsData != null) {
        session.log(
            '✅ Produkt bei Open Food Facts API gefunden: ${openFoodFactsData['name']}');
        // Cache speichern
        await _cacheOpenFoodFactsData(session, barcode, openFoodFactsData);
        return BarcodeScanResponse(
          found: true,
          source: 'api',
          barcode: barcode,
          openFoodFactsName: openFoodFactsData['name'],
          openFoodFactsDescription: openFoodFactsData['description'],
          openFoodFactsCategories: openFoodFactsData['categories'],
          openFoodFactsImageUrl: openFoodFactsData['imageUrl'],
          openFoodFactsBrand: openFoodFactsData['brand'],
          openFoodFactsIngredients: openFoodFactsData['ingredients'],
          openFoodFactsNutritionGrade: openFoodFactsData['nutritionGrade'],
        );
      }
      session.log('❌ Produkt auch nicht bei Open Food Facts API gefunden');

      // 4. Produkt nicht gefunden
      session.log('🚫 Barcode-Scan abgeschlossen: Produkt nirgends gefunden');
      return BarcodeScanResponse(
        found: false,
        barcode: barcode,
        message: 'Produkt nicht gefunden - kann manuell erstellt werden',
      );
    } catch (e) {
      session.log('Fehler beim Scannen von Barcode $barcode: $e',
          level: LogLevel.error);
      return BarcodeScanResponse(
        found: false,
        barcode: barcode,
        error: e.toString(),
      );
    }
  }

  // ==================== OPEN FOOD FACTS INTEGRATION ====================

  /// Open Food Facts API abfragen
  Future<Map<String, dynamic>?> _queryOpenFoodFacts(
      Session session, String barcode) async {
    try {
      final url =
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

      session.log('🔍 Open Food Facts API-Anfrage: $url');
      final response = await http.get(Uri.parse(url));

      session.log(
          '📡 Open Food Facts API Response: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        session.log('📦 Open Food Facts API Raw Data: ${jsonEncode(data)}');

        if (data['status'] == 1) {
          final product = data['product'];
          session.log(
              '✅ Open Food Facts Produkt gefunden: ${product['product_name'] ?? 'Kein Name'}');

          final result = {
            'name': product['product_name'] ?? 'Unbekanntes Produkt',
            'description': product['generic_name'],
            'categories': product['categories']?.split(',').first.trim(),
            'imageUrl': product['image_url'],
            'brand': product['brands'],
            'ingredients': product['ingredients_text'],
            'nutritionGrade': product['nutrition_grade_fr'],
            'allergens': product['allergens_tags'],
            'rawData': data,
          };

          session.log('🎯 Extrahierte Produktdaten: ${jsonEncode(result)}');
          return result;
        } else {
          session
              .log('⚠️ Open Food Facts: Produkt nicht gefunden (status != 1)');
          session.log('📄 Vollständige API-Antwort: ${jsonEncode(data)}');
        }
      } else {
        session
            .log('❌ Open Food Facts API HTTP-Fehler: ${response.statusCode}');
        session.log('📄 Response Body: ${response.body}');
      }
      return null;
    } catch (e) {
      session.log('💥 Open Food Facts API Exception: $e',
          level: LogLevel.warning);
      return null;
    }
  }

  /// Cached Open Food Facts Daten abrufen
  Future<Map<String, dynamic>?> _getCachedOpenFoodFactsData(
      Session session, String barcode) async {
    try {
      final cached = await OpenFoodFactsCache.db.find(
        session,
        where: (t) => t.barcode.equals(barcode) & t.isValid.equals(true),
        limit: 1,
      );

      if (cached.isNotEmpty) {
        final cacheItem = cached.first;
        // Prüfe Cache-Alter (max. 7 Tage)
        final cacheAge = DateTime.now().difference(cacheItem.cachedAt).inDays;
        if (cacheAge < 7) {
          return jsonDecode(cacheItem.cachedData);
        } else {
          // Cache invalidieren
          await OpenFoodFactsCache.db.updateRow(
            session,
            cacheItem.copyWith(isValid: false),
          );
        }
      }
      return null;
    } catch (e) {
      session.log('Cache-Abfrage Fehler: $e', level: LogLevel.warning);
      return null;
    }
  }

  /// Open Food Facts Daten cachen
  Future<void> _cacheOpenFoodFactsData(
    Session session,
    String barcode,
    Map<String, dynamic> data,
  ) async {
    try {
      final cacheItem = OpenFoodFactsCache(
        barcode: barcode,
        cachedData: jsonEncode(data),
        cachedAt: DateTime.now(),
        isValid: true,
        productFound: true,
        lastApiStatus: 200,
      );

      await OpenFoodFactsCache.db.insertRow(session, cacheItem);
      session.log('Open Food Facts Daten gecacht für Barcode: $barcode');
    } catch (e) {
      session.log('Cache-Speicherung Fehler: $e', level: LogLevel.warning);
    }
  }

  // ==================== PRODUCT CATEGORIES ====================

  /// Alle aktiven Produktkategorien abrufen
  Future<List<ProductCategory>> getProductCategories(Session session,
      {int? hallId}) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      var queryBuilder = ProductCategory.db.find(
        session,
        where: (t) => t.isActive.equals(true),
        orderBy: (t) => t.displayOrder,
      );

      if (hallId != null) {
        queryBuilder = ProductCategory.db.find(
          session,
          where: (t) => t.isActive.equals(true) & t.hallId.equals(hallId),
          orderBy: (t) => t.displayOrder,
        );
      }

      return await queryBuilder;
    } catch (e) {
      session.log('Fehler beim Abrufen der Kategorien: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Neue Produktkategorie erstellen
  Future<ProductCategory> createProductCategory(
    Session session,
    String name, {
    String? description,
    String colorHex = '#607D8B',
    String iconName = 'category',
    int? hallId,
    bool isFavorites = false,
  }) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_manage_product_categories',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung zum Verwalten von Kategorien');
    }

    try {
      // Prüfe ob bereits eine Favoriten-Kategorie existiert
      if (isFavorites) {
        final existingFavorites = await ProductCategory.db.find(
          session,
          where: (t) => t.isFavorites.equals(true),
          limit: 1,
        );
        if (existingFavorites.isNotEmpty) {
          throw Exception('Es kann nur eine Favoriten-Kategorie geben');
        }
      }

      final newCategory = ProductCategory(
        name: name,
        description: description,
        colorHex: colorHex,
        iconName: iconName,
        hallId: hallId,
        isFavorites: isFavorites,
        isSystemCategory: false,
        createdByStaffId: staffUserId,
        createdAt: DateTime.now(),
      );

      final savedCategory =
          await ProductCategory.db.insertRow(session, newCategory);
      session.log('Neue Kategorie erstellt: ${savedCategory.name}');
      return savedCategory;
    } catch (e) {
      session.log('Fehler beim Erstellen der Kategorie: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  // ==================== FAVORITES MANAGEMENT ====================

  /// Produkt zur Favoriten-Kategorie hinzufügen
  Future<Product> addToFavorites(Session session, int productId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_access_favorites_category',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung für Favoriten-Verwaltung');
    }

    try {
      // Favoriten-Kategorie finden
      final favoritesCategory = await ProductCategory.db.find(
        session,
        where: (t) => t.isFavorites.equals(true),
        limit: 1,
      );

      if (favoritesCategory.isEmpty) {
        throw Exception('Favoriten-Kategorie nicht gefunden');
      }

      final product = await Product.db.findById(session, productId);
      if (product == null) {
        throw Exception('Produkt nicht gefunden');
      }

      final updatedProduct = product.copyWith(
        categoryId: favoritesCategory.first.id,
        updatedAt: DateTime.now(),
      );

      return await Product.db.updateRow(session, updatedProduct);
    } catch (e) {
      session.log('Fehler beim Hinzufügen zu Favoriten: $e',
          level: LogLevel.error);
      rethrow;
    }
  }
}
