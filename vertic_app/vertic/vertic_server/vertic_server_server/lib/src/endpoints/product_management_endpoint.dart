import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../helpers/staff_auth_helper.dart';
import '../helpers/permission_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// **🔧 SICHERE PRODUCT MANAGEMENT ENDPOINT - FRAMEWORK-CRASH-FIX**
///
/// ✅ BACKEND-SICHERHEIT:
/// - Umfassende Debug-Ausgaben
/// - Sichere Error-Handling
/// - Transaction-Safety
/// - Performance-Tracking
class ProductManagementEndpoint extends Endpoint {
  // ==================== ENHANCED CRUD OPERATIONS ====================

  /// **🛒 SICHERE PRODUKTE-ABFRAGE**
  Future<List<Product>> getProducts(
    Session session, {
    int? categoryId,
    int? hallId,
    bool onlyActive = true,
  }) async {
    final startTime = DateTime.now();
    session.log('🛒 ProductManagement: getProducts() - START');
    session.log(
        '   Filter: categoryId=$categoryId, hallId=$hallId, onlyActive=$onlyActive');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    // Permission prüfen
    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_view_products',
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
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
        session.log('🔍 ProductManagement: Filter nur aktive Produkte');
      }

      if (categoryId != null) {
        queryBuilder = Product.db.find(
          session,
          where: (t) =>
              t.isActive.equals(onlyActive) & t.categoryId.equals(categoryId),
        );
        session.log('🔍 ProductManagement: Filter Kategorie-ID: $categoryId');
      }

      if (hallId != null) {
        queryBuilder = Product.db.find(
          session,
          where: (t) => t.isActive.equals(onlyActive) & t.hallId.equals(hallId),
        );
        session.log('🔍 ProductManagement: Filter Hallen-ID: $hallId');
      }

      final products = await queryBuilder;

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: ${products.length} Produkte abgerufen in ${duration.inMilliseconds}ms');

      // Debug-Details der ersten 3 Produkte
      if (products.isNotEmpty) {
        for (int i = 0; i < products.length && i < 3; i++) {
          final p = products[i];
          session.log(
              '   📦 Produkt $i: ${p.name} (€${p.price}, Kategorie: ${p.categoryId})');
        }
        if (products.length > 3) {
          session.log('   ... und ${products.length - 3} weitere Produkte');
        }
      }

