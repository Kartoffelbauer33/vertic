import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:typed_data';
import '../main.dart'; // Für Zugriff auf client und sessionManager
import 'main_tab_controller.dart'; // Für Navigation nach Login
import 'child_registration_page.dart'; // Für Child-Registrierung
import 'camera_capture_page.dart'; // Für Foto-Aufnahme
import 'package:test_server_client/test_server_client.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/foundation.dart'; // Für Platform Detection

class RegistrationPage extends StatefulWidget {
  final Function(String email, String password)? onRegistrationComplete;

  const RegistrationPage({
    super.key,
    this.onRegistrationComplete,
  });

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages =
      4; // 1. Persönliche Daten, 2. Foto, 3. Dokumente, 4. Validierung

  // Form-Controller für Schritt 1
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedGender;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _validationCodeController = TextEditingController();

  // Parent-Email für Minderjährige
  final _parentEmailController = TextEditingController();
  bool _isMinor = false;

  // Foto-Daten
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  ByteData? _photoData;

  // Dokumente-Zustimmung
  List<DocumentWithRules> _applicableDocuments = [];
  Map<int, bool> _documentAgreements = {};
  bool _isLoadingDocuments = false;
  String? _documentsError;

  String? _errorMessage;
  String? _validationErrorMessage;
  final emailAuthController = EmailAuthController(client.modules.auth);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cameraController?.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneNumberController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _validationCodeController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  // Hilfsmethode zum Parsen des Datums im Format dd.mm.yyyy
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          // Einfache Validierung des Datumsbereichs (kann verfeinert werden)
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
      // Fehler beim Parsen ignorieren, Rückgabe null
    }
    return null;
  }

  // HILFSMETHODEN FÜR BESSERE VALIDATION
  void _validateAndProceed() {
    // Erst validieren wenn jemand wirklich "Weiter" drückt
    if (_formKey.currentState?.validate() ?? false) {
      _nextPage();
    } else {
      // Zeige Fehlermeldung wenn nicht alle Felder ausgefüllt sind
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte fülle zuerst alle Felder aus!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // Standard: 18 Jahre alt
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);

        // WICHTIG: Berechne automatisch ob minderjährig (unter 18)
        final age = DateTime.now().difference(picked).inDays / 365.25;
        _isMinor = age < 18;

        // ALTERSSCHUTZ: Prüfe sofort nach Datumswahl
        if (_isMinor) {
          // Zeige Warnmeldung für Minderjährige
          _showMinorWarningDialog();
        }
      });
    }
  }

  /// Zeigt Warnung für minderjährige Personen
  void _showMinorWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text('Achtung'),
            ],
          ),
          content: const Text(
            'Personen unter 18 Jahren können selbst kein Konto anlegen.\n\n'
            'Bitte frage deine Erziehungsberechtigten, ein Konto für dich zu erstellen.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                Navigator.of(context).pop(); // RegistrationPage schließen
              },
              child: const Text('Verstanden'),
            ),
          ],
        );
      },
    );
  }

  void _register() async {
    setState(() {
      _errorMessage = null;
      _validationErrorMessage = null;
    });

    // Bei Schritt 4 (Validierung) - führe die komplette Registrierung durch
    if (_currentPage != 3) return;

    final email = _isMinor
        ? _parentEmailController.text.trim()
        : _emailController.text.trim();
    final password = _passwordController.text;
    final validationCode = _validationCodeController.text.trim();

    if (validationCode.isEmpty) {
      setState(() {
        _validationErrorMessage = 'Bitte geben Sie den Bestätigungscode ein';
      });
      return;
    }

    if (_photoData == null) {
      setState(() {
        _errorMessage =
            'Profilbild ist erforderlich. Bitte gehen Sie zu Schritt 2 zurück.';
      });
      return;
    }

    try {
      // 1. E-Mail-Validierung durchführen
      debugPrint('🔧 Validiere E-Mail-Code...');
      final userInfo =
          await emailAuthController.validateAccount(email, validationCode);

      if (userInfo == null) {
        setState(() {
          _validationErrorMessage = 'Ungültiger oder abgelaufener Code.';
        });
        return;
      }

      // 2. Automatischer Login (vor weiteren API-Calls!)
      debugPrint('🔑 Führe automatischen Login durch...');
      final loginResult = await emailAuthController.signIn(email, password);

      if (loginResult == null) {
        setState(() {
          _errorMessage =
              'Login nach Registrierung fehlgeschlagen. Bitte erneut versuchen.';
        });
        return;
      }

      // 3. Erweiterte Profildaten speichern (jetzt authentifiziert)
      debugPrint('💾 Speichere Profildaten...');
      // ✅ UNIFIED AUTH: Verwende neuen completeClientRegistration Endpoint
      final profileResult = await client.unifiedAuth.completeClientRegistration(
        _firstNameController.text,
        _lastNameController.text,
        _isMinor ? _parentEmailController.text.trim() : null,
        _parseDate(_birthDateController.text),
        _selectedGender,
        _addressController.text,
        _cityController.text,
        _postalCodeController.text,
        _phoneNumberController.text,
      );

      if (profileResult == null) {
        setState(() {
          _errorMessage = 'Fehler beim Speichern der Profildaten';
        });
        return;
      }

      // 4. Profilbild hochladen
      debugPrint('📸 Lade Profilbild hoch...');
      final photoUploadSuccess = await client.userProfile.uploadProfilePhoto(
        email,
        _photoData!,
      );

      if (!photoUploadSuccess) {
        debugPrint('⚠️ Warnung: Profilbild konnte nicht hochgeladen werden');
        // Trotzdem fortfahren – Foto kann später hinzugefügt werden
      }

      // 5. Dokument-Zustimmungen speichern
      debugPrint('📄 Speichere Dokument-Zustimmungen...');
      await _recordDocumentAgreements(profileResult.id!);

      // 6. Familie-Dialog anzeigen und dann zur Haupt-App
      debugPrint('✅ Registrierung erfolgreich!');

      if (mounted) {
        _showFamilyMemberDialog(context);
      }
    } catch (e) {
      debugPrint('💥 Fehler bei der Registrierung: $e');
      setState(() {
        if (e.toString().contains('email')) {
          _validationErrorMessage =
              'Fehler bei der E-Mail-Validierung: ${e.toString()}';
        } else {
          _errorMessage = 'Registrierung fehlgeschlagen: ${e.toString()}';
        }
      });
    }
  }

  /// Speichere alle Dokument-Zustimmungen in der Datenbank
  Future<void> _recordDocumentAgreements(int clientId) async {
    for (final entry in _documentAgreements.entries) {
      final documentId = entry.key;
      final isAgreed = entry.value;

      if (isAgreed) {
        try {
          await client.documentManagement.recordUserAgreement(
            clientId,
            documentId,
            null, // IP-Adresse optional
            null, // User-Agent optional
          );
          debugPrint('✅ Zustimmung gespeichert für Dokument $documentId');
        } catch (e) {
          debugPrint(
              '❌ Fehler beim Speichern der Zustimmung für Dokument $documentId: $e');
          // Fortfahren, auch wenn einzelne Zustimmungen fehlschlagen
        }
      }
    }
  }

  // HILFSMETHODE: Startet die E-Mail-Validierung wenn von Schritt 1 zu Schritt 3
  void _startEmailValidation() async {
    final email = _isMinor
        ? _parentEmailController.text.trim()
        : _emailController.text.trim();
    final password = _passwordController.text;

    try {
      debugPrint('📧 Sende Registrierungs-E-Mail...');
      final result = await emailAuthController.createAccountRequest(
        '${_firstNameController.text} ${_lastNameController.text}',
        email,
        password,
      );

      if (!result) {
        setState(() {
          _errorMessage =
              'E-Mail-Versand fehlgeschlagen. Möglicherweise existiert bereits ein Konto.';
        });
        _previousPage(); // Zurück zu Schritt 1
        return;
      }

      debugPrint('✅ Bestätigungscode gesendet an: $email');
    } catch (e) {
      debugPrint('💥 Fehler beim E-Mail-Versand: $e');
      setState(() {
        _errorMessage =
            'Fehler beim Versenden der Bestätigungs-E-Mail: ${e.toString()}';
      });
      _previousPage(); // Zurück zu Schritt 1
    }
  }

  /// Zeigt Foto-Aufnahme für Profilbild
  void _showPhotoCapture(BuildContext context, String userEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text('Profilbild'),
            ],
          ),
          content: const Text(
            'Möchten Sie ein Profilbild für Ihr Konto aufnehmen?\n\n'
            'Dies hilft unserem Personal bei der Identifikation.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                _showFamilyMemberDialog(context); // Direkt zu Family-Dialog
              },
              child: const Text('Überspringen'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dialog schließen

                // Öffne Kamera-Aufnahme
                final photoTaken = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => CameraCaptureScreen(
                      args: CameraCapturePageArgs(
                        userEmail: userEmail,
                        client: client,
                      ),
                    ),
                  ),
                );

                // Nach Foto-Aufnahme (oder Überspringen) zum Family-Dialog
                if (mounted) {
                  _showFamilyMemberDialog(context);
                }
              },
              child: const Text('Foto aufnehmen'),
            ),
          ],
        );
      },
    );
  }

  /// Zeigt Dialog für Family-Mitglied hinzufügen
  void _showFamilyMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Familie'),
            ],
          ),
          content: const Text(
            'Sie sind erfolgreich angemeldet!\n\n'
            'Möchten Sie noch ein Familienmitglied unter 18 Jahren anmelden?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                // DIREKT zur MainTabController navigieren
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainTabController(),
                  ),
                  (route) => false, // Alle vorherigen Routes entfernen
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Registrierung erfolgreich! Du bist jetzt angemeldet.')),
                );
              },
              child: const Text('Nein'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                // Öffne Child-Registrierung
                _showChildRegistration(context);
              },
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
  }

  /// Öffnet Child-Registrierung mit vorausgefüllten Parent-Daten
  void _showChildRegistration(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChildRegistrationPage(
          parentFirstName: _firstNameController.text,
          parentLastName: _lastNameController.text,
          parentEmail: _emailController.text,
          parentGender: _selectedGender ?? 'unbekannt',
          parentAddress: _addressController.text,
          parentCity: _cityController.text,
          parentPostalCode: _postalCodeController.text,
          parentPhoneNumber: _phoneNumberController.text,
        ),
      ),
    );
  }

  // KAMERA-METHODEN
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('Keine Kamera gefunden');
        return;
      }

      // Bevorzuge Front-Kamera für Selfies
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Initialisieren der Kamera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      setState(() {
        _capturedImage = image;
        _photoData = ByteData.sublistView(bytes);
      });
    } catch (e) {
      debugPrint('Fehler beim Foto aufnehmen: $e');
      setState(() {
        _errorMessage = 'Fehler beim Aufnehmen des Fotos: $e';
      });
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
      _photoData = null;
    });
  }

  // NAVIGATION ZWISCHEN SCHRITTEN
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // Spezielle Logik beim Übergang von Schritt 2 (Foto) zu Schritt 3 (Dokumente)
      if (_currentPage == 1) {
        _loadApplicableDocuments(); // Dokumente laden
      }
      // Spezielle Logik beim Übergang von Schritt 3 (Dokumente) zu Schritt 4 (E-Mail)
      else if (_currentPage == 2) {
        _startEmailValidation(); // E-Mail-Versand starten
      }

      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedFromStep1() {
    // Button ist immer verfügbar - Validierung passiert beim Klick
    return true;
  }

  bool _canProceedFromStep2() {
    return _photoData != null; // Foto ist Pflicht!
  }

  bool _canProceedFromStep3() {
    return _canProceedFromStep4(); // Verwende die gleiche Logik
  }

  bool _canProceedFromStep4() {
    // Prüfe, ob alle Pflichtdokumente zugestimmt wurden
    for (final documentWithRules in _applicableDocuments) {
      if (documentWithRules.isRequiredForUser) {
        final isAgreed =
            _documentAgreements[documentWithRules.document.id!] ?? false;
        if (!isAgreed) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _loadApplicableDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
      _documentsError = null;
    });

    try {
      // Berechne Alter basierend auf Geburtsdatum
      final birthDate = _parseDate(_birthDateController.text);
      if (birthDate == null) {
        throw Exception('Geburtsdatum ist erforderlich');
      }

      final age = DateTime.now().difference(birthDate).inDays ~/ 365;

      // Lade anwendbare Dokumente vom Server
      final documents =
          await client.documentManagement.getDocumentsForUser(age, null);

      setState(() {
        _applicableDocuments = documents;
        _isLoadingDocuments = false;

        // Initialisiere Agreement-Map
        for (final doc in documents) {
          _documentAgreements[doc.document.id!] = false;
        }
      });

      debugPrint(
          '📋 ${documents.length} anwendbare Dokumente geladen für Alter: $age');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Dokumente: $e');
      setState(() {
        _documentsError = e.toString();
        _isLoadingDocuments = false;
      });
    }
  }

  String _getDocumentTypeDisplayName(String documentType) {
    const typeNames = {
      'datenschutz': 'Datenschutzerklärung',
      'hallenrichtlinien': 'Hallenrichtlinien',
      'hausordnung': 'Hausordnung',
      'agb': 'Allgemeine Geschäftsbedingungen',
      'haftungsausschluss': 'Haftungsausschluss',
      'minderjaerige': 'Bestimmungen für Minderjährige',
      'sonstiges': 'Sonstiges',
    };
    return typeNames[documentType.toLowerCase()] ?? documentType;
  }

  void _showDocumentDialog(RegistrationDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.title),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDocumentTypeDisplayName(document.documentType),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _PDFViewer(documentId: document.id!),
                ),
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrierung (${_currentPage + 1}/$_totalPages)'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Nur über Buttons navigieren
        children: [
          _buildStep1PersonalData(),
          _buildStep2Photo(),
          _buildStep3Documents(),
          _buildStep4Validation(),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Zurück Button
          if (_currentPage > 0)
            ElevatedButton(
              onPressed: _previousPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Zurück'),
            )
          else
            const SizedBox.shrink(),

          // Progress Indicator
          Row(
            children: List.generate(_totalPages, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index <= _currentPage
                      ? const Color(0xFF00897B)
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),

          // Weiter/Fertig Button
          ElevatedButton(
            onPressed: _getNextButtonAction(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: Text(_getNextButtonText()),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentPage) {
      case 0:
        return _validateAndProceed; // Validierung beim Klick
      case 1:
        return _canProceedFromStep2() ? _nextPage : null;
      case 2:
        return _canProceedFromStep3() ? _nextPage : null; // Dokumente
      case 3:
        return _register; // E-Mail Validierung und Abschluss
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Weiter zum Foto';
      case 1:
        return 'Weiter zu Dokumenten';
      case 2:
        return 'Weiter zur E-Mail Bestätigung';
      case 3:
        return 'Registrierung abschließen';
      default:
        return 'Weiter';
    }
  }

  Widget _buildStep1PersonalData() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Erstelle dein Konto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // E-Mail & Passwort (Anmeldedaten)
            const Text('Anmeldedaten',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Email-Feld (nur für Erwachsene sichtbar)
            if (!_isMinor) ...[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Deine E-Mail*',
                  border: OutlineInputBorder(),
                  helperText: 'Du erhältst hier den Bestätigungscode',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (!_isMinor && (value == null || value.isEmpty)) {
                    return 'E-Mail ist für Erwachsene erforderlich';
                  }
                  if (!_isMinor &&
                      (!value!.contains('@') || !value.contains('.'))) {
                    return 'Bitte gib eine gültige E-Mail-Adresse ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Parent-Email-Feld (nur für Minderjährige sichtbar)
            if (_isMinor) ...[
              Container(
                padding: const EdgeInsets.all(12),
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
                        Icon(Icons.info,
                            color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Du bist unter 18 Jahre alt',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ein Elternteil oder Erziehungsberechtigter muss deine Registrierung bestätigen.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentEmailController,
                decoration: const InputDecoration(
                  labelText:
                      'E-Mail deines Elternteils/Erziehungsberechtigten*',
                  border: OutlineInputBorder(),
                  helperText: 'Der Bestätigungscode wird hierhin gesendet',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (_isMinor && (value == null || value.isEmpty)) {
                    return 'Parent-Email ist für Minderjährige erforderlich';
                  }
                  if (_isMinor &&
                      (!value!.contains('@') || !value.contains('.'))) {
                    return 'Bitte gib eine gültige E-Mail-Adresse ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Passwort*',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte gib ein Passwort ein';
                }
                if (value.length < 8) {
                  return 'Das Passwort muss mindestens 8 Zeichen lang sein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Passwort bestätigen*',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte bestätige dein Passwort';
                }
                if (value != _passwordController.text) {
                  return 'Die Passwörter stimmen nicht überein';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Persönliche Daten
            const Text('Persönliche Daten',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Vorname*',
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
                labelText: 'Nachname*',
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              keyboardType: TextInputType.datetime,
              readOnly: true, // Nur über Datepicker änderbar
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

            // Kontaktdaten
            const Text('Kontaktdaten',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse*',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value?.isEmpty ?? true)
                  ? 'Adresse ist ein Pflichtfeld'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Stadt*',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value?.isEmpty ?? true) ? 'Stadt ist ein Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'PLZ*',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value?.isEmpty ?? true) ? 'PLZ ist ein Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Telefonnummer*',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => (value?.isEmpty ?? true)
                  ? 'Telefonnummer ist ein Pflichtfeld'
                  : null,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Photo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Schritt 2: Profilbild aufnehmen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nehmen Sie ein Foto für Ihr Profil auf. Dies ist ein Pflichtfeld und hilft unserem Personal bei der Identifikation.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Kamera-Ansicht oder Foto-Vorschau
          Expanded(
            child: _capturedImage != null
                ? _buildPhotoPreview()
                : _buildCameraView(),
          ),

          const SizedBox(height: 16),

          // Foto-Buttons
          if (_capturedImage != null)
            ElevatedButton(
              onPressed: _retakePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Erneut aufnehmen'),
            )
          else if (_isCameraInitialized)
            ElevatedButton(
              onPressed: _takePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              child: const Icon(Icons.camera_alt, size: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Kamera wird initialisiert...'),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_capturedImage!.path),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStep3Documents() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schritt 3: Dokumente bestätigen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bitte lesen und bestätigen Sie die folgenden Dokumente:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (_isLoadingDocuments)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Lade anwendbare Dokumente...'),
                ],
              ),
            )
          else if (_documentsError != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Fehler beim Laden der Dokumente: $_documentsError',
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadApplicableDocuments,
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            )
          else if (_applicableDocuments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Keine zusätzlichen Dokumente erforderlich.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _applicableDocuments.length,
                itemBuilder: (context, index) {
                  final documentWithRules = _applicableDocuments[index];
                  final document = documentWithRules.document;
                  final isRequired = documentWithRules.isRequiredForUser;
                  final isAgreed = _documentAgreements[document.id!] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  document.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'PFLICHT',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDocumentTypeDisplayName(document.documentType),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          if (document.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              document.description!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showDocumentDialog(document),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Dokument anzeigen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CheckboxListTile(
                                  value: isAgreed,
                                  onChanged: (value) {
                                    setState(() {
                                      _documentAgreements[document.id!] =
                                          value ?? false;
                                    });
                                  },
                                  title: Text(
                                    'Hiermit stimme ich zu',
                                    style: TextStyle(
                                      fontWeight: isRequired
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep4Validation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schritt 4: E-Mail bestätigen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Wir haben einen Bestätigungscode an ${_isMinor ? _parentEmailController.text : _emailController.text} gesendet.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _validationCodeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Bestätigungscode',
              border: const OutlineInputBorder(),
              errorText: _validationErrorMessage,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie den Bestätigungscode ein';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Zusammenfassung
          const Text(
            'Zusammenfassung:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Name: ${_firstNameController.text} ${_lastNameController.text}'),
                  const SizedBox(height: 8),
                  Text(
                      'E-Mail: ${_isMinor ? _parentEmailController.text : _emailController.text}'),
                  const SizedBox(height: 8),
                  Text('Geschlecht: ${_selectedGender ?? "Nicht angegeben"}'),
                  const SizedBox(height: 8),
                  Text('Geburtsdatum: ${_birthDateController.text}'),
                  const SizedBox(height: 8),
                  Text(
                      'Profilbild: ${_photoData != null ? "✅ Aufgenommen" : "❌ Nicht vorhanden"}'),
                  const SizedBox(height: 8),
                  Text('Dokumente: ${_applicableDocuments.length} bestätigt'),
                  if (_isMinor) ...[
                    const SizedBox(height: 8),
                    const Text(
                        '⚠️ Minderjährig - Elternbestätigung erforderlich'),
                  ],
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget für PDF-Anzeige
class _PDFViewer extends StatefulWidget {
  final int documentId;

  const _PDFViewer({required this.documentId});

  @override
  State<_PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<_PDFViewer> {
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfData;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('📄 Lade PDF für Dokument ${widget.documentId}...');

      // PDF-Daten vom Server laden
      final pdfData =
          await client.documentManagement.downloadDocument(widget.documentId);

      if (pdfData == null) {
        throw Exception('Dokument nicht gefunden');
      }

      debugPrint('📄 PDF geladen (${pdfData.lengthInBytes} bytes)');

      setState(() {
        _pdfData = pdfData.buffer.asUint8List();
        _isLoading = false;
      });

      debugPrint('📄 PDF-Daten erfolgreich gespeichert');
    } catch (e, stackTrace) {
      debugPrint('❌ Fehler beim Laden des PDFs: $e');
      debugPrint('📄 StackTrace: $stackTrace');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF wird geladen...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade600),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPDF,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_pdfData == null) {
      return const Center(
        child: Text('PDF-Daten nicht verfügbar'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: PdfViewer.data(
        _pdfData!,
        sourceName: 'doc-${widget.documentId}',
      ),
    );
  }
}
