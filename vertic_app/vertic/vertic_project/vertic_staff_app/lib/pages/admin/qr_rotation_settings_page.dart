import 'package:flutter/material.dart';

class QrRotationSettingsPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool, String?) onUnsavedChanges;

  const QrRotationSettingsPage({
    super.key,
    required this.onBack,
    required this.onUnsavedChanges,
  });

  @override
  State<QrRotationSettingsPage> createState() => _QrRotationSettingsPageState();
}

class _QrRotationSettingsPageState extends State<QrRotationSettingsPage> {
  String _selectedMode = 'daily_usage';
  int _intervalHours = 24;
  bool _requiresUsageForRotation = true;
  bool _emergencyRotationEnabled = true;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _rotationModes = [
    {
      'id': 'immediate',
      'name': 'Nach jeder Nutzung',
      'description':
          'Höchste Sicherheit - QR-Code wird nach jedem Check-in neu generiert',
      'icon': Icons.security,
      'color': Colors.red,
      'recommended': false,
    },
    {
      'id': 'daily_usage',
      'name': 'Täglich bei Nutzung',
      'description':
          'Ausgewogen - QR-Code wird alle 24h rotiert, aber nur wenn benutzt',
      'icon': Icons.schedule,
      'color': Colors.green,
      'recommended': true,
    },
    {
      'id': 'time_based',
      'name': 'Zeitbasiert',
      'description':
          'Regelmäßig - QR-Code wird nach konfigurierbarer Zeit rotiert',
      'icon': Icons.timer,
      'color': Colors.blue,
      'recommended': false,
    },
    {
      'id': 'manual',
      'name': 'Manuell',
      'description': 'Niedrigste Sicherheit - QR-Code wird nur manuell rotiert',
      'icon': Icons.pan_tool,
      'color': Colors.orange,
      'recommended': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _selectedMode = 'daily_usage';
        _intervalHours = 24;
        _requiresUsageForRotation = true;
        _emergencyRotationEnabled = true;
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Einstellungen: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      widget.onUnsavedChanges(true, 'QR-Rotation-Einstellungen');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      const success = true;

      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        widget.onUnsavedChanges(false, null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('QR-Rotation-Einstellungen erfolgreich gespeichert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Fehler beim Speichern der Einstellungen';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Speichern: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code Rotation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _hasUnsavedChanges ? _showUnsavedChangesDialog : widget.onBack,
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveSettings,
              tooltip: 'Einstellungen speichern',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sicherheitshinweis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Diese Einstellungen betreffen die Sicherheit aller QR-Codes im System.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'QR-Code Rotation Modi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ..._rotationModes.map((mode) => _buildModeCard(mode)),
          const SizedBox(height: 24),
          if (_selectedMode == 'time_based') ...[
            Text(
              'Zeitintervall-Einstellungen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTimeIntervalSettings(),
            const SizedBox(height: 24),
          ],
          Text(
            'Erweiterte Optionen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildAdvancedOptions(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeCard(Map<String, dynamic> mode) {
    final isSelected = _selectedMode == mode['id'];
    final isRecommended = mode['recommended'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? mode['color'].withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode['id'];
          });
          _markAsChanged();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: mode['id'],
                groupValue: _selectedMode,
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value!;
                  });
                  _markAsChanged();
                },
                activeColor: mode['color'],
              ),
              const SizedBox(width: 12),
              Icon(
                mode['icon'],
                color: isSelected ? mode['color'] : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? mode['color'] : null,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'EMPFOHLEN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeIntervalSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rotationsintervall: $_intervalHours Stunden',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _intervalHours.toDouble(),
              min: 1,
              max: 168,
              divisions: 23,
              label: '$_intervalHours h',
              onChanged: (value) {
                setState(() {
                  _intervalHours = value.round();
                });
                _markAsChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1h', style: TextStyle(color: Colors.grey.shade600)),
                Text('1 Woche', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Nutzung für Rotation erforderlich'),
              subtitle: const Text(
                  'QR-Code wird nur rotiert wenn er tatsächlich verwendet wurde'),
              value: _requiresUsageForRotation,
              onChanged: (value) {
                setState(() {
                  _requiresUsageForRotation = value;
                });
                _markAsChanged();
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Notfall-Rotation aktiviert'),
              subtitle: const Text(
                  'Admins können QR-Codes manuell sofort rotieren lassen'),
              value: _emergencyRotationEnabled,
              onChanged: (value) {
                setState(() {
                  _emergencyRotationEnabled = value;
                });
                _markAsChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _hasUnsavedChanges ? _showUnsavedChangesDialog : widget.onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Zurück'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _hasUnsavedChanges && !_isLoading ? _saveSettings : null,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Speichern...' : 'Speichern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Sie haben ungespeicherte Änderungen an den QR-Rotation-Einstellungen. '
          'Möchten Sie diese speichern bevor Sie fortfahren?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onUnsavedChanges(false, null);
              widget.onBack();
            },
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveSettings();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
