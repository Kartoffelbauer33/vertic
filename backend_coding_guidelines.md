# Serverpod 2.9 Coding Guidelines & Best Practices

## 📋 Inhaltsverzeichnis
1. [Model-Definition Standards](#model-definition-standards)
2. [Endpoint-Architektur](#endpoint-architektur)
3. [Frontend-Integration](#frontend-integration)
4. [Datenbank & Migrationen](#datenbank--migrationen)
5. [Authentication & Security](#authentication--security)
6. [State Management](#state-management)
7. [Error Handling](#error-handling)
8. [Performance & Optimization](#performance--optimization)

---

## Model-Definition Standards

### ✅ Moderne YAML-Syntax verwenden

```yaml
# ✅ RICHTIG: user.spy.yaml (mit .spy.yaml Extension!)
class: User
table: users
managedMigration: true  # Explizit für Migrations
fields:
  email: String, unique
  firstName: String
  lastName: String
  isActive: bool, default=true  # Default in YAML!
  createdAt: DateTime, createdAt  # Auto-managed
  updatedAt: DateTime?, updatedAt
indexes:
  user_email_idx:
    fields: email
    unique: true
```

### ❌ Veraltete Patterns vermeiden

```yaml
# ❌ FALSCH: Keine Default-Werte im generierten Code setzen!
# ❌ FALSCH: Keine JSON-Strings für komplexe Daten
# ❌ FALSCH: Keine manuellen Timestamp-Updates
```

### 🔗 Relationale Integrität

```yaml
# order.spy.yaml
class: Order
table: orders
fields:
  userId: int, relation(parent=User, onDelete=Restrict)
  user: User?, api  # Für JOINs und Eager Loading
  statusId: int, relation(parent=OrderStatus)
  status: OrderStatus?, api
  items: List<OrderItem>?, api  # One-to-Many
```

### 📊 Enum-Definition

```yaml
# order_status.spy.yaml
enum: OrderStatus
serialized: byName  # IMMER byName verwenden!
default: pending
values:
  - pending
  - processing
  - completed
  - cancelled
```

---

## Endpoint-Architektur

### 🎯 RESTful Endpoint Design

```dart
// ✅ RICHTIG: Klare, fokussierte Endpoints
class ProductEndpoint extends Endpoint {
  // CRUD Operations
  Future<Product> create(Session session, Product product) async {
    // Validation
    if (product.name.isEmpty) {
      throw ValidationException('Product name required');
    }
    
    // Permission Check
    await requirePermission(session, 'product.create');
    
    // Business Logic
    return await Product.db.insertRow(session, product);
  }
  
  // Komplexe Queries mit Streaming
  Stream<Product> searchProducts(
    Session session,
    String query, {
    int? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async* {
    final products = await Product.db.find(
      session,
      where: (t) => t.name.like('%$query%'),
      include: Product.include(
        category: ProductCategory.include(),
        taxClass: TaxClass.include(),
      ),
    );
    
    for (final product in products) {
      yield product;
    }
  }
}
```

### 🔄 WebSocket für Live-Updates

```dart
class LivePOSEndpoint extends Endpoint {
  @override
  Future<void> streamOpened(StreamingSession session) async {
    // Client zu Channel hinzufügen
    session.messages.addListener('pos-updates', (message) {
      sendStreamMessage(session, message);
    });
  }
  
  // Broadcast an alle POS-Terminals
  Future<void> broadcastCartUpdate(
    Session session,
    int hallId,
    CartUpdate update,
  ) async {
    await session.messages.postMessage(
      'pos-updates',
      update,
      channel: 'hall-$hallId',
    );
  }
}
```

---

## Frontend-Integration

### 🏗️ Projekt-Struktur

```
lib/
├── core/
│   ├── client/
│   │   ├── client_manager.dart      # Singleton Client
│   │   └── interceptors/            # Auth, Logging, Retry
│   ├── state/
│   │   ├── app_state.dart           # Global State
│   │   └── providers/               # Feature States
│   └── services/
│       ├── auth_service.dart
│       └── sync_service.dart        # Offline-Sync
├── features/
│   ├── auth/
│   │   ├── models/                  # DTOs
│   │   ├── pages/
│   │   ├── widgets/
│   │   └── state/
│   └── pos/
│       ├── models/
│       ├── pages/
│       ├── widgets/
│       └── state/
└── shared/
    ├── widgets/
    └── utils/
```

### 📡 Smart Client Integration

```dart
// client_manager.dart
class ClientManager {
  static final ClientManager _instance = ClientManager._internal();
  factory ClientManager() => _instance;
  
  late final Client client;
  late final StreamingConnectionManager streaming;
  
  ClientManager._internal();
  
  Future<void> initialize() async {
    client = Client(
      Environment.serverUrl,
      authenticationKeyManager: SecureAuthKeyManager(),
      interceptors: [
        AuthInterceptor(),
        RetryInterceptor(maxRetries: 3),
        LoggingInterceptor(),
      ],
    )..connectivityMonitor = FlutterConnectivityMonitor();
    
    // WebSocket für Live-Updates
    streaming = StreamingConnectionManager(client);
    await streaming.connect();
  }
}
```

### 🔄 State Management mit Riverpod

```dart
// product_state.dart
@riverpod
class ProductNotifier extends _$ProductNotifier {
  @override
  Future<List<Product>> build() async {
    // Auto-fetch bei Initialisierung
    return await _fetchProducts();
  }
  
  Future<List<Product>> _fetchProducts() async {
    final client = ref.read(clientProvider);
    return await client.product.getAllProducts();
  }
  
  Future<void> updateProduct(Product product) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(clientProvider);
      final updated = await client.product.update(product);
      
      // Optimistic Update
      state = AsyncValue.data(
        state.value!.map((p) => p.id == updated.id ? updated : p).toList(),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Verwendung in Widget
class ProductListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productNotifierProvider);
    
    return productsAsync.when(
      data: (products) => ProductGrid(products: products),
      loading: () => const LoadingSpinner(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

---

## Datenbank & Migrationen

### 🔄 Migration-First Development

```bash
# Workflow für Datenbank-Änderungen
1. Model in .spy.yaml ändern
2. serverpod generate
3. serverpod create-migration
4. Review: migrations/TIMESTAMP.sql
5. dart bin/main.dart --apply-migrations
```

### 🗄️ Optimierte Queries

```dart
// ✅ RICHTIG: Eager Loading mit Includes
final orders = await Order.db.find(
  session,
  where: (o) => o.userId.equals(userId),
  include: Order.include(
    user: User.include(),
    items: OrderItem.includeList(
      include: OrderItem.include(
        product: Product.include(),
      ),
    ),
  ),
  orderBy: (o) => o.createdAt,
  orderDescending: true,
  limit: 50,
);

// ✅ RICHTIG: Batch Operations
await session.db.transaction((transaction) async {
  // Alle Operationen in einer Transaktion
  final order = await Order.db.insertRow(session, order);
  
  for (final item in items) {
    item.orderId = order.id!;
    await OrderItem.db.insertRow(session, item);
  }
  
  await Stock.db.updateRow(
    session,
    stock..quantity -= totalQuantity,
  );
});
```

### 📊 Database Indexing Strategy

```yaml
# performance_critical_table.spy.yaml
indexes:
  # Composite Index für häufige Queries
  user_date_status_idx:
    fields: userId, createdAt, status
  
  # Partial Index für Performance
  active_products_idx:
    fields: isActive, categoryId
    where: isActive = true
  
  # Full-Text Search
  product_search_idx:
    fields: name, description
    type: gin
```

---

## Authentication & Security

### 🔐 Unified Auth System

```dart
// auth_service.dart
class AuthService {
  final Client client;
  final SecureStorage storage;
  
  // Token-Refresh mit Retry
  Future<String?> getValidToken() async {
    var token = await storage.read('auth_token');
    
    if (token != null && isTokenExpired(token)) {
      try {
        token = await refreshToken();
      } catch (e) {
        // Fallback zu Login
        await logout();
        return null;
      }
    }
    
    return token;
  }
  
  // Permission-based Access
  Future<bool> hasPermission(String permission) async {
    final user = await getCurrentUser();
    return user?.permissions.contains(permission) ?? false;
  }
}
```

### 🛡️ Endpoint Security

```dart
class SecureEndpoint extends Endpoint {
  // Method-level Permissions
  @RequirePermission('admin.users.read')
  Future<List<User>> getAllUsers(Session session) async {
    // Automatisch geschützt durch Annotation
    return User.db.find(session);
  }
  
  // Row-level Security
  Future<List<Order>> getUserOrders(Session session) async {
    final userId = await requireAuthenticatedUser(session);
    
    return Order.db.find(
      session,
      where: (o) => o.userId.equals(userId),
    );
  }
}
```

---

## State Management

### 🏪 Global State Architecture

```dart
// app_state.dart
@riverpod
class AppState extends _$AppState {
  @override
  AppStateData build() {
    return AppStateData(
      user: null,
      settings: AppSettings.defaults(),
      syncStatus: SyncStatus.idle,
    );
  }
  
  // Centralized State Updates
  void updateUser(User? user) {
    state = state.copyWith(user: user);
    
    // Side Effects
    if (user == null) {
      ref.read(routerProvider).go('/login');
    }
  }
}

// Feature States verbinden
@riverpod
Future<POSState> posState(PosStateRef ref) async {
  final user = ref.watch(appStateProvider.select((s) => s.user));
  
  if (user == null) {
    return POSState.unauthorized();
  }
  
  // Feature-spezifische Daten laden
  final [session, products, customers] = await Future.wait([
    ref.read(clientProvider).pos.getCurrentSession(user.hallId),
    ref.read(productNotifierProvider.future),
    ref.read(customerNotifierProvider.future),
  ]);
  
  return POSState(
    session: session,
    products: products,
    customers: customers,
  );
}
```

---

## Error Handling

### 🚨 Strukturierte Fehlerbehandlung

```dart
// Backend Error Types
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  
  AppException(this.message, {this.code, this.details});
}

class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;
  
  ValidationException(String message, this.fieldErrors)
      : super(message, code: 'VALIDATION_ERROR', details: fieldErrors);
}

// Frontend Error Handling
class ErrorBoundary extends ConsumerWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorListener(
      onError: (error, stackTrace) {
        if (error is ServerpodClientException) {
          if (error.statusCode == 401) {
            ref.read(authServiceProvider).logout();
          } else if (error.statusCode >= 500) {
            showSystemErrorDialog(context, error);
          }
        }
        
        // Error Reporting
        ref.read(crashlyticsProvider).recordError(error, stackTrace);
      },
      child: child,
    );
  }
}
```

---

## Performance & Optimization

### ⚡ Backend Optimization

```dart
// 1. Query Optimization
class OptimizedEndpoint extends Endpoint {
  // Pagination mit Cursor
  Future<PaginatedResult<Product>> getProducts(
    Session session, {
    String? cursor,
    int limit = 20,
  }) async {
    final query = Product.db.find(
      session,
      limit: limit + 1,  // +1 für hasNext Check
    );
    
    if (cursor != null) {
      query.where((p) => p.id.greaterThan(int.parse(cursor)));
    }
    
    final products = await query;
    final hasNext = products.length > limit;
    
    return PaginatedResult(
      items: products.take(limit).toList(),
      nextCursor: hasNext ? products.last.id.toString() : null,
    );
  }
  
  // Caching Strategy
  Future<Product> getProductCached(Session session, int id) async {
    final cacheKey = 'product:$id';
    
    // Try cache first
    final cached = await session.cache.get<Product>(cacheKey);
    if (cached != null) return cached;
    
    // Load and cache
    final product = await Product.db.findById(session, id);
    if (product != null) {
      await session.cache.put(
        cacheKey,
        product,
        lifetime: Duration(minutes: 15),
      );
    }
    
    return product!;
  }
}
```

### 📱 Frontend Optimization

```dart
// 1. Lazy Loading mit Virtualization
class VirtualProductGrid extends StatelessWidget {
  final List<Product> products;
  
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverVirtualGrid(
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              // Lazy load images
              imageBuilder: (url) => CachedNetworkImage(
                imageUrl: url,
                placeholder: (_, __) => Shimmer.loading(),
                memCacheHeight: 200,
                memCacheWidth: 200,
              ),
            );
          },
        ),
      ],
    );
  }
}

