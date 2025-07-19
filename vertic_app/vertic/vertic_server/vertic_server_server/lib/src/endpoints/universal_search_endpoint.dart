import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../helpers/staff_auth_helper.dart';

/// **🔍 UNIVERSELLE SUCHFUNKTION - MODERNE IMPLEMENTIERUNG**
class UniversalSearchEndpoint extends Endpoint {
  /// **🔍 HAUPT-SUCHFUNKTION**
  Future<SearchResponse> universalSearch(
    Session session,
    SearchRequest request,
  ) async {
    final startTime = DateTime.now();
    session.log('🔍 UniversalSearch: universalSearch() - START');

    try {
      // Authentication (für Staff und Kunden)
      final staffUserId =
          await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      final isStaffUser = staffUserId != null;

      final searchQuery = _sanitizeQuery(request.query);
      if (searchQuery.isEmpty) {
        return SearchResponse(
          results: [],
          totalCount: 0,
          queryTime: 0.0,
          suggestions: [],
        );
      }

      // Parallel Search über alle konfigurierten Entitäten
      final futures = <Future<List<SearchResult>>>[];
      final enabledTypes =
          request.entityTypes ?? ['customer', 'product', 'category'];

      for (final entityType in enabledTypes) {
        switch (entityType) {
          case 'customer':
            if (isStaffUser) {
              futures.add(_searchCustomers(session, searchQuery, request));
            }
            break;
          case 'product':
            futures.add(_searchProducts(session, searchQuery, request));
            break;
          case 'category':
            futures.add(_searchCategories(session, searchQuery, request));
            break;
        }
      }

      // Warte auf alle Suchergebnisse
      final allResults = await Future.wait(futures);
      final combinedResults = <SearchResult>[];

      for (final results in allResults) {
        combinedResults.addAll(results);
      }

      // Sortierung nach Relevanz
      combinedResults
          .sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // Pagination anwenden
      final startIndex = request.offset;
      final endIndex =
          (startIndex + request.limit).clamp(0, combinedResults.length);
      final paginatedResults = combinedResults.sublist(
        startIndex.clamp(0, combinedResults.length),
        endIndex,
      );

      final duration = DateTime.now().difference(startTime);
      final queryTime = duration.inMicroseconds / 1000.0; // ms

      session.log(
          '✅ UniversalSearch: ${combinedResults.length} Ergebnisse in ${queryTime.toStringAsFixed(2)}ms');

      return SearchResponse(
        results: paginatedResults,
        totalCount: combinedResults.length,
        queryTime: queryTime,
        suggestions: [],
      );
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      session.log(
          '❌ UniversalSearch: Fehler nach ${duration.inMilliseconds}ms: $e',
          level: LogLevel.error);

      return SearchResponse(
        results: [],
        totalCount: 0,
        queryTime: duration.inMicroseconds / 1000.0,
        suggestions: [],
      );
    }
  }

  /// **👥 KUNDEN-SUCHE**
  Future<List<SearchResult>> _searchCustomers(
    Session session,
    String query,
    SearchRequest request,
  ) async {
    try {
      // Verwende Serverpod ORM für Kunden-Suche
      final customers = await AppUser.db.find(
        session,
        where: (t) =>
            t.firstName.ilike('%$query%') |
            t.lastName.ilike('%$query%') |
            t.email.ilike('%$query%'),
        limit: request.limit,
      );

      return customers
          .map((customer) => SearchResult(
                entityType: 'customer',
                entityId: customer.id!,
                title: '${customer.firstName ?? ''} ${customer.lastName ?? ''}'
                    .trim(),
                subtitle: customer.email,
                description: customer.phoneNumber,
                relevanceScore: 1.0,
                matchedFields: ['name', 'email', 'phone'],
                category: 'Kunde',
              ))
          .toList();
    } catch (e) {
      session.log('❌ Customer search error: $e', level: LogLevel.warning);
      return [];
    }
  }

  /// **🛒 PRODUKT-SUCHE**
  Future<List<SearchResult>> _searchProducts(
    Session session,
    String query,
    SearchRequest request,
  ) async {
    try {
      // Verwende Serverpod ORM für Produkt-Suche
      final products = await Product.db.find(
        session,
        where: (t) =>
            t.isActive.equals(true) &
            (t.name.ilike('%$query%') | t.description.ilike('%$query%')),
        limit: request.limit,
      );

      return products
          .map((product) => SearchResult(
                entityType: 'product',
                entityId: product.id!,
                title: product.name,
                subtitle: '€${product.price.toStringAsFixed(2)}',
                description: product.description,
                relevanceScore: 1.0,
                matchedFields: ['name', 'description'],
                category: 'Produkt',
              ))
          .toList();
    } catch (e) {
      session.log('❌ Product search error: $e', level: LogLevel.warning);
      return [];
    }
  }

  /// **🏷️ KATEGORIE-SUCHE**
  Future<List<SearchResult>> _searchCategories(
    Session session,
    String query,
    SearchRequest request,
  ) async {
    try {
      // Verwende Serverpod ORM für Kategorie-Suche
      final categories = await ProductCategory.db.find(
        session,
        where: (t) =>
            t.isActive.equals(true) &
            (t.name.ilike('%$query%') | t.description.ilike('%$query%')),
        limit: request.limit,
      );

      return categories
          .map((category) => SearchResult(
                entityType: 'category',
                entityId: category.id!,
                title: category.name,
                subtitle: 'Kategorie',
                description: category.description,
                relevanceScore: 1.0,
                matchedFields: ['name', 'description'],
                category: 'Kategorie',
              ))
          .toList();
    } catch (e) {
      session.log('❌ Category search error: $e', level: LogLevel.warning);
      return [];
    }
  }

  /// **🧹 QUERY SANITIZATION**
  String _sanitizeQuery(String query) {
    return query
        .trim()
        .replaceAll(RegExp(r'[^\w\säöüß-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
