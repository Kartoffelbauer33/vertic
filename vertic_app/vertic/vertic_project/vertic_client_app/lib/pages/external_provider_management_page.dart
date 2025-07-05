import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ExternalProviderManagementPage extends StatefulWidget {
  final SessionManager sessionManager;
  final Client client;
  final AppUser user;

  const ExternalProviderManagementPage({
    super.key,
    required this.sessionManager,
    required this.client,
    required this.user,
  });

  @override
  State<ExternalProviderManagementPage> createState() =>
      _ExternalProviderManagementPageState();
}

class _ExternalProviderManagementPageState
    extends State<ExternalProviderManagementPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // Data State
  List<UserExternalMembership> _memberships = [];
  List<ExternalProvider> _availableProviders = [];
  List<ExternalCheckinLog> _checkinHistory = [];

  // UI State
  bool _isLoading = true;
  bool _isLocationEnabled = false;
  int? _detectedHallId;
  String? _detectedHallName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _detectUserLocation(),
      _loadUserMemberships(),
      _loadCheckinHistory(),
    ]);

    setState(() => _isLoading = false);
  }

  /// 🌍 GPS-basierte Hall-Detection
  Future<void> _detectUserLocation() async {
    try {
      // Permission Check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() => _isLocationEnabled = true);

        // GPS Position ermitteln
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 🎯 Hall Detection über Backend mit GPS-Koordinaten
        final detectedGym =
            await widget.client.externalProvider.detectHallByLocation(
          position.latitude,
          position.longitude,
          radiusKm: 10.0, // 10km Radius für Hall-Detection
        );

        if (detectedGym != null) {
          setState(() {
            _detectedHallId = detectedGym.id;
            _detectedHallName = detectedGym.name;
          });

          // Verfügbare Provider für diese Halle laden
          await _loadAvailableProviders(detectedGym.id!);
        }
      }
    } catch (e) {
      debugPrint('GPS Detection Error: $e');
      setState(() => _isLocationEnabled = false);

      // Fallback: User manuell Halle wählen lassen
      await _showHallSelectionDialog();
    }
  }

  Future<void> _loadAvailableProviders(int hallId) async {
    try {
      final providers =
          await widget.client.externalProvider.getHallProviders(hallId);
      setState(() {
        _availableProviders = providers;
      });
    } catch (e) {
      debugPrint('Error loading providers: $e');
    }
  }

  Future<void> _loadUserMemberships() async {
    try {
      final memberships = await widget.client.externalProvider
          .getUserMemberships(widget.user.id!);
      setState(() {
        _memberships = memberships;
      });
    } catch (e) {
      debugPrint('Error loading memberships: $e');
    }
  }

  Future<void> _loadCheckinHistory() async {
    try {
      final history =
          await widget.client.externalProvider.getUserCheckinHistory(
        widget.user.id!,
        50, // limit as positional parameter
      );
      setState(() {
        _checkinHistory = history;
      });
    } catch (e) {
      debugPrint('Error loading checkin history: $e');
    }
  }

  Future<void> _showHallSelectionDialog() async {
    try {
      final allGyms = await widget.client.externalProvider.getAvailableGyms();

      if (!mounted) return;

      final selectedGym = await showDialog<Gym>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gym auswählen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GPS nicht verfügbar. Bitte wählen Sie Ihr Gym:'),
              const SizedBox(height: 16),
              ...allGyms.map((gym) => ListTile(
                    title: Text(gym.name),
                    subtitle: Text(gym.address ?? ''),
                    onTap: () => Navigator.of(context).pop(gym),
                  )),
            ],
          ),
        ),
      );

      if (selectedGym != null) {
        setState(() {
          _detectedHallId = selectedGym.id;
          _detectedHallName = selectedGym.name;
        });
        await _loadAvailableProviders(selectedGym.id!);
      }
    } catch (e) {
      debugPrint('Error showing hall selection: $e');
    }
  }

  Future<void> _linkNewMembership() async {
    if (_detectedHallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wählen Sie zuerst ein Gym aus')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _LinkMembershipDialog(
        client: widget.client,
        userId: widget.user.id!,
        hallId: _detectedHallId!,
        availableProviders: _availableProviders,
        onMembershipLinked: () {
          _loadUserMemberships(); // Refresh
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('External Provider'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.card_membership), text: 'Memberships'),
            Tab(icon: Icon(Icons.qr_code), text: 'QR-Codes'),
            Tab(icon: Icon(Icons.history), text: 'Historie'),
          ],
        ),
        actions: [
          if (_detectedHallId != null)
            IconButton(
              icon: const Icon(Icons.add_card),
              onPressed: _linkNewMembership,
              tooltip: 'Neue Mitgliedschaft verknüpfen',
            ),
        ],
      ),
      body: Column(
        children: [
          // Location Info Card
          if (_detectedHallId != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isLocationEnabled
                        ? Icons.location_on
                        : Icons.location_city,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detectedHallName ?? 'Unbekanntes Gym',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _isLocationEnabled
                              ? 'Per GPS erkannt'
                              : 'Manuell ausgewählt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showHallSelectionDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Ändern'),
                  ),
                ],
              ),
            ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMembershipsTab(),
                _buildQrCodesTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _detectedHallId != null && _availableProviders.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: _linkNewMembership,
                  icon: const Icon(Icons.add),
                  label: const Text('Mitgliedschaft hinzufügen'),
                )
              : null,
    );
  }

  Widget _buildMembershipsTab() {
    if (_memberships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Keine Mitgliedschaften verknüpft',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
                'Verknüpfen Sie Ihre Fitpass oder Friction Mitgliedschaft'),
            const SizedBox(height: 24),
            if (_detectedHallId != null)
              ElevatedButton.icon(
                onPressed: _linkNewMembership,
                icon: const Icon(Icons.add),
                label: const Text('Erste Mitgliedschaft hinzufügen'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _memberships.length,
      itemBuilder: (context, index) {
        final membership = _memberships[index];
        return _buildMembershipCard(membership);
      },
    );
  }

  Widget _buildMembershipCard(UserExternalMembership membership) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getProviderIcon(membership.providerId.toString()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider ID: ${membership.providerId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (membership.membershipEmail != null)
                        Text(
                          membership.membershipEmail!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                _buildMembershipStatusBadge(membership),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.verified, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Verifiziert am ${_formatDate(membership.verifiedAt ?? DateTime.now())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (membership.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                membership.notes!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showMembershipDetails(membership),
                  child: const Text('Details'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _removeMembership(membership),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Entfernen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getProviderIcon(String providerName) {
    switch (providerName.toLowerCase()) {
      case 'fitpass':
        return const Icon(Icons.fitness_center, color: Colors.orange, size: 32);
      case 'friction':
        return const Icon(Icons.sports_gymnastics,
            color: Colors.blue, size: 32);
      default:
        return const Icon(Icons.card_membership, color: Colors.grey, size: 32);
    }
  }

  Widget _buildMembershipStatusBadge(UserExternalMembership membership) {
    final isActive = membership.isActive == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'AKTIV' : 'INAKTIV',
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQrCodesTab() {
    final activeMemberships =
        _memberships.where((m) => m.isActive == true).toList();

    if (activeMemberships.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine aktiven Mitgliedschaften'),
            Text('QR-Codes werden nur für aktive Mitgliedschaften angezeigt'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeMemberships.length,
      itemBuilder: (context, index) {
        final membership = activeMemberships[index];
        return _buildQrCodeCard(membership);
      },
    );
  }

  Widget _buildQrCodeCard(UserExternalMembership membership) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Provider ${membership.providerId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: membership.externalUserId,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${membership.externalUserId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Zeigen Sie diesen QR-Code beim Check-in vor',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_checkinHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine Check-in Historie'),
            Text('Ihre External Provider Check-ins werden hier angezeigt'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checkinHistory.length,
      itemBuilder: (context, index) {
        final checkin = _checkinHistory[index];
        return _buildCheckinHistoryItem(checkin);
      },
    );
  }

  Widget _buildCheckinHistoryItem(ExternalCheckinLog checkin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          checkin.accessGranted ? Icons.check_circle : Icons.error,
          color: checkin.accessGranted ? Colors.green : Colors.red,
        ),
        title: Text('Provider ${checkin.membershipId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDateTime(checkin.checkinAt)),
            if (checkin.isReEntry)
              const Text(
                'Wiedereinlass (3h-Regel)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        trailing: checkin.accessGranted
            ? const Icon(Icons.check, color: Colors.green)
            : const Icon(Icons.close, color: Colors.red),
        onTap: () => _showCheckinDetails(checkin),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showMembershipDetails(UserExternalMembership membership) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mitgliedschaft Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Provider ID', membership.providerId.toString()),
            _buildDetailRow('Externe User ID', membership.externalUserId),
            if (membership.membershipEmail != null)
              _buildDetailRow('E-Mail', membership.membershipEmail!),
            _buildDetailRow(
                'Verifiziert am', _formatDateTime(membership.verifiedAt!)),
            _buildDetailRow(
                'Methode',
                membership.verificationMethod.isNotEmpty
                    ? membership.verificationMethod
                    : 'Unbekannt'),
            if (membership.notes != null)
              _buildDetailRow('Notizen', membership.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCheckinDetails(ExternalCheckinLog checkin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-in Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status',
                checkin.accessGranted ? 'Erfolgreich' : 'Fehlgeschlagen'),
            _buildDetailRow('Zeit', _formatDateTime(checkin.checkinAt)),
            _buildDetailRow('Halle', checkin.hallId.toString()),
            if (checkin.isReEntry) _buildDetailRow('Typ', 'Wiedereinlass'),
            if (checkin.failureReason != null)
              _buildDetailRow('Fehler', checkin.failureReason!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMembership(UserExternalMembership membership) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mitgliedschaft entfernen'),
        content: const Text(
          'Möchten Sie diese Mitgliedschaft wirklich entfernen? '
          'Sie können sie später wieder hinzufügen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.client.externalProvider.removeMembership(membership.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mitgliedschaft entfernt')),
          );
          _loadUserMemberships(); // Refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }
}

// Dialog für das Hinzufügen neuer Mitgliedschaften
class _LinkMembershipDialog extends StatefulWidget {
  final Client client;
  final int userId;
  final int hallId;
  final List<ExternalProvider> availableProviders;
  final VoidCallback onMembershipLinked;

  const _LinkMembershipDialog({
    required this.client,
    required this.userId,
    required this.hallId,
    required this.availableProviders,
    required this.onMembershipLinked,
  });

  @override
  State<_LinkMembershipDialog> createState() => _LinkMembershipDialogState();
}

class _LinkMembershipDialogState extends State<_LinkMembershipDialog> {
  final _qrController = TextEditingController();
  final _notesController = TextEditingController();
  ExternalProvider? _selectedProvider;
  bool _isLinking = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mitgliedschaft hinzufügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provider auswählen:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExternalProvider>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Provider auswählen',
              ),
              items: widget.availableProviders.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Row(
                    children: [
                      _getProviderIcon(provider.providerName),
                      const SizedBox(width: 8),
                      Text(provider.displayName.isNotEmpty
                          ? provider.displayName
                          : provider.providerName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (provider) {
                setState(() => _selectedProvider = provider);
              },
            ),
            const SizedBox(height: 16),
            const Text('QR-Code oder Mitgliedsnummer:'),
            const SizedBox(height: 8),
            TextField(
              controller: _qrController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'FP-123456789 oder BEGIN:VCARD...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Notizen (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'z.B. Premium Mitgliedschaft',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLinking ? null : _linkMembership,
          child: _isLinking
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verknüpfen'),
        ),
      ],
    );
  }

  Widget _getProviderIcon(String providerName) {
    switch (providerName.toLowerCase()) {
      case 'fitpass':
        return const Icon(Icons.fitness_center, color: Colors.orange);
      case 'friction':
        return const Icon(Icons.sports_gymnastics, color: Colors.blue);
      default:
        return const Icon(Icons.card_membership, color: Colors.grey);
    }
  }

  Future<void> _linkMembership() async {
    if (_selectedProvider == null || _qrController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte füllen Sie alle Felder aus')),
        );
      }
      return;
    }

    setState(() => _isLinking = true);

    try {
      final request = ExternalMembershipRequest(
        qrCodeData: _qrController.text.trim(),
        providerName: _selectedProvider!.providerName,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final response =
          await widget.client.externalProvider.linkExternalMembership(request);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
          widget.onMembershipLinked();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