// 2. Debounced Search
class SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<SearchBar> {
  final _debouncer = Debouncer(duration: Duration(milliseconds: 300));
  
  void _onSearchChanged(String query) {
    _debouncer.run(() {
      ref.read(searchQueryProvider.notifier).update(query);
    });
  }
}
```

---

## 🎯 Quick Reference Checkliste

### Für jedes neue Feature:

- [ ] Models in `.spy.yaml` definieren
- [ ] `serverpod generate` ausführen
- [ ] Migrations erstellen und reviewen
- [ ] Endpoints mit klaren Methoden
- [ ] Permission-Checks implementieren
- [ ] Frontend State mit Riverpod
- [ ] Error Boundaries einbauen
- [ ] Loading/Error States
- [ ] Optimistic Updates wo sinnvoll
- [ ] WebSocket für Live-Features
- [ ] Unit & Integration Tests

### Anti-Patterns vermeiden:

- ❌ JSON als String in Datenbank
- ❌ Keine Relationen definieren  
- ❌ Client-seitige Joins
- ❌ Synchrone Loops für DB-Calls
- ❌ Fehlende Error-Behandlung
- ❌ Direct State Mutations
- ❌ Hardcoded Werte
- ❌ Fehlende Validierung

### Modern Serverpod nutzen:

- ✅ Streaming für Live-Updates
- ✅ Batch Operations
- ✅ Include für Eager Loading
- ✅ Transactions für Konsistenz
- ✅ Typed Errors
- ✅ Permission System
- ✅ Caching Strategy
- ✅ Monitoring & Logging