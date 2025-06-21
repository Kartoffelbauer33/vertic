import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:file_picker/file_picker.dart';

class DocumentManagementPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool, String?)? onUnsavedChanges;

  const DocumentManagementPage({
    super.key,
    required this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<DocumentManagementPage> createState() => _DocumentManagementPageState();
}

class _DocumentManagementPageState extends State<DocumentManagementPage> {
  List<RegistrationDocument> _documents = [];
  List<Gym> _gyms = [];
  Map<int, DocumentDisplayRule?> _documentRules = {}; // Cache for rules
  bool _isLoading = true;
  String? _errorMessage;

  // Upload form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedDocumentType = 'datenschutz';
  Uint8List? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;

  final List<String> _documentTypes = [
    'datenschutz',
    'hallenrichtlinien',
    'hausordnung',
    'agb',
    'haftungsausschluss',
    'minderjaerige',
    'sonstiges',
  ];

  final Map<String, String> _documentTypeNames = {
    'datenschutz': 'Datenschutzerklärung',
    'hallenrichtlinien': 'Hallenrichtlinien',
    'hausordnung': 'Hausordnung',
    'agb': 'AGB',
    'haftungsausschluss': 'Haftungsausschluss',
    'minderjaerige': 'Minderjährige',
    'sonstiges': 'Sonstiges',
  };

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      // Load documents and gyms in parallel
      final results = await Future.wait([
        client.documentManagement.getAllDocuments(),
        client.documentManagement.getAllGyms(),
      ]);

      final documents = results[0] as List<RegistrationDocument>;
      final gyms = results[1] as List<Gym>;

      // Load rules for all documents
      final Map<int, DocumentDisplayRule?> rulesMap = {};
      for (final document in documents) {
        final rules = await client.documentManagement
            .getDisplayRulesForDocument(document.id!);
        rulesMap[document.id!] = rules.isNotEmpty ? rules.first : null;
      }

      setState(() {
        _documents = documents;
        _gyms = gyms;
        _documentRules = rulesMap;
        _isLoading = false;
      });

      debugPrint(
          '📋 ${documents.length} Dokumente, ${gyms.length} Gyms geladen');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Dokumente: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Dokumente: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      debugPrint('🔍 Starte File Picker...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // Wichtig: Daten laden
      );

      debugPrint(
          '📄 File Picker Result: ${result != null ? "Erfolg" : "Null"}');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        debugPrint(
            '📄 Datei Details: name=${file.name}, size=${file.size}, bytes=${file.bytes != null ? "vorhanden" : "null"}');

        if (file.bytes != null) {
          setState(() {
            _selectedFile = file.bytes;
            _selectedFileName = file.name;
          });
          debugPrint(
              '✅ PDF ausgewählt: $_selectedFileName (${_selectedFile!.length} bytes)');
        } else {
          throw Exception(
              'Datei-Bytes sind null - möglicherweise zu groß oder beschädigt');
        }
      } else {
        debugPrint('⚠️ Keine Datei ausgewählt oder Result ist null');
      }
    } catch (e) {
      debugPrint('❌ File Picker Fehler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Auswählen der Datei: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titel ist erforderlich'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie eine PDF-Datei aus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      debugPrint('🔍 Starte Upload...');
      debugPrint('📄 Titel: ${_titleController.text.trim()}');
      debugPrint('📄 Typ: $_selectedDocumentType');
      debugPrint(
          '📄 Datei: $_selectedFileName (${_selectedFile!.length} bytes)');

      // Echte Backend-Anbindung: PDF hochladen
      final response = await client.documentManagement.uploadDocument(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _selectedDocumentType,
        ByteData.sublistView(_selectedFile!),
        _selectedFileName!,
      );

      debugPrint(
          '📄 Server Response: success=${response.success}, message=${response.message}');

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${response.message}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear form
        _clearUploadForm();

        // Reload documents
        await _loadDocuments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${response.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Upload Fehler: $e');
      debugPrint('📄 StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Upload: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _clearUploadForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDocumentType = 'datenschutz';
      _selectedFile = null;
      _selectedFileName = null;
    });
  }

  void _showUploadDialog() {
    _clearUploadForm();
    showDialog(
      context: context,
      builder: (context) => _buildUploadDialog(),
    );
  }

  Widget _buildUploadDialog() {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.upload_file, color: Colors.teal),
              SizedBox(width: 8),
              Text('Dokument hochladen'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titel *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedDocumentType,
                    decoration: const InputDecoration(
                      labelText: 'Dokumenttyp *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _documentTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_documentTypeNames[type] ?? type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedDocumentType = value!;
                      });
                    },
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

                  // File picker
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await _pickFile();
                        setDialogState(() {}); // Update dialog
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedFile != null
                                ? Icons.picture_as_pdf
                                : Icons.upload_file,
                            size: 48,
                            color: _selectedFile != null
                                ? Colors.red
                                : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFile != null
                                ? _selectedFileName!
                                : 'PDF-Datei auswählen',
                            style: TextStyle(
                              color: _selectedFile != null
                                  ? Colors.black
                                  : Colors.grey,
                              fontWeight: _selectedFile != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (_selectedFile != null)
                            Text(
                              '${(_selectedFile!.length / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
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
              onPressed: _isUploading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _uploadDocument();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Hochladen'),
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
        title: const Text('Dokument-Verwaltung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Dokument hochladen',
        child: const Icon(Icons.upload_file),
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
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Keine Dokumente vorhanden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Laden Sie Registrierungs-Dokumente hoch mit dem + Button.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final document = _documents[index];
          return _buildDocumentCard(document);
        },
      ),
    );
  }

  Widget _buildDocumentCard(RegistrationDocument document) {
    final currentRule = _documentRules[document.id!];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: document.isActive ? Colors.green : Colors.grey,
          child: Icon(
            document.isActive ? Icons.description : Icons.block,
            color: Colors.white,
          ),
        ),
        title: Text(
          document.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_documentTypeNames[document.documentType] ??
                document.documentType),
            Text(
                '${(document.fileSize / 1024).toStringAsFixed(1)} KB • ${document.fileName}'),
            if (currentRule != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: currentRule.isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRuleDescription(currentRule),
                  style: TextStyle(
                    fontSize: 12,
                    color: currentRule.isActive
                        ? Colors.green.shade800
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleDocumentAction(value, document),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'update',
              child: Row(
                children: [
                  Icon(Icons.update, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Aktualisieren'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'status',
              child: Row(
                children: [
                  Icon(document.isActive
                      ? Icons.visibility_off
                      : Icons.visibility),
                  const SizedBox(width: 8),
                  Text(document.isActive ? 'Deaktivieren' : 'Aktivieren'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Herunterladen'),
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
        children: [
          _buildDocumentRuleEditor(document),
          _buildDocumentDetails(document),
        ],
      ),
    );
  }

  Widget _buildDocumentRuleEditor(RegistrationDocument document) {
    final currentRule = _documentRules[document.id!];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DocumentRuleForm(
        document: document,
        currentRule: currentRule,
        gyms: _gyms,
        onSave: (minAge, maxAge, gymId, isRequired, isActive) =>
            _saveDocumentRule(document,
                minAge: minAge,
                maxAge: maxAge,
                gymId: gymId,
                isRequired: isRequired,
                isActive: isActive),
        onDelete: () => _deleteDocumentRule(document),
      ),
    );
  }

  Widget _buildDocumentDetails(RegistrationDocument document) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (document.description != null) ...[
            const Text(
              'Beschreibung:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(document.description!),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Erstellt: ${_formatDateTime(document.createdAt)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          if (document.updatedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.update, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Aktualisiert: ${_formatDateTime(document.updatedAt!)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getRuleDescription(DocumentDisplayRule rule) {
    final parts = <String>[];

    if (rule.minAge != null || rule.maxAge != null) {
      if (rule.minAge != null && rule.maxAge != null) {
        parts.add('${rule.minAge}-${rule.maxAge}J');
      } else if (rule.minAge != null) {
        parts.add('ab ${rule.minAge}J');
      } else if (rule.maxAge != null) {
        parts.add('bis ${rule.maxAge}J');
      }
    }

    if (rule.gymId != null) {
      final gym = _gyms.where((g) => g.id == rule.gymId).firstOrNull;
      parts.add(gym?.name ?? "Gym");
    }

    if (rule.isRequired) parts.add('PFLICHT');
    if (!rule.isActive) parts.add('INAKTIV');

    return parts.isEmpty ? 'Alle Benutzer' : parts.join(' • ');
  }

  void _handleDocumentAction(String action, RegistrationDocument document) {
    switch (action) {
      case 'update':
        _updateDocument(document);
        break;
      case 'status':
        _toggleDocumentStatus(document);
        break;
      case 'download':
        _downloadDocument(document);
        break;
      case 'delete':
        _deleteDocument(document);
        break;
    }
  }

  Future<void> _toggleDocumentStatus(RegistrationDocument document) async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // Echte Backend-Anbindung: Status ändern
      final success = await client.documentManagement.updateDocumentStatus(
        document.id!,
        !document.isActive,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${document.title} wurde ${!document.isActive ? "aktiviert" : "deaktiviert"}'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload documents
        await _loadDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Aktualisieren des Status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadDocument(RegistrationDocument document) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('PDF wird heruntergeladen...'),
            ],
          ),
        ),
      );

      final client = Provider.of<Client>(context, listen: false);

      // Download PDF data from server
      final pdfData =
          await client.documentManagement.downloadDocument(document.id!);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (pdfData != null) {
        // Open file save dialog
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'PDF speichern',
          fileName: document.fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputPath != null) {
          // Convert ByteData to Uint8List
          final bytes = pdfData.buffer.asUint8List(
            pdfData.offsetInBytes,
            pdfData.lengthInBytes,
          );

          // Write file to selected location
          final file = File(outputPath);
          await file.writeAsBytes(bytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('📄 "${document.fileName}" erfolgreich gespeichert'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Ordner öffnen',
                  onPressed: () => _openFileLocation(outputPath),
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Dokument konnte nicht heruntergeladen werden'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Download-Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFileLocation(String filePath) {
    try {
      // Windows: Open file location in Explorer
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', filePath]);
      }
      // macOS: Open in Finder
      else if (Platform.isMacOS) {
        Process.run('open', ['-R', filePath]);
      }
      // Linux: Open parent directory
      else if (Platform.isLinux) {
        final directory = File(filePath).parent.path;
        Process.run('xdg-open', [directory]);
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Öffnen des Ordners: $e');
    }
  }

  Future<void> _deleteDocument(RegistrationDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dokument löschen'),
        content: Text(
            'Möchten Sie "${document.title}" wirklich löschen?\n\nACHTUNG: Diese Aktion kann nicht rückgängig gemacht werden!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // User confirmed deletion in the dialog
      try {
        final client = Provider.of<Client>(context, listen: false);
        final success =
            await client.documentManagement.deleteDocument(document.id!);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dokument "${document.title}" wurde gelöscht.'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload documents to reflect the change
          await _loadDocuments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Löschen fehlgeschlagen. Das Dokument wurde nicht gefunden.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lösch-Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDocumentRule(
    RegistrationDocument document, {
    int? minAge,
    int? maxAge,
    int? gymId,
    required bool isRequired,
    required bool isActive,
  }) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final currentRule = _documentRules[document.id!];

      final rule = DocumentDisplayRule(
        id: currentRule?.id,
        documentId: document.id!,
        ruleName: 'Anzeige-Regel für ${document.title}',
        description: null,
        minAge: minAge,
        maxAge: maxAge,
        gymId: gymId,
        isRequired: isRequired,
        isActive: isActive,
        createdAt: currentRule?.createdAt ?? DateTime.now().toUtc(),
      );

      final savedRule =
          await client.documentManagement.addOrUpdateDisplayRule(rule);

      setState(() {
        _documentRules[document.id!] = savedRule;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Regel für "${document.title}" gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern der Regel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDocumentRule(RegistrationDocument document) async {
    final currentRule = _documentRules[document.id!];
    if (currentRule == null) return;

    try {
      final client = Provider.of<Client>(context, listen: false);
      await client.documentManagement.deleteDisplayRule(currentRule.id!);

      setState(() {
        _documentRules[document.id!] = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Regel für "${document.title}" gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen der Regel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateDocument(RegistrationDocument document) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.update, color: Colors.blue),
            SizedBox(width: 8),
            Text('Dokument aktualisieren'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchten Sie das PDF für "${document.title}" aktualisieren?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Was bleibt erhalten:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Titel und Beschreibung'),
                  Text('• Dokumenttyp'),
                  Text('• Alle Anzeige-Regeln'),
                  Text('• Status (aktiv/inaktiv)'),
                  SizedBox(height: 8),
                  Text(
                    'Nur die PDF-Datei wird ersetzt!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('PDF auswählen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🔍 Starte PDF-Auswahl für Update...');

      // Pick new PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        debugPrint('📄 Neue PDF ausgewählt: ${file.name} (${file.size} bytes)');

        if (file.bytes != null) {
          // Show progress dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Dokument wird aktualisiert...'),
                ],
              ),
            ),
          );

          try {
            final client = Provider.of<Client>(context, listen: false);

            // Update document via backend
            final response = await client.documentManagement.updateDocument(
              document.id!,
              ByteData.sublistView(file.bytes!),
              file.name,
            );

            // Close progress dialog
            if (mounted) Navigator.of(context).pop();

            if (response.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${response.message}'),
                  backgroundColor: Colors.green,
                ),
              );

              // Reload documents to show updated file info
              await _loadDocuments();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ${response.message}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          } catch (e) {
            // Close progress dialog if still open
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Update-Fehler: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Fehler beim Lesen der PDF-Datei'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        debugPrint('⚠️ Keine PDF-Datei für Update ausgewählt');
      }
    } catch (e) {
      debugPrint('❌ Fehler bei PDF-Auswahl: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Fehler bei der Dateiauswahl: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Inline rule form widget for documents
class DocumentRuleForm extends StatefulWidget {
  final RegistrationDocument document;
  final DocumentDisplayRule? currentRule;
  final List<Gym> gyms;
  final Function(int?, int?, int?, bool, bool) onSave;
  final VoidCallback onDelete;

  const DocumentRuleForm({
    super.key,
    required this.document,
    required this.currentRule,
    required this.gyms,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<DocumentRuleForm> createState() => _DocumentRuleFormState();
}

class _DocumentRuleFormState extends State<DocumentRuleForm> {
  late TextEditingController _minAgeController;
  late TextEditingController _maxAgeController;
  late int? _selectedGymId;
  late bool _isRequired;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _minAgeController = TextEditingController(
      text: widget.currentRule?.minAge?.toString() ?? '',
    );
    _maxAgeController = TextEditingController(
      text: widget.currentRule?.maxAge?.toString() ?? '',
    );
    _selectedGymId = widget.currentRule?.gymId;
    _isRequired = widget.currentRule?.isRequired ?? false;
    _isActive = widget.currentRule?.isActive ?? true;
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  void _saveRule() {
    final minAge = _minAgeController.text.trim().isEmpty
        ? null
        : int.tryParse(_minAgeController.text.trim());
    final maxAge = _maxAgeController.text.trim().isEmpty
        ? null
        : int.tryParse(_maxAgeController.text.trim());

    widget.onSave(minAge, maxAge, _selectedGymId, _isRequired, _isActive);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.currentRule != null ? Icons.edit : Icons.add,
              color: const Color(0xFF00897B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.currentRule != null
                  ? 'Anzeige-Regel bearbeiten'
                  : 'Anzeige-Regel erstellen',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00897B),
              ),
            ),
            const Spacer(),
            if (widget.currentRule != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Regel löschen'),
                      content: const Text(
                          'Möchten Sie die Anzeige-Regel wirklich löschen?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Abbrechen'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onDelete();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Löschen'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Age inputs
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAgeController,
                decoration: const InputDecoration(
                  labelText: 'Min. Alter',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxAgeController,
                decoration: const InputDecoration(
                  labelText: 'Max. Alter',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Gym selection
        DropdownButtonFormField<int?>(
          value: _selectedGymId,
          decoration: const InputDecoration(
            labelText: 'Boulderhalle',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Alle Boulderhallen'),
            ),
            ...widget.gyms.map((gym) => DropdownMenuItem(
                  value: gym.id,
                  child: Text(gym.name),
                )),
          ],
          onChanged: (value) => setState(() => _selectedGymId = value),
        ),
        const SizedBox(height: 16),

        // Checkboxes
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Pflichtfeld'),
                value: _isRequired,
                onChanged: (value) =>
                    setState(() => _isRequired = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Aktiv'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveRule,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: Text(
              widget.currentRule != null
                  ? 'Regel aktualisieren'
                  : 'Regel erstellen',
            ),
          ),
        ),
      ],
    );
  }
}
