import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:test_server_client/test_server_client.dart';
import 'dart:io';
import 'main_tab_controller.dart'; // Für Navigation nach Registrierung

class CameraCapturePageArgs {
  final String userEmail;
  final Client client;
  final bool isFromRegistration; // NEU: Flag um zu wissen ob von Registrierung

  CameraCapturePageArgs({
    required this.userEmail,
    required this.client,
    this.isFromRegistration = false, // Default false für normale Foto-Updates
  });
}

class CameraCaptureScreen extends StatefulWidget {
  final CameraCapturePageArgs args;

  const CameraCaptureScreen({
    super.key,
    required this.args,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isUploading = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _showErrorDialog('Keine Kamera gefunden');
        return;
      }

      // Bevorzuge Front-Kamera für Selfies
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Initialisieren der Kamera: $e');
      _showErrorDialog('Fehler beim Zugriff auf die Kamera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      debugPrint('Fehler beim Foto aufnehmen: $e');
      _showErrorDialog('Fehler beim Aufnehmen des Fotos: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_capturedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Bild laden und in ByteData konvertieren
      final bytes = await _capturedImage!.readAsBytes();

      // Bildgröße prüfen und bei Bedarf komprimieren
      ByteData photoData;
      if (bytes.length > 1024 * 1024) {
        // > 1MB
        // Komprimierung würde hier stattfinden
        // Für jetzt einfach die ersten 1MB nehmen (nicht optimal, aber sicher)
        final compressedBytes = bytes.take(1024 * 1024).toList();
        photoData = ByteData.sublistView(Uint8List.fromList(compressedBytes));
      } else {
        photoData = ByteData.sublistView(bytes);
      }

      // Foto zum Server hochladen
      final success = await widget.args.client.userProfile.uploadProfilePhoto(
        widget.args.userEmail,
        photoData,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Fehler beim Hochladen des Fotos');
      }
    } catch (e) {
      debugPrint('Fehler beim Upload: $e');
      _showErrorDialog('Fehler beim Hochladen: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fehler'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Erfolg!'),
        content: const Text(
          'Ihr Profilbild wurde erfolgreich hochgeladen.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog schließen

              if (widget.args.isFromRegistration) {
                // Von Registrierung: Zeige Family-Dialog
                _showFamilyMemberDialog();
              } else {
                // Normal: Zurück zur vorherigen Seite
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _skipPhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foto überspringen?'),
        content: const Text(
          'Sie können die Registrierung ohne Foto abschließen. '
          'Das Foto kann später in den Einstellungen hinzugefügt werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog schließen

              if (widget.args.isFromRegistration) {
                // Von Registrierung: Zeige Family-Dialog
                _showFamilyMemberDialog();
              } else {
                // Normal: Zurück zur vorherigen Seite
                Navigator.of(context).pop(false);
              }
            },
            child: const Text('Überspringen'),
          ),
        ],
      ),
    );
  }

  /// Zeigt Dialog für Family-Mitglied hinzufügen (von RegistrationPage kopiert)
  void _showFamilyMemberDialog() {
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
                // TODO: Öffne Child-Registrierung (später implementieren)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainTabController(),
                  ),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Child-Registrierung folgt später. Du bist jetzt angemeldet!')),
                );
              },
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilbild aufnehmen'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: _isInitialized
          ? _buildCameraView()
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildCameraView() {
    if (_capturedImage != null) {
      return _buildPreviewView();
    }

    return Column(
      children: [
        // Info-Text
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Nehmen Sie ein Foto für Ihr Profil auf. '
            'Dies hilft unserem Personal bei der Identifikation.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),

        // Kamera Vorschau
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        ),

        // Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Überspringen Button
              ElevatedButton(
                onPressed: _skipPhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Überspringen'),
              ),

              // Foto aufnehmen Button
              ElevatedButton(
                onPressed: _takePicture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.camera_alt, size: 32),
              ),

              const SizedBox(width: 80), // Platzhalter für Symmetrie
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        // Info-Text
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Wie gefällt Ihnen das Foto?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        // Foto Vorschau
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_capturedImage!.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: _isUploading
              ? const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Foto wird hochgeladen...'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Erneut aufnehmen
                    ElevatedButton(
                      onPressed: _retakePicture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Erneut aufnehmen'),
                    ),

                    // Verwenden
                    ElevatedButton(
                      onPressed: _uploadPhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Verwenden'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
