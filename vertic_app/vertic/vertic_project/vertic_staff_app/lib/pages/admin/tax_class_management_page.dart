import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🏛️ ROBUSTE STEUERKLASSEN-VERWALTUNG (Layout-Fix)**
///
/// **BUG-FIXES:**
/// - Sichere Widget-Lifecycle-Behandlung mit mounted-Checks
/// - Race-Condition-Prevention bei async setState()
/// - Einfache Layout-Struktur ohne komplexe Constraints
/// - Ordentliche Disposal-Behandlung
/// - Fehlerbehandlung für Provider-Exceptions
class TaxClassManagementPage extends StatefulWidget {
  const TaxClassManagementPage({super.key});

  @override
  State<TaxClassManagementPage> createState() => _TaxClassManagementPageState();
}

class _TaxClassManagementPageState extends State<TaxClassManagementPage> {
  List<Country> _countries = [];
  List<TaxClass> _taxClasses = [];
  Country? _selectedCountry;
  bool _isLoading = false;
  String? _errorMessage;

  // **LIFECYCLE-SCHUTZ: Verhindern von setState() nach dispose**
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // **SICHERE INITIALIZATION: PostFrame für stabilen Context**
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _loadDataSafely();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// **SICHERE setState() mit mounted-Check**
  void _setStateSafe(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  /// **SICHERE DATEN-LADUNG mit Exception-Handling**
  Future<void> _loadDataSafely() async {
    if (_isDisposed) return;

    _setStateSafe(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // **PROVIDER-SAFETY-CHECK**
      final clientProvider = Provider.of<Client?>(context, listen: false);
      if (clientProvider == null) {
        throw Exception('Client-Provider nicht verfügbar');
      }

      debugPrint('🔄 Sichere Daten-Ladung gestartet...');

      // Länder laden
      final countries = await clientProvider.taxManagement.getAllCountries();
      if (_isDisposed) return;

      debugPrint('✅ ${countries.length} Länder sicher geladen');

      if (countries.isEmpty) {
        throw Exception('Keine Länder-Daten verfügbar');
      }

      // Standard-Land setzen
      final defaultCountry = countries.firstWhere(
        (c) => c.code == 'DE',
        orElse: () => countries.first,
      );

      _setStateSafe(() {
        _countries = countries;
        _selectedCountry = defaultCountry;
      });

      // Tax Classes laden
      await _loadTaxClassesSafely(defaultCountry.id!);
    } catch (e) {
      debugPrint('❌ Sicherer Lade-Fehler: $e');
      _setStateSafe(() {
        _errorMessage = 'Fehler beim Laden: $e';
      });
    } finally {
      _setStateSafe(() => _isLoading = false);
    }
  }

  /// **SICHERE TAX CLASSES LADUNG**
  Future<void> _loadTaxClassesSafely(int countryId) async {
    if (_isDisposed) return;

    try {
      final clientProvider = Provider.of<Client?>(context, listen: false);
      if (clientProvider == null || _isDisposed) return;

      debugPrint('🔄 Tax Classes für Land-ID: $countryId');

      final taxClasses = await clientProvider.taxManagement
          .getTaxClassesForCountry(countryId);
      if (_isDisposed) return;

      debugPrint('✅ ${taxClasses.length} Tax Classes sicher geladen');

      _setStateSafe(() {
        _taxClasses = taxClasses;
      });
    } catch (e) {
      debugPrint('❌ Tax Classes Fehler: $e');
      _setStateSafe(() {
        _errorMessage = 'Tax Classes Fehler: $e';
      });
    }
  }

  /// **SICHERES BACKEND-SETUP**
  Future<void> _setupCountryDefaultsSafely() async {
    if (_isDisposed) return;

    _setStateSafe(() => _isLoading = true);

    try {
      final clientProvider = Provider.of<Client?>(context, listen: false);
      if (clientProvider == null) {
        throw Exception('Client nicht verfügbar');
      }

      final germanyResult = await clientProvider.taxManagement
          .setupGermanyDefaults();
      if (_isDisposed) return;

      debugPrint('✅ Deutschland Setup: $germanyResult');

      final austriaResult = await clientProvider.taxManagement
          .setupAustriaDefaults();
      if (_isDisposed) return;

      debugPrint('✅ Österreich Setup: $austriaResult');

      // Daten neu laden
      await _loadDataSafely();

      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backend-Setup erfolgreich'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Setup-Fehler: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Setup fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setStateSafe(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // **SAFETY-CHECK: Disposed Widget nicht rendern**
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏛️ Steuerklassen'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDataSafely,
              tooltip: 'Neu laden',
            ),
        ],
      ),
      body: SafeArea(child: _buildSafeBody()),
    );
  }

  /// **SICHERE BODY mit einfacher Layout-Struktur**
  Widget _buildSafeBody() {
    // **LOADING-STATE**
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text('Lade Daten...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // **ERROR-STATE**
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
              const SizedBox(height: 16),
              Text(
                'Verbindungsfehler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadDataSafely,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Neu laden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _setupCountryDefaultsSafely,
                    icon: const Icon(Icons.build),
                    label: const Text('Setup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // **SUCCESS-STATE: Einfache Spalten-Layout**
    return Column(
      children: [
        // **LÄNDER-AUSWAHL (Feste Höhe)**
        Container(
          width: double.infinity,
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(16),
          child: _buildCountrySelector(),
        ),

        // **TAX CLASSES LISTE (Flexible Höhe)**
        Expanded(child: _buildTaxClassList()),
      ],
    );
  }

  /// **EINFACHER LÄNDER-SELECTOR**
  Widget _buildCountrySelector() {
    if (_countries.isEmpty) {
      return const Text(
        'Keine Länder verfügbar',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🌍 Land:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Country>(
          value: _selectedCountry,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          items: _countries.map((country) {
            return DropdownMenuItem(
              value: country,
              child: Text('${country.code} - ${country.displayName}'),
            );
          }).toList(),
          onChanged: (country) async {
            if (country != null && !_isDisposed) {
              _setStateSafe(() => _selectedCountry = country);
              await _loadTaxClassesSafely(country.id!);
            }
          },
        ),
      ],
    );
  }

  /// **EINFACHE TAX CLASS LISTE**
  Widget _buildTaxClassList() {
    if (_taxClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Keine Steuerklassen',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _setupCountryDefaultsSafely,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Setup starten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _taxClasses.length,
      itemBuilder: (context, index) {
        if (index >= _taxClasses.length) return const SizedBox.shrink();
        return _buildTaxClassCard(_taxClasses[index]);
      },
    );
  }

  /// **EINFACHE TAX CLASS CARD**
  Widget _buildTaxClassCard(TaxClass taxClass) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          child: const Icon(Icons.receipt, size: 20),
        ),
        title: Text(
          taxClass.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: taxClass.description?.isNotEmpty == true
            ? Text(taxClass.description!)
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${taxClass.taxRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
