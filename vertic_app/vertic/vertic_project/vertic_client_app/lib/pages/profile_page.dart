import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';
import '../main.dart' show WelcomePage, sessionManager, client;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Controller und Formular-State für das Benutzerformular
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  // Status-Nachrichten
  String? _resultMessage;
  String? _errorMessage;

  // Benutzer-Daten
  late AppUser _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    sessionManager.addListener(_onSessionChange);
    _loadUserDataIfSignedIn();
  }

  @override
  void dispose() {
    sessionManager.removeListener(_onSessionChange);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneNumberController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _onSessionChange() {
    setState(() {});
    _loadUserDataIfSignedIn();
  }

  void _loadUserDataIfSignedIn() async {
    if (!sessionManager.isSignedIn ||
        sessionManager.signedInUser?.email == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ UNIFIED AUTH: Verwende neuen Unified Endpoint
      final user = await client.unifiedAuth.getCurrentUserProfile();

      if (user != null) {
        setState(() {
          _user = user;

          // Controller mit den Benutzerdaten befüllen
          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName;
          _emailController.text = user.email ?? '';
          _selectedGender = user.gender?.toLowerCase();
          _addressController.text = user.address ?? '';
          _cityController.text = user.city ?? '';
          _postalCodeController.text = user.postalCode ?? '';
          _phoneNumberController.text = user.phoneNumber ?? '';

          if (user.birthDate != null) {
            _birthDateController.text =
                DateFormat('dd.MM.yyyy').format(user.birthDate!);
          } else {
            _birthDateController.text = '';
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Benutzerprofil nicht gefunden';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // Format TT.MM.JJJJ parsen
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      }
    } catch (e) {
      // Fehler beim Parsen ignorieren
    }

    return null;
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_birthDateController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('de', 'DE'),
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _updateUserProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _resultMessage = null;
        _errorMessage = null;
      });

      try {
        // ✅ UNIFIED AUTH: Verwende neuen updateClientProfile Endpoint
        final updatedUserResult = await client.unifiedAuth.updateClientProfile(
          _firstNameController.text,
          _lastNameController.text,
          null, // parentEmail - nur bei Minderjährigen
          _parseDate(_birthDateController.text),
          _selectedGender,
          _addressController.text,
          _cityController.text,
          _postalCodeController.text,
          _phoneNumberController.text,
        );

        if (updatedUserResult != null) {
          setState(() {
            _resultMessage = 'Profil erfolgreich aktualisiert';
            _user =
                updatedUserResult; // Verwende das zurückgegebene User-Objekt
          });
        } else {
          setState(() {
            _errorMessage = 'Fehler beim Speichern des Profils';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Fehler beim Aktualisieren: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signOut() async {
    try {
      await sessionManager.signOutDevice();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Abmelden: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!sessionManager.isSignedIn) {
      // Wenn nicht eingeloggt, zur Login-Seite zurückkehren
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text('Nicht eingeloggt.'),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Abmelden',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Persönliche Daten
              const Text('Persönliche Daten',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Bitte Vorname eingeben' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nachname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Bitte Nachname eingeben' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // E-Mail kann nicht geändert werden
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Geschlecht',
                  border: OutlineInputBorder(),
                ),
                items: ['männlich', 'weiblich', 'divers'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Geburtsdatum (TT.MM.JJJJ)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true, // Datum nur über DatePicker wählbar
                onTap: () => _selectDate(context),
              ),

              const SizedBox(height: 24),

              // Adresse
              const Text('Adresse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Straße und Hausnummer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'PLZ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Ort',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Telefonnummer',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),

              // Aktionsbuttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateUserProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Profil aktualisieren'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Abmelden Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Abmelden'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status-Anzeige
              if (_resultMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.shade100,
                  width: double.infinity,
                  child: Text(
                    _resultMessage!,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  width: double.infinity,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
