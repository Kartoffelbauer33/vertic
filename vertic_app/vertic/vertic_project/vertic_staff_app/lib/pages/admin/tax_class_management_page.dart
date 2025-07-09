import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../auth/permission_provider.dart';

/// **🏛️ VEREINFACHTE STEUERKLASSEN-VERWALTUNG (Layout-Fix)**
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      debugPrint('🔄 Lade Länder vom Backend...');
      _countries = await client.taxManagement.getAllCountries();
      debugPrint('✅ ${_countries.length} Länder geladen');

      if (_countries.isEmpty) {
        throw Exception(
          'Keine Länder-Daten verfügbar. Backend-Setup erforderlich.',
        );
      }

      _selectedCountry = _countries.firstWhere(
        (c) => c.code == 'DE',
        orElse: () => _countries.first,
      );

      await _loadTaxClassesForCountry(_selectedCountry!.id!);
    } catch (e) {
      debugPrint('❌ Backend-Fehler: $e');
      setState(() {
        _errorMessage = 'Backend-Verbindung fehlgeschlagen: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTaxClassesForCountry(int countryId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      debugPrint('🔄 Lade Tax Classes für Land-ID: $countryId');

      _taxClasses = await client.taxManagement.getTaxClassesForCountry(
        countryId,
      );
      debugPrint('✅ ${_taxClasses.length} Tax Classes geladen');

      setState(() {});
    } catch (e) {
      debugPrint('❌ Tax Classes Backend-Fehler: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Steuerklassen: $e';
      });
    }
  }

  /// **Backend-Setup ausführen**
  Future<void> _setupCountryDefaults() async {
    try {
      setState(() => _isLoading = true);
      final client = Provider.of<Client>(context, listen: false);

      final germanyResult = await client.taxManagement.setupGermanyDefaults();
      debugPrint('✅ Deutschland Setup: $germanyResult');

      final austriaResult = await client.taxManagement.setupAustriaDefaults();
      debugPrint('✅ Österreich Setup: $austriaResult');

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backend-Setup erfolgreich ausgeführt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Setup-Fehler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Setup fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('��️ DACH-Compliance & Steuerklassen'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Neu laden',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Lade Steuerklassen-Daten...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 48),
              const SizedBox(height: 16),
              Text(
                'Backend-Verbindungsfehler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _setupCountryDefaults,
                    icon: const Icon(Icons.build),
                    label: const Text('Setup ausführen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildCountrySelector(),
        Expanded(child: _buildTaxClassList()),
      ],
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌍 Land auswählen:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Country>(
            value: _selectedCountry,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _countries
                .map(
                  (country) => DropdownMenuItem(
                    value: country,
                    child: Text('${country.code} - ${country.displayName}'),
                  ),
                )
                .toList(),
            onChanged: (country) async {
              if (country != null) {
                setState(() => _selectedCountry = country);
                await _loadTaxClassesForCountry(country.id!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaxClassList() {
    if (_taxClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Keine Steuerklassen verfügbar',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _setupCountryDefaults,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Standard-Setup durchführen'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _taxClasses.length,
      itemBuilder: (context, index) {
        final taxClass = _taxClasses[index];
        return _buildSimpleTaxClassCard(taxClass);
      },
    );
  }

  Widget _buildSimpleTaxClassCard(TaxClass taxClass) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          taxClass.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(taxClass.description ?? ''),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${taxClass.taxRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
