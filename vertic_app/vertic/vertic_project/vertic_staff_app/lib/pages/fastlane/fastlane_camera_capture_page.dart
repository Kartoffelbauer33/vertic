import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Vollbild-Kamera zum Aufnehmen eines Profilfotos für die Fastlane-Registrierung.
/// Gibt die Bilddaten als ByteData zurück. Keine Datei-Auswahl, nur Kamera.
class FastlaneCameraCapturePage extends StatefulWidget {
  const FastlaneCameraCapturePage({super.key});

  @override
  State<FastlaneCameraCapturePage> createState() => _FastlaneCameraCapturePageState();
}

class _FastlaneCameraCapturePageState extends State<FastlaneCameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
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
        _showError('Keine Kamera gefunden');
        return;
      }

      final front = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      _showError('Fehler beim Initialisieren der Kamera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kamera-Fehler'),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final image = await _controller!.takePicture();
      setState(() => _capturedImage = image);
    } catch (e) {
      _showError('Fehler beim Aufnehmen: $e');
    }
  }

  Future<void> _usePicture() async {
    if (_capturedImage == null) return;
    try {
      final bytes = await _capturedImage!.readAsBytes();
      final data = ByteData.sublistView(bytes);
      if (!mounted) return;
      Navigator.of(context).pop<ByteData>(data);
    } catch (e) {
      _showError('Fehler beim Verarbeiten des Bildes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto aufnehmen')),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _capturedImage == null
              ? Column(
                  children: [
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
                          ElevatedButton.icon(
                            onPressed: _takePicture,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Aufnehmen'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(onPressed: () => setState(() => _capturedImage = null), child: const Text('Erneut')),
                          ElevatedButton.icon(
                            onPressed: _usePicture,
                            icon: const Icon(Icons.check),
                            label: const Text('Verwenden'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}