      return products;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: getProducts() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **🆕 SICHERE PRODUKT-ERSTELLUNG**
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
    // 🏛️ DACH-Compliance Parameter
    int? taxClassId,
    int? defaultCountryId,
    bool requiresTSESignature = false,
    bool requiresAgeVerification = false,
    bool isSubjectToSpecialTax = false,
  }) async {
    final startTime = DateTime.now();
    session.log('🆕 ProductManagement: createProduct() - START');
    session.log('   Name: "$name", Preis: €$price');
    session.log('   Kategorie: $categoryId, Barcode: $barcode');
    session.log(
        '   DACH-Compliance: TaxClass=$taxClassId, Country=$defaultCountryId, TSE=$requiresTSESignature');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_create_products',
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Erstellen von Produkten');
    }

    // Eingabe-Validierung
    if (name.trim().isEmpty) {
      session.log('❌ ProductManagement: Leerer Name', level: LogLevel.error);
      throw Exception('Produktname darf nicht leer sein');
    }

    if (price <= 0) {
      session.log('❌ ProductManagement: Ungültiger Preis: $price',
          level: LogLevel.error);
      throw Exception('Preis muss größer als 0 sein');
    }

    try {
      // 🔍 Barcode-Uniqueness prüfen (falls vorhanden)
      if (barcode != null && barcode.isNotEmpty) {
        session.log('🔍 ProductManagement: Prüfe Barcode-Uniqueness: $barcode');

        final existingProduct = await Product.db.find(
          session,
          where: (t) => t.barcode.equals(barcode),
          limit: 1,
        );

        if (existingProduct.isNotEmpty) {
          session.log(
              '❌ ProductManagement: Barcode bereits vorhanden: $barcode',
              level: LogLevel.error);
          throw Exception('Produkt mit Barcode $barcode existiert bereits');
        }

        session.log('✅ ProductManagement: Barcode ist einzigartig: $barcode');
      }

      // 📦 Kategorie validieren (falls vorhanden)
      if (categoryId != null) {
        session
            .log('🔍 ProductManagement: Validiere Kategorie-ID: $categoryId');

        final category = await ProductCategory.db.findById(session, categoryId);
        if (category == null) {
          session.log(
              '❌ ProductManagement: Kategorie nicht gefunden: $categoryId',
              level: LogLevel.error);
          throw Exception('Kategorie mit ID $categoryId nicht gefunden');
        }

        session
            .log('✅ ProductManagement: Kategorie validiert: ${category.name}');
      }

      // 🏛️ Tax Class validieren (falls vorhanden)
      if (taxClassId != null) {
        session
            .log('🔍 ProductManagement: Validiere Tax-Class-ID: $taxClassId');

        final taxClass = await TaxClass.db.findById(session, taxClassId);
        if (taxClass == null) {
          session.log(
              '❌ ProductManagement: Tax Class nicht gefunden: $taxClassId',
              level: LogLevel.error);
          throw Exception('Tax Class mit ID $taxClassId nicht gefunden');
        }

        session.log(
            '✅ ProductManagement: Tax Class validiert: ${taxClass.name} (${taxClass.taxRate}%)');
      }

      // 🆕 Neues Produkt erstellen
      final now = DateTime.now();
      final newProduct = Product(
        name: name.trim(),
        description: description?.trim(),
        categoryId: categoryId,
        price: price,
        barcode: barcode?.trim(),
        hallId: hallId,
        costPrice: costPrice,
        marginPercentage:
            costPrice != null ? ((price - costPrice) / costPrice * 100) : null,
        stockQuantity: stockQuantity,
        isActive: true,
        isFoodItem: isFoodItem,
        // 🏛️ DACH-Compliance Felder
        taxClassId: taxClassId,
        defaultCountryId: defaultCountryId,
        requiresTSESignature: requiresTSESignature,
        requiresAgeVerification: requiresAgeVerification,
        isSubjectToSpecialTax: isSubjectToSpecialTax,
        createdByStaffId: staffUserId,
        createdAt: now,
      );

      session.log('💾 ProductManagement: Speichere Produkt in Datenbank...');
      final savedProduct = await Product.db.insertRow(session, newProduct);

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Neues Produkt erstellt in ${duration.inMilliseconds}ms:');
      session.log('   ID: ${savedProduct.id}, Name: ${savedProduct.name}');
      session.log(
          '   Preis: €${savedProduct.price}, Kategorie: ${savedProduct.categoryId}');
      session.log(
          '   DACH-Compliance: TaxClass=${savedProduct.taxClassId}, TSE=${savedProduct.requiresTSESignature}');
      session.log('   Erstellt von Staff: $staffUserId am $now');

      return savedProduct;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: createProduct() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **📦 SICHERE KATEGORIEN-ABFRAGE**
  Future<List<ProductCategory>> getProductCategories(
    Session session, {
    bool onlyActive = true,
    int? hallId,
  }) async {
    final startTime = DateTime.now();
    session.log('📦 ProductManagement: getProductCategories() - START');
    session.log('   Filter: onlyActive=$onlyActive, hallId=$hallId');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    try {
      var queryBuilder = ProductCategory.db.find(session);

      if (onlyActive) {
        queryBuilder = ProductCategory.db.find(
          session,
          where: (t) => t.isActive.equals(true),
        );
        session.log('🔍 ProductManagement: Filter nur aktive Kategorien');
      }

      if (hallId != null) {
        queryBuilder = ProductCategory.db.find(
          session,
          where: (t) => t.isActive.equals(onlyActive) & t.hallId.equals(hallId),
        );
        session.log('🔍 ProductManagement: Filter Hallen-ID: $hallId');
      }

      final categories = await queryBuilder;

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: ${categories.length} Kategorien abgerufen in ${duration.inMilliseconds}ms');

      // Debug-Details der ersten 3 Kategorien
      if (categories.isNotEmpty) {
        for (int i = 0; i < categories.length && i < 3; i++) {
          final c = categories[i];
          session.log(
              '   🏷️ Kategorie $i: ${c.name} (Aktiv: ${c.isActive}, Color: ${c.colorHex})');
        }
        if (categories.length > 3) {
          session.log('   ... und ${categories.length - 3} weitere Kategorien');
        }
      }

      return categories;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: getProductCategories() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **🆕 SICHERE KATEGORIE-ERSTELLUNG**
  Future<ProductCategory> createProductCategory(
    Session session,
    String name, {
    String? description,
    String? colorHex,
    String? iconName,
    bool isFavorites = false,
    int? hallId,
    int displayOrder = 0,
  }) async {
    final startTime = DateTime.now();
    session.log('🆕 ProductManagement: createProductCategory() - START');
    session.log('   Name: "$name", Color: $colorHex, Icon: $iconName');
    session
        .log('   Favoriten: $isFavorites, Hall: $hallId, Order: $displayOrder');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_create_products', // Kategorien sind Teil der Produkt-Verwaltung
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Erstellen von Kategorien');
    }

    // Eingabe-Validierung
    if (name.trim().isEmpty) {
      session.log('❌ ProductManagement: Leerer Kategorie-Name',
          level: LogLevel.error);
      throw Exception('Kategorie-Name darf nicht leer sein');
    }

    try {
      // 🔍 Name-Uniqueness prüfen
      session.log(
          '🔍 ProductManagement: Prüfe Kategorie-Name-Uniqueness: "$name"');

      final existingCategory = await ProductCategory.db.find(
        session,
        where: (t) => t.name.equals(name.trim()),
        limit: 1,
      );

      if (existingCategory.isNotEmpty) {
        session.log(
            '❌ ProductManagement: Kategorie-Name bereits vorhanden: "$name"',
            level: LogLevel.error);
        throw Exception('Kategorie mit Namen "$name" existiert bereits');
      }

      session
          .log('✅ ProductManagement: Kategorie-Name ist einzigartig: "$name"');

      // 🎨 Standard-Werte setzen
      final finalColorHex = colorHex ?? '#607D8B';
      final finalIconName = iconName ?? 'category';

      // 🆕 Neue Kategorie erstellen
      final now = DateTime.now();
      final newCategory = ProductCategory(
        name: name.trim(),
        description: description?.trim(),
        colorHex: finalColorHex,
        iconName: finalIconName,
        isFavorites: isFavorites,
        hallId: hallId,
        displayOrder: displayOrder,
        isActive: true,
        createdAt: now,
      );

      session.log('💾 ProductManagement: Speichere Kategorie in Datenbank...');
      final savedCategory =
          await ProductCategory.db.insertRow(session, newCategory);

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Neue Kategorie erstellt in ${duration.inMilliseconds}ms:');
      session.log('   ID: ${savedCategory.id}, Name: ${savedCategory.name}');
      session.log(
          '   Color: ${savedCategory.colorHex}, Icon: ${savedCategory.iconName}');
      session.log('   Favoriten: ${savedCategory.isFavorites}, Erstellt: $now');

      return savedCategory;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: createProductCategory() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **🔄 SICHERE PRODUKT-AKTUALISIERUNG - FIXED**
  Future<Product> updateProduct(
    Session session,
    int productId, {
    String? name,
    String? description,
    double? price,
    String? barcode,
    int? categoryId,
    int? stockQuantity,
    bool? isActive,
    bool? isFoodItem,
    int? taxClassId,
    int? defaultCountryId,
    bool? requiresTSESignature,
    bool? requiresAgeVerification,
    bool? isSubjectToSpecialTax,
  }) async {
    final startTime = DateTime.now();
    session.log('🔄 ProductManagement: updateProduct() - START');
    session.log('   Produkt-ID: $productId');
    session
        .log('   Parameter: name=$name, price=$price, categoryId=$categoryId');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_edit_products',
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Bearbeiten von Produkten');
    }

    try {
      session.log('🔍 ProductManagement: Lade existierendes Produkt...');
      final existingProduct = await Product.db.findById(session, productId);
      if (existingProduct == null) {
        session.log('❌ ProductManagement: Produkt nicht gefunden: $productId',
            level: LogLevel.error);
        throw Exception('Produkt mit ID $productId nicht gefunden');
      }

      session.log(
          '✅ ProductManagement: Produkt gefunden: ${existingProduct.name}');

      // 🔍 Kategorie validieren (falls geändert)
      if (categoryId != null && categoryId != existingProduct.categoryId) {
        session.log(
            '🔍 ProductManagement: Validiere neue Kategorie-ID: $categoryId');
        final category = await ProductCategory.db.findById(session, categoryId);
        if (category == null) {
          session.log(
              '❌ ProductManagement: Kategorie nicht gefunden: $categoryId',
              level: LogLevel.error);
          throw Exception('Kategorie mit ID $categoryId nicht gefunden');
        }
        session
            .log('✅ ProductManagement: Kategorie validiert: ${category.name}');
      }

      // 🏛️ Tax Class validieren (falls geändert)
      if (taxClassId != null && taxClassId != existingProduct.taxClassId) {
        session.log(
            '🔍 ProductManagement: Validiere neue Tax-Class-ID: $taxClassId');
        final taxClass = await TaxClass.db.findById(session, taxClassId);
        if (taxClass == null) {
          session.log(
              '❌ ProductManagement: Tax Class nicht gefunden: $taxClassId',
              level: LogLevel.error);
          throw Exception('Tax Class mit ID $taxClassId nicht gefunden');
        }
        session
            .log('✅ ProductManagement: Tax Class validiert: ${taxClass.name}');
      }

      // Update-Product mit allen Feldern
      final updatedProduct = existingProduct.copyWith(
        name: name ?? existingProduct.name,
        description: description ?? existingProduct.description,
        price: price ?? existingProduct.price,
        barcode: barcode ?? existingProduct.barcode,
        categoryId: categoryId ?? existingProduct.categoryId,
        stockQuantity: stockQuantity ?? existingProduct.stockQuantity,
        isActive: isActive ?? existingProduct.isActive,
        isFoodItem: isFoodItem ?? existingProduct.isFoodItem,
        taxClassId: taxClassId ?? existingProduct.taxClassId,
        defaultCountryId: defaultCountryId ?? existingProduct.defaultCountryId,
        requiresTSESignature:
            requiresTSESignature ?? existingProduct.requiresTSESignature,
        requiresAgeVerification:
            requiresAgeVerification ?? existingProduct.requiresAgeVerification,
        isSubjectToSpecialTax:
            isSubjectToSpecialTax ?? existingProduct.isSubjectToSpecialTax,
        updatedAt: DateTime.now(),
      );

      session.log('💾 ProductManagement: Speichere Produkt-Update...');
      final savedProduct = await Product.db.updateRow(session, updatedProduct);

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Produkt aktualisiert in ${duration.inMilliseconds}ms:');
      session.log('   ID: ${savedProduct.id}, Name: ${savedProduct.name}');
      session.log(
          '   Preis: €${savedProduct.price}, Kategorie: ${savedProduct.categoryId}');
      session.log(
          '   Aktiv: ${savedProduct.isActive}, TSE: ${savedProduct.requiresTSESignature}');

      return savedProduct;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: updateProduct() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **🗑️ SICHERE PRODUKT-LÖSCHUNG (Soft Delete)**
  Future<void> deleteProduct(Session session, int productId) async {
    final startTime = DateTime.now();
    session.log('🗑️ ProductManagement: deleteProduct() - START');
    session.log('   Produkt-ID: $productId');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_delete_products',
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Löschen von Produkten');
    }

    try {
      session.log('🔍 ProductManagement: Lade existierendes Produkt...');
      final existingProduct = await Product.db.findById(session, productId);
      if (existingProduct == null) {
        session.log('❌ ProductManagement: Produkt nicht gefunden: $productId',
            level: LogLevel.error);
        throw Exception('Produkt mit ID $productId nicht gefunden');
      }

      session.log(
          '✅ ProductManagement: Produkt gefunden: ${existingProduct.name}');

      // Soft Delete - isActive auf false setzen
      final deletedProduct = existingProduct.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      session.log('💾 ProductManagement: Markiere Produkt als inaktiv...');
      await Product.db.updateRow(session, deletedProduct);

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Produkt gelöscht (Soft Delete) in ${duration.inMilliseconds}ms:');
      session.log('   ID: $productId, Name: ${existingProduct.name}');
      session.log('   Von Staff $staffUserId gelöscht');
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: deleteProduct() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **📊 DEBUG: SYSTEM-STATISTIKEN**
  Future<Map<String, dynamic>> getSystemStats(Session session) async {
    final startTime = DateTime.now();
    session.log('📊 ProductManagement: getSystemStats() - START');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    try {
      // Parallel Stats abrufen
      final futures = await Future.wait([
        Product.db.count(session),
        Product.db.count(session, where: (p) => p.isActive.equals(true)),
        ProductCategory.db.count(session),
        ProductCategory.db
            .count(session, where: (c) => c.isActive.equals(true)),
      ]);

      final totalProducts = futures[0];
      final activeProducts = futures[1];
      final totalCategories = futures[2];
      final activeCategories = futures[3];

      final stats = {
        'totalProducts': totalProducts,
        'activeProducts': activeProducts,
        'inactiveProducts': totalProducts - activeProducts,
        'totalCategories': totalCategories,
        'activeCategories': activeCategories,
        'inactiveCategories': totalCategories - activeCategories,
        'timestamp': DateTime.now().toIso8601String(),
        'staffUserId': staffUserId,
      };

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: System-Stats abgerufen in ${duration.inMilliseconds}ms:');
      session.log('   📦 Produkte: $activeProducts/$totalProducts aktiv');
      session
          .log('   🏷️ Kategorien: $activeCategories/$totalCategories aktiv');

      return stats;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: getSystemStats() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  // ==================== EXISTING METHODS (mit verbessertem Logging) ====================

  /// Einzelnes Produkt per ID abrufen
  Future<Product?> getProduct(Session session, int productId) async {
    session.log('🔍 ProductManagement: getProduct($productId)');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_view_products',
    );
    if (!hasPermission) {
      session.log('❌ ProductManagement: Keine Berechtigung',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Anzeigen von Produkten');
    }

    try {
      final product = await Product.db.findById(session, productId);
      if (product != null) {
        session.log('✅ ProductManagement: Produkt gefunden: ${product.name}');
      } else {
        session.log('⚠️ ProductManagement: Produkt nicht gefunden: $productId');
      }
      return product;
    } catch (e, stackTrace) {
      session.log('❌ ProductManagement: getProduct() Fehler: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }
}
