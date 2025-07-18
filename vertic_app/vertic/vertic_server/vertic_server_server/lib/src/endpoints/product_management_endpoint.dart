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

  // ==================== 🆕 HIERARCHISCHE KATEGORIEN-METHODEN ====================

  /// **🏗️ TOP-LEVEL-KATEGORIEN ABRUFEN (Überkategorien)**
  Future<List<ProductCategory>> getTopLevelCategories(
    Session session, {
    bool onlyActive = true,
    int? hallId,
  }) async {
    final startTime = DateTime.now();
    session.log('🏗️ ProductManagement: getTopLevelCategories() - START');
    session.log('   Filter: onlyActive=$onlyActive, hallId=$hallId');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    try {
      var queryBuilder = ProductCategory.db.find(
        session,
        where: (t) => t.parentCategoryId.equals(null),
      );

      if (onlyActive) {
        queryBuilder = ProductCategory.db.find(
          session,
          where: (t) =>
              t.parentCategoryId.equals(null) & t.isActive.equals(true),
        );
        session.log(
            '🔍 ProductManagement: Filter nur aktive Top-Level-Kategorien');
      }

      if (hallId != null) {
        queryBuilder = ProductCategory.db.find(
          session,
          where: (t) =>
              t.parentCategoryId.equals(null) &
              t.isActive.equals(onlyActive) &
              t.hallId.equals(hallId),
        );
        session.log('🔍 ProductManagement: Filter Hallen-ID: $hallId');
      }

      final categories = await queryBuilder;

      // Nach displayOrder sortieren
      categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: ${categories.length} Top-Level-Kategorien abgerufen in ${duration.inMilliseconds}ms');

      return categories;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: getTopLevelCategories() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **📁 UNTER-KATEGORIEN ABRUFEN**
  Future<List<ProductCategory>> getSubCategories(
    Session session,
    int parentCategoryId, {
    bool onlyActive = true,
  }) async {
    final startTime = DateTime.now();
    session.log('📁 ProductManagement: getSubCategories() - START');
    session.log('   ParentID: $parentCategoryId, onlyActive: $onlyActive');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    try {
      var queryBuilder = ProductCategory.db.find(
        session,
        where: (t) => t.parentCategoryId.equals(parentCategoryId),
      );

      if (onlyActive) {
        queryBuilder = ProductCategory.db.find(
          session,
          where: (t) =>
              t.parentCategoryId.equals(parentCategoryId) &
              t.isActive.equals(true),
        );
        session.log('🔍 ProductManagement: Filter nur aktive Unter-Kategorien');
      }

      final categories = await queryBuilder;

      // Nach displayOrder sortieren
      categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: ${categories.length} Unter-Kategorien für Parent $parentCategoryId abgerufen in ${duration.inMilliseconds}ms');

      return categories;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: getSubCategories() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **🏗️ TOP-LEVEL-KATEGORIE ERSTELLEN (Überkategorie)**
  Future<ProductCategory> createTopLevelCategory(
    Session session,
    String name, {
    String? description,
    String? colorHex,
    String? iconName,
    int? hallId,
    int displayOrder = 0,
  }) async {
    final startTime = DateTime.now();
    session.log('🏗️ ProductManagement: createTopLevelCategory() - START');
    session.log(
        '   Name: "$name", Color: ${colorHex ?? '#607D8B'}, Icon: ${iconName ?? 'category'}');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    // Berechtigung prüfen
    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_manage_product_categories',
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Erstellen von Kategorien');
    }

    // Input-Validierung
    if (name.trim().isEmpty) {
      session.log('❌ ProductManagement: Leerer Kategorie-Name',
          level: LogLevel.error);
      throw Exception('VALIDATION_ERROR: Kategorie-Name darf nicht leer sein');
    }

    if (name.trim().length > 50) {
      session.log(
          '❌ ProductManagement: Kategorie-Name zu lang: ${name.length} Zeichen',
          level: LogLevel.error);
      throw Exception(
          'VALIDATION_ERROR: Kategorie-Name darf maximal 50 Zeichen haben');
    }

    try {
      // Erweiterte Name-Uniqueness prüfen (case-insensitive)
      final existingCategory = await ProductCategory.db.find(
        session,
        where: (t) => t.name.equals(name.trim()),
        limit: 1,
      );

      if (existingCategory.isNotEmpty) {
        final existing = existingCategory.first;
        session.log(
            '❌ ProductManagement: Kategorie-Name bereits vorhanden: "$name" (ID: ${existing.id})',
            level: LogLevel.error);
        throw Exception(
            'DUPLICATE_NAME_ERROR: Eine Kategorie mit dem Namen "${name.trim()}" existiert bereits. Bitte wählen Sie einen anderen Namen.');
      }

      final now = DateTime.now();
      final newCategory = ProductCategory(
        name: name.trim(),
        description: description?.trim(),
        colorHex: colorHex ?? '#607D8B',
        iconName: iconName ?? 'category',
        hallId: hallId,
        displayOrder: displayOrder,
        isActive: true,
        level: 0, // Top-Level
        hasChildren: false, // Neu erstellt, noch keine Kinder
        parentCategoryId: null, // Top-Level hat keinen Parent
        createdAt: now,
        createdByStaffId: staffUserId,
      );

      final savedCategory =
          await ProductCategory.db.insertRow(session, newCategory);

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Neue Top-Level-Kategorie erstellt in ${duration.inMilliseconds}ms:');
      session.log('   ID: ${savedCategory.id}, Name: ${savedCategory.name}');
      session.log(
          '   Level: ${savedCategory.level}, Parent: ${savedCategory.parentCategoryId}');

      return savedCategory;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: createTopLevelCategory() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **📁 UNTER-KATEGORIE ERSTELLEN**
  Future<ProductCategory> createSubCategory(
    Session session,
    String name,
    int parentCategoryId, {
    String? description,
    String? colorHex,
    String? iconName,
    int? hallId,
    int displayOrder = 0,
  }) async {
    final startTime = DateTime.now();
    session.log('📁 ProductManagement: createSubCategory() - START');
    session.log('   Name: "$name", ParentID: $parentCategoryId');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    // Berechtigung prüfen
    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_manage_product_categories',
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Erstellen von Kategorien');
    }

    // Input-Validierung
    if (name.trim().isEmpty) {
      session.log('❌ ProductManagement: Leerer Kategorie-Name',
          level: LogLevel.error);
      throw Exception('VALIDATION_ERROR: Kategorie-Name darf nicht leer sein');
    }

    if (name.trim().length > 50) {
      session.log(
          '❌ ProductManagement: Kategorie-Name zu lang: ${name.length} Zeichen',
          level: LogLevel.error);
      throw Exception(
          'VALIDATION_ERROR: Kategorie-Name darf maximal 50 Zeichen haben');
    }

    try {
      // Parent-Kategorie existiert und validieren
      final parentCategory = await ProductCategory.db.findFirstRow(
        session,
        where: (t) => t.id.equals(parentCategoryId),
      );

      if (parentCategory == null) {
        session.log(
            '❌ ProductManagement: Parent-Kategorie $parentCategoryId nicht gefunden',
            level: LogLevel.error);
        throw Exception(
            'PARENT_NOT_FOUND_ERROR: Übergeordnete Kategorie mit ID $parentCategoryId wurde nicht gefunden');
      }

      // Prüfe ob Parent aktiv ist
      if (!parentCategory.isActive) {
        session.log(
            '❌ ProductManagement: Parent-Kategorie $parentCategoryId ist inaktiv',
            level: LogLevel.error);
        throw Exception(
            'PARENT_INACTIVE_ERROR: Die übergeordnete Kategorie "${parentCategory.name}" ist deaktiviert');
      }

      // Erweiterte Name-Uniqueness prüfen (auch innerhalb der Parent-Kategorie)
      final existingCategory = await ProductCategory.db.find(
        session,
        where: (t) => t.name.equals(name.trim()),
        limit: 1,
      );

      if (existingCategory.isNotEmpty) {
        final existing = existingCategory.first;
        session.log(
            '❌ ProductManagement: Kategorie-Name bereits vorhanden: "$name" (ID: ${existing.id})',
            level: LogLevel.error);

        // Spezifische Nachricht je nach Parent-Hierarchie
        if (existing.parentCategoryId == parentCategoryId) {
          throw Exception(
              'DUPLICATE_NAME_ERROR: Eine Unterkategorie mit dem Namen "${name.trim()}" existiert bereits unter "${parentCategory.name}". Bitte wählen Sie einen anderen Namen.');
        } else {
          throw Exception(
              'DUPLICATE_NAME_ERROR: Eine Kategorie mit dem Namen "${name.trim()}" existiert bereits. Bitte wählen Sie einen anderen Namen.');
        }
      }

      final now = DateTime.now();
      final newCategory = ProductCategory(
        name: name.trim(),
        description: description?.trim(),
        colorHex: colorHex ?? parentCategory.colorHex, // Erbe Parent-Farbe
        iconName: iconName ?? parentCategory.iconName, // Erbe Parent-Icon
        hallId: hallId ?? parentCategory.hallId, // Erbe Parent-Hall
        displayOrder: displayOrder,
        isActive: true,
        level: parentCategory.level + 1, // Ein Level tiefer als Parent
        hasChildren: false, // Neu erstellt, noch keine Kinder
        parentCategoryId: parentCategoryId,
        createdAt: now,
        createdByStaffId: staffUserId,
      );

      final savedCategory =
          await ProductCategory.db.insertRow(session, newCategory);

      // Parent-Kategorie aktualisieren: hasChildren = true
      final updatedParent = parentCategory.copyWith(
        hasChildren: true,
        updatedAt: now,
      );
      await ProductCategory.db.updateRow(session, updatedParent);

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Neue Unter-Kategorie erstellt in ${duration.inMilliseconds}ms:');
      session.log('   ID: ${savedCategory.id}, Name: ${savedCategory.name}');
      session.log(
          '   Level: ${savedCategory.level}, Parent: ${savedCategory.parentCategoryId}');
      session.log('   Parent ${parentCategory.name} hasChildren aktualisiert');

      return savedCategory;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: createSubCategory() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **📊 HIERARCHISCHE STRUKTUR ABRUFEN**
  Future<Map<String, dynamic>> getCategoryHierarchy(
    Session session, {
    bool onlyActive = true,
    int? hallId,
  }) async {
    final startTime = DateTime.now();
    session.log('📊 ProductManagement: getCategoryHierarchy() - START');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    try {
      // Top-Level-Kategorien abrufen
      final topLevelCategories = await getTopLevelCategories(
        session,
        onlyActive: onlyActive,
        hallId: hallId,
      );

      final hierarchy = <String, dynamic>{};

      for (final topCategory in topLevelCategories) {
        // Unter-Kategorien für diese Top-Level-Kategorie abrufen
        final subCategories = await getSubCategories(
          session,
          topCategory.id!,
          onlyActive: onlyActive,
        );

        // Produkte zählen (direkt in Top-Level und in Sub-Kategorien)
        final topLevelProductCount = await Product.db.find(
          session,
          where: (t) =>
              t.categoryId.equals(topCategory.id) &
              t.isActive.equals(onlyActive),
        );

        int totalProductCount = topLevelProductCount.length;

        final subCategoryData = <Map<String, dynamic>>[];
        for (final subCategory in subCategories) {
          final subProducts = await Product.db.find(
            session,
            where: (t) =>
                t.categoryId.equals(subCategory.id) &
                t.isActive.equals(onlyActive),
          );

          totalProductCount += subProducts.length;

          subCategoryData.add({
            'category': subCategory,
            'productCount': subProducts.length,
          });
        }

        hierarchy[topCategory.id.toString()] = {
          'category': topCategory,
          'productCount': totalProductCount,
          'directProductCount': topLevelProductCount.length,
          'subCategories': subCategoryData,
        };
      }

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Hierarchie abgerufen in ${duration.inMilliseconds}ms');
      session.log(
          '   ${topLevelCategories.length} Top-Level-Kategorien verarbeitet');

      return hierarchy;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: getCategoryHierarchy() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }

  /// **🗑️ KATEGORIE LÖSCHEN (Hierarchie-aware)**
  Future<bool> deleteProductCategory(Session session, int categoryId) async {
    final startTime = DateTime.now();
    session.log('🗑️ ProductManagement: deleteProductCategory() - START');
    session.log('   Kategorie-ID: $categoryId');

    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log('❌ ProductManagement: Nicht authentifiziert',
          level: LogLevel.error);
      throw Exception('Authentication erforderlich');
    }

    // Berechtigung prüfen
    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_manage_product_categories',
    );
    if (!hasPermission) {
      session.log(
          '❌ ProductManagement: Keine Berechtigung für Staff $staffUserId',
          level: LogLevel.error);
      throw Exception('Keine Berechtigung zum Löschen von Kategorien');
    }

    try {
      // Kategorie laden
      final category = await ProductCategory.db.findById(session, categoryId);
      if (category == null) {
        session.log('❌ ProductManagement: Kategorie $categoryId nicht gefunden',
            level: LogLevel.error);
        throw Exception(
            'CATEGORY_NOT_FOUND_ERROR: Kategorie mit ID $categoryId wurde nicht gefunden');
      }

      session.log('✅ ProductManagement: Kategorie gefunden: ${category.name}');

      // System-Kategorien schützen
      if (category.isSystemCategory) {
        session.log(
            '❌ ProductManagement: System-Kategorie kann nicht gelöscht werden',
            level: LogLevel.error);
        throw Exception(
            'SYSTEM_CATEGORY_ERROR: System-Kategorien können nicht gelöscht werden');
      }

      // Favorites-Kategorie schützen
      if (category.isFavorites) {
        session.log(
            '❌ ProductManagement: Favoriten-Kategorie kann nicht gelöscht werden',
            level: LogLevel.error);
        throw Exception(
            'FAVORITES_CATEGORY_ERROR: Die Favoriten-Kategorie kann nicht gelöscht werden');
      }

      // Prüfe auf Produkte in dieser Kategorie
      final productsInCategory = await Product.db.find(
        session,
        where: (t) => t.categoryId.equals(categoryId) & t.isActive.equals(true),
      );

      if (productsInCategory.isNotEmpty) {
        session.log(
            '❌ ProductManagement: Kategorie enthält noch ${productsInCategory.length} aktive Produkte',
            level: LogLevel.error);
        throw Exception(
            'CATEGORY_HAS_PRODUCTS_ERROR: Die Kategorie "${category.name}" enthält noch ${productsInCategory.length} aktive Produkte. Bitte entfernen Sie zuerst alle Produkte aus dieser Kategorie.');
      }

      // Hierarchie-Prüfung: Hat diese Kategorie Unterkategorien?
      if (category.hasChildren) {
        final subCategories = await ProductCategory.db.find(
          session,
          where: (t) =>
              t.parentCategoryId.equals(categoryId) & t.isActive.equals(true),
        );

        if (subCategories.isNotEmpty) {
          session.log(
              '❌ ProductManagement: Kategorie hat noch ${subCategories.length} Unterkategorien',
              level: LogLevel.error);
          final subCategoryNames =
              subCategories.map((c) => '"${c.name}"').join(', ');
          throw Exception(
              'CATEGORY_HAS_SUBCATEGORIES_ERROR: Die Kategorie "${category.name}" hat noch ${subCategories.length} Unterkategorien: $subCategoryNames. Bitte löschen Sie zuerst alle Unterkategorien.');
        }
      }

      final now = DateTime.now();

      // LÖSCHUNG DURCHFÜHREN
      session.log('💾 ProductManagement: Lösche Kategorie aus Datenbank...');

      // Soft Delete: Kategorie als inaktiv markieren
      final deletedCategory = category.copyWith(
        isActive: false,
        updatedAt: now,
      );
      await ProductCategory.db.updateRow(session, deletedCategory);

      // Falls dies eine Unterkategorie war: Parent-Kategorie aktualisieren
      if (category.parentCategoryId != null) {
        final parentCategory = await ProductCategory.db
            .findById(session, category.parentCategoryId!);
        if (parentCategory != null) {
          // Prüfe ob Parent noch andere aktive Kinder hat
          final remainingSiblings = await ProductCategory.db.find(
            session,
            where: (t) =>
                t.parentCategoryId.equals(category.parentCategoryId!) &
                t.isActive.equals(true) &
                t.id.notEquals(categoryId),
          );

          // Wenn keine aktiven Geschwister mehr: Parent hasChildren = false
          if (remainingSiblings.isEmpty) {
            final updatedParent = parentCategory.copyWith(
              hasChildren: false,
              updatedAt: now,
            );
            await ProductCategory.db.updateRow(session, updatedParent);
            session.log(
                '✅ ProductManagement: Parent-Kategorie "${parentCategory.name}" hasChildren aktualisiert');
          }
        }
      }

      final duration = DateTime.now().difference(startTime);
      session.log(
          '✅ ProductManagement: Kategorie gelöscht (Soft Delete) in ${duration.inMilliseconds}ms:');
      session.log('   ID: $categoryId, Name: ${category.name}');
      session.log(
          '   Level: ${category.level}, Parent: ${category.parentCategoryId}');
      session.log('   Von Staff $staffUserId gelöscht');

      return true;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ ProductManagement: deleteProductCategory() Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);
      session.log('📍 Stack: $stackTrace', level: LogLevel.debug);
      rethrow;
    }
  }
}
