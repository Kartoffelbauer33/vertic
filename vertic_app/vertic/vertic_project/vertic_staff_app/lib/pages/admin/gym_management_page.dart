import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

class GymManagementPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool, [String?])? onUnsavedChanges;

  const GymManagementPage({
    super.key,
    required this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<GymManagementPage> createState() => _GymManagementPageState();
}

class _GymManagementPageState extends State<GymManagementPage> {
  List<Gym> _gyms = [];
  final List<GymStats> _gymStats = [];
  List<Facility> _facilities = []; // 🏢 FACILITY-LISTE
  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  bool _isVerticLocation = true;
  int? _selectedFacilityId; // 🏢 AUSGEWÄHLTE FACILITY

  @override
  void initState() {
    super.initState();
    _loadGyms();
    _loadGymTicketStats();
    _loadFacilities(); // 🏢 FACILITIES LADEN
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);
      final gyms = await client.gym.getAllGyms();

      setState(() {
        _gyms = gyms;
        _isLoading = false;
      });
    } catch (e) {
      String errorMessage = 'Fehler: $e';

      // Bessere Fehlermeldung für Authentifizierung
      if (e.toString().contains('500') ||
          e.toString().contains('Internal server error') ||
          e.toString().contains('Sie müssen eingeloggt sein')) {
        errorMessage =
            '⚠️ Sie sind nicht eingeloggt!\n\nBitte melden Sie sich erneut an um Gyms zu verwalten.';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGymTicketStats() async {
    try {
      // Temporär deaktiviert - Methode existiert noch nicht im Backend
      setState(() {
        _isLoading = false;
      });
      // TODO: Implementiere getGymTicketStats im Backend
      // final stats = await client.gym.getGymTicketStats();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Statistiken: $e')),
        );
      }
    }
  }

  /// 🏢 NEUE METHODE: FACILITIES LADEN
  Future<void> _loadFacilities() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final facilities = await client.facility.getAllFacilities();

      setState(() {
        _facilities = facilities;
      });

      debugPrint('✅ ${facilities.length} Facilities geladen');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Facilities: $e');
      setState(() {
        _facilities = [];
      });
    }
  }

  /// 🏢 HILFSMETHODE: FACILITY-NAME ERMITTELN
  String _getFacilityName(int facilityId) {
    final facility = _facilities.firstWhere(
      (f) => f.id == facilityId,
      orElse: () => Facility(
        name: 'Unbekannte Facility',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );
    return facility.name;
  }

  void _clearForm() {
    _nameController.clear();
    _shortCodeController.clear();
    _cityController.clear();
    _addressController.clear();
    _descriptionController.clear();
    _isActive = true;
    _isVerticLocation = true;
    _selectedFacilityId = null; // 🏢 FACILITY-AUSWAHL ZURÜCKSETZEN
  }

  void _showCreateGymDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => _buildGymDialog(),
    );
  }

  /// 🏢 NEUE METHODE: FACILITY-DIALOG ANZEIGEN
  void _showCreateFacilityDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final contactEmailController = TextEditingController();
    final contactPhoneController = TextEditingController();
    bool isActive = true;
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.corporate_fare, color: Colors.orange),
                SizedBox(width: 8),
                Text('Neue Facility erstellen'),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Facility-Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        helperText:
                            'z.B. "Zusammenschluss aller Greifbar-Hallen"',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // 👤 KONTAKTPERSON-SEKTION
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Kontaktperson der Facility',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: contactEmailController,
                            decoration: const InputDecoration(
                              labelText: 'E-Mail *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                              helperText: 'Hauptkontakt für diese Facility',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: contactPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefon',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                              helperText: 'Optional: Direktkontakt',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Aktiv'),
                      subtitle: const Text('Facility ist in Betrieb'),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: isCreating
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final contactEmail = contactEmailController.text.trim();

                        // 🔍 VERBESSERTE VALIDIERUNG
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Facility-Name ist erforderlich'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (contactEmail.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kontakt-E-Mail ist erforderlich'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isCreating = true);

                        try {
                          final client =
                              Provider.of<Client>(context, listen: false);
                          final facility = Facility(
                            name: name,
                            description:
                                descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                            address:
                                null, // 🏢 Facility hat keine eigene Adresse
                            city: null, // 🏢 Facility ist überregional
                            postalCode: null,
                            contactEmail: contactEmail,
                            contactPhone:
                                contactPhoneController.text.trim().isEmpty
                                    ? null
                                    : contactPhoneController.text.trim(),
                            isActive: isActive,
                            createdAt: DateTime.now().toUtc(),
                          );

                          final savedFacility =
                              await client.facility.createFacility(facility);

                          if (savedFacility != null) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Facility "${savedFacility.name}" erfolgreich erstellt!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            await _loadFacilities();
                          }
                        } catch (e) {
                          String errorMessage = 'Fehler beim Erstellen: $e';

                          // 🔍 BENUTZERFREUNDLICHE FEHLERMELDUNGEN
                          if (e.toString().contains('bereits')) {
                            errorMessage =
                                'Eine Facility mit diesem Namen existiert bereits. Bitte wählen Sie einen anderen Namen.';
                          } else if (e.toString().contains('eingeloggt')) {
                            errorMessage =
                                '⚠️ Sie sind nicht als SuperUser eingeloggt!\n\nBitte melden Sie sich als SuperUser an.';
                          } else if (e.toString().contains('SuperUser')) {
                            errorMessage =
                                '🚫 Nur SuperUser können Facilities erstellen.\n\nBitte wenden Sie sich an einen Administrator.';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        } finally {
                          setDialogState(() => isCreating = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Erstellen'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditGymDialog(Gym gym) {
    _nameController.text = gym.name;
    _shortCodeController.text = gym.shortCode;
    _cityController.text = gym.city;
    _addressController.text = gym.address ?? '';
    _descriptionController.text = gym.description ?? '';
    _isActive = gym.isActive;
    _isVerticLocation = gym.isVerticLocation ?? true;
    _selectedFacilityId = gym.facilityId; // 🏢 FACILITY-ID SETZEN

    showDialog(
      context: context,
      builder: (context) => _buildGymDialog(gym: gym),
    );
  }

  Widget _buildGymDialog({Gym? gym}) {
    final isEditing = gym != null;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.add,
                color: Colors.teal,
              ),
              const SizedBox(width: 8),
              Text(isEditing ? 'Gym bearbeiten' : 'Neues Gym erstellen'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shortCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Kurzkürzel (2-5 Zeichen) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.short_text),
                      helperText: 'Nur Großbuchstaben, keine Leerzeichen',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 5,
                    onChanged: (value) {
                      // Automatische Formatierung: nur Großbuchstaben, keine Leerzeichen
                      final formatted = value.toUpperCase().replaceAll(' ', '');
                      if (formatted != value) {
                        _shortCodeController.value = TextEditingValue(
                          text: formatted,
                          selection:
                              TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Stadt *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // 🏢 FACILITY-DROPDOWN
                  DropdownButtonFormField<int?>(
                    value: _selectedFacilityId,
                    decoration: const InputDecoration(
                      labelText: 'Übergeordnete Facility',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.corporate_fare),
                      helperText: 'Leer lassen für Vertic Universal',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('🌐 Vertic Universal (keine Facility)'),
                      ),
                      ..._facilities.map((facility) => DropdownMenuItem<int?>(
                            value: facility.id,
                            child: Text(
                                '🏢 ${facility.name}${facility.city != null ? ' - ${facility.city}' : ''}'),
                          )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedFacilityId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Aktiv'),
                          subtitle: const Text('Gym ist in Betrieb'),
                          value: _isActive,
                          onChanged: (value) {
                            setDialogState(() {
                              _isActive = value ?? true;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Vertic Standort'),
                          subtitle: const Text('Gehört zu Vertic'),
                          value: _isVerticLocation,
                          onChanged: (value) {
                            setDialogState(() {
                              _isVerticLocation = value ?? true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: _isCreating ? null : () => _saveGym(gym),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Speichern' : 'Erstellen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGym(Gym? existingGym) async {
    final name = _nameController.text.trim();
    final shortCode = _shortCodeController.text.trim().toUpperCase();
    final city = _cityController.text.trim();

    // Umfassende Validierung
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gym-Name ist erforderlich'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (shortCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurzkürzel ist erforderlich'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (shortCode.length < 2 || shortCode.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurzkürzel muss zwischen 2 und 5 Zeichen lang sein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stadt ist erforderlich'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      final gym = Gym(
        id: existingGym?.id,
        name: name,
        shortCode: shortCode,
        city: city,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        facilityId: _selectedFacilityId, // 🏢 FACILITY-ID HINZUFÜGEN
        isActive: _isActive,
        isVerticLocation: _isVerticLocation,
        createdAt: existingGym?.createdAt ?? DateTime.now().toUtc(),
      );

      final savedGym = existingGym != null
          ? await client.gym.updateGym(gym)
          : await client.gym.createGym(gym);

      if (savedGym != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingGym != null
                ? 'Gym "${savedGym.name}" erfolgreich aktualisiert!'
                : 'Gym "${savedGym.name}" (${savedGym.shortCode}) erfolgreich erstellt!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadGyms();
      }
    } catch (e) {
      String errorMessage = 'Fehler: $e';

      // Bessere Fehlermeldung für Authentifizierung
      if (e.toString().contains('500') ||
          e.toString().contains('Internal server error') ||
          e.toString().contains('Sie müssen eingeloggt sein')) {
        errorMessage =
            '⚠️ Sie sind nicht eingeloggt!\n\nBitte melden Sie sich erneut an um Gyms zu verwalten.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _deleteGym(Gym gym) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Gym löschen'),
          ],
        ),
        content: Text(
          'Möchten Sie das Gym "${gym.name}" wirklich löschen?\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden. '
          'Stellen Sie sicher, dass keine Ticket-Typen mehr mit diesem Gym verknüpft sind.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = Provider.of<Client>(context, listen: false);
      final success = await client.gym.deleteGym(gym.id!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gym erfolgreich gelöscht!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadGyms();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🏗️ HIERARCHISCHE ANSICHT MIT FACILITIES UND GYMS
  Widget _buildHierarchicalView() {
    // Wenn keine Facilities und Gyms vorhanden sind
    if (_facilities.isEmpty && _gyms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Keine Facilities oder Gyms vorhanden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstellen Sie eine neue Facility oder ein Gym mit den + Buttons.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🌐 VERTIC UNIVERSAL SECTION (Gyms ohne Facility)
        _buildVerticsUniversalSection(),

        // 🏢 FACILITIES SECTIONS
        ..._buildFacilitySections(),
      ],
    );
  }

  /// 🌐 VERTIC UNIVERSAL SECTION
  Widget _buildVerticsUniversalSection() {
    final universalGyms = _gyms.where((gym) => gym.facilityId == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.public, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vertic Universal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      '${universalGyms.length} Gym${universalGyms.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Universal Gyms
        if (universalGyms.isNotEmpty)
          ...universalGyms.map((gym) => _buildGymCard(gym, isIndented: true))
        else
          Container(
            margin: const EdgeInsets.only(left: 16, bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Keine Universal-Gyms vorhanden',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  /// 🏢 FACILITY SECTIONS
  List<Widget> _buildFacilitySections() {
    return _facilities.map((facility) {
      final facilityGyms =
          _gyms.where((gym) => gym.facilityId == facility.id).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility Header
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.corporate_fare,
                    color: Colors.orange.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      if (facility.description != null &&
                          facility.description!.isNotEmpty)
                        Text(
                          facility.description!,
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        '${facilityGyms.length} Gym${facilityGyms.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Facility Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: facility.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    facility.isActive ? 'AKTIV' : 'INAKTIV',
                    style: TextStyle(
                      color: facility.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Facility Gyms
          if (facilityGyms.isNotEmpty)
            ...facilityGyms.map((gym) => _buildGymCard(gym, isIndented: true))
          else
            Container(
              margin: const EdgeInsets.only(left: 16, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Keine Gyms in dieser Facility vorhanden',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      );
    }).toList();
  }

  /// 🏋️ GYM CARD
  Widget _buildGymCard(Gym gym, {bool isIndented = false}) {
    final stats = _gymStats.firstWhere(
      (s) => s.gymName == gym.name,
      orElse: () => GymStats(
        gymId: gym.id,
        gymName: gym.name,
        shortCode: gym.shortCode,
        city: gym.city,
        isActive: gym.isActive,
        ticketCount: 0,
        einzeltickets: 0,
        punktekarten: 0,
        zeitkarten: 0,
      ),
    );

    return Container(
      margin: EdgeInsets.only(
        left: isIndented ? 16 : 0,
        bottom: 12,
      ),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: gym.isActive ? Colors.green : Colors.grey,
            child: Icon(
              gym.isActive ? Icons.fitness_center : Icons.block,
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  gym.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: gym.isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  gym.isActive ? 'AKTIV' : 'INAKTIV',
                  style: TextStyle(
                    color: gym.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${gym.shortCode} • ${gym.city}'),
              if (gym.address != null) Text(gym.address!),
              const SizedBox(height: 4),
              Text(
                '${stats.ticketCount} Tickets: '
                '${stats.einzeltickets} Einzel, '
                '${stats.punktekarten} Punkte, '
                '${stats.zeitkarten} Zeit',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditGymDialog(gym);
                  break;
                case 'delete':
                  _deleteGym(gym);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Bearbeiten'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Löschen'),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _showEditGymDialog(gym),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym-Verwaltung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 🏢 FACILITY ERSTELLEN
          FloatingActionButton(
            onPressed: _showCreateFacilityDialog,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            tooltip: 'Neue Facility erstellen',
            heroTag: 'facility',
            child: const Icon(Icons.corporate_fare),
          ),
          const SizedBox(height: 10),
          // 🏋️ GYM ERSTELLEN
          FloatingActionButton(
            onPressed: _showCreateGymDialog,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            tooltip: 'Neues Gym erstellen',
            heroTag: 'gym',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGyms,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    // 🏗️ HIERARCHISCHE STRUKTUR ERSTELLEN
    return RefreshIndicator(
      onRefresh: () async {
        await _loadGyms();
        await _loadGymTicketStats();
        await _loadFacilities(); // 🏢 FACILITIES AUCH AKTUALISIEREN
      },
      child: _buildHierarchicalView(),
    );
  }
}
