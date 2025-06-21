import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Für Zugriff auf client und sessionManager
import 'main_tab_controller.dart'; // Für Navigation nach Registrierung

class ChildRegistrationPage extends StatefulWidget {
  final String parentFirstName;
  final String parentLastName;
  final String parentEmail;
  final String parentGender;
  final String parentAddress;
  final String parentCity;
  final String parentPostalCode;
  final String parentPhoneNumber;

  const ChildRegistrationPage({
    super.key,
    required this.parentFirstName,
    required this.parentLastName,
    required this.parentEmail,
    required this.parentGender,
    required this.parentAddress,
    required this.parentCity,
    required this.parentPostalCode,
    required this.parentPhoneNumber,
  });

  @override
  State<ChildRegistrationPage> createState() => _ChildRegistrationPageState();
}

class _ChildRegistrationPageState extends State<ChildRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Nur änderbare Felder für Kinder
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _selectedGender;

  // Optionale überschreibbare Felder
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fülle Parent-Daten vor
    _addressController.text = widget.parentAddress;
    _cityController.text = widget.parentCity;
    _postalCodeController.text = widget.parentPostalCode;
    _phoneNumberController.text = widget.parentPhoneNumber;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          if (year > 1900 &&
              year < 2100 &&
              month >= 1 &&
              month <= 12 &&
              day >= 1 &&
              day <= 31) {
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
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365 * 10)), // Standard: 10 Jahre alt
      firstDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // Max 18 Jahre
      lastDate: DateTime.now(),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);

        // Validierung: Muss unter 18 sein
        final age = DateTime.now().difference(picked).inDays / 365.25;
        if (age >= 18) {
          _showAgeErrorDialog();
          _birthDateController.clear();
        }
      });
    }
  }

  void _showAgeErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ungültiges Alter'),
          content: const Text(
            'Familienmitglieder müssen unter 18 Jahre alt sein.\n\n'
            'Für Personen über 18 Jahren ist eine separate Registrierung erforderlich.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _addChild() async {
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      final firstName = _firstNameController.text;
      final lastName = _lastNameController.text;
      final birthDate = _parseDate(_birthDateController.text);
      final gender = _selectedGender;

      if (birthDate == null) {
        setState(() {
          _errorMessage = 'Bitte gültiges Geburtsdatum eingeben.';
        });
        return;
      }

      if (gender == null) {
        setState(() {
          _errorMessage = 'Bitte Geschlecht auswählen.';
        });
        return;
      }

      try {
        // Hole Parent-User-ID über Email
        final parentProfile =
            await client.userProfile.getUserProfile(widget.parentEmail);
        if (parentProfile == null) {
          setState(() {
            _errorMessage =
                'Parent-Profil nicht gefunden. Bitte erneut versuchen.';
          });
          return;
        }

        // Erstelle Child-Account
        final childUser = await client.userProfile.addChildAccount(
          parentProfile.id!,
          firstName,
          lastName,
          birthDate,
          gender,
          address: _addressController.text,
          city: _cityController.text,
          postalCode: _postalCodeController.text,
          phoneNumber: _phoneNumberController.text,
        );

        if (childUser != null) {
          // Erfolg!
          _showSuccessDialog(childUser.firstName!, childUser.lastName!);
        } else {
          setState(() {
            _errorMessage =
                'Fehler beim Erstellen des Kinderkontos. Bitte versuchen Sie es erneut.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Fehler: ${e.toString()}';
        });
      }
    }
  }

  void _showSuccessDialog(String firstName, String lastName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text('Erfolgreich!'),
            ],
          ),
          content: Text(
            'Das Kinderkonto für $firstName $lastName wurde erfolgreich erstellt!\n\n'
            'Möchten Sie noch ein weiteres Familienmitglied hinzufügen?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                // Zur Haupt-App navigieren
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainTabController(),
                  ),
                  (route) => false, // Alle vorherigen Routes entfernen
                );
              },
              child: const Text('Nein, fertig'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                // Formular zurücksetzen für nächstes Kind
                _resetFormForNextChild();
              },
              child: const Text('Ja, weiteres Kind'),
            ),
          ],
        );
      },
    );
  }

  void _resetFormForNextChild() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _birthDateController.clear();
      _selectedGender = null;
      _errorMessage = null;
      // Adresse etc. bleiben vorausgefüllt
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kind anmelden'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info-Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.family_restroom,
                            color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Kinderkonto für Familie ${widget.parentLastName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Parent: ${widget.parentFirstName} ${widget.parentLastName}\n'
                      'Email: ${widget.parentEmail}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Daten des Kindes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Kind-spezifische Felder
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname des Kindes*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.isEmpty ?? true)
                    ? 'Vorname ist ein Pflichtfeld'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nachname des Kindes*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.isEmpty ?? true)
                    ? 'Nachname ist ein Pflichtfeld'
                    : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Geschlecht*',
                  border: OutlineInputBorder(),
                ),
                items: ['männlich', 'weiblich', 'divers'].map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Bitte Geschlecht auswählen' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Geburtsdatum (TT.MM.JJJJ)*',
                  border: const OutlineInputBorder(),
                  helperText: 'Nur für Personen unter 18 Jahren',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Geburtsdatum ist ein Pflichtfeld';
                  if (_parseDate(value!) == null)
                    return 'Ungültiges Format (TT.MM.JJJJ)';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Adresse (übernommen von Elternteil)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  helperText: 'Kann bei Bedarf geändert werden',
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Stadt',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'PLZ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Telefonnummer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Fehlermeldung
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _addChild,
                      child: const Text('Kind anmelden'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
