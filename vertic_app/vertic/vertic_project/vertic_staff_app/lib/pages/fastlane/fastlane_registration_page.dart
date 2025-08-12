import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

import 'package:vertic_staff/design_system/design_system.dart';

/// Registrierung in der Fastlane mit 4 Schritten + Fortschrittsleiste
/// Schritt 1: Personendaten + Foto
/// Schritt 2: Notfallkontakt
/// Schritt 3: Kinder hinzufügen
/// Schritt 4: Übersicht + Zustimmungen + Senden
class FastlaneRegistrationPage extends StatefulWidget {
  const FastlaneRegistrationPage({super.key});

  @override
  State<FastlaneRegistrationPage> createState() => _FastlaneRegistrationPageState();
}

class _FastlaneRegistrationPageState extends State<FastlaneRegistrationPage> {
  final PageController _controller = PageController();
  int _currentStep = 0;
  // Hinweis: Kameraberechtigung wird zentral in _PhotoActions nur einmal pro Laufzeit erfragt

  // Schritt 1
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _gender;
  ByteData? _profilePhoto; // Upload später via userProfile.uploadProfilePhoto

  // Schritt 2 Notfallkontakt
  final _emFirstName = TextEditingController();
  final _emLastName = TextEditingController();
  final _emPhone = TextEditingController();

  // Schritt 3 Kinder (vereinfachte Liste im State)
  final List<_ChildDraft> _children = [];

  // Inline-Kind-Eingabe (kein Dialog mehr)
  final _childFirst = TextEditingController();
  final _childLast = TextEditingController();
  DateTime? _childBirth;
  String? _childGender;


  // Schritt 4 Zustimmungen
  bool _agreedHouseRules = false;
  bool _agreedAGB = false;
  bool _agreedPrivacy = false;

  @override
  void dispose() {
    _controller.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _birthDate.dispose();
    _address.dispose();
    _email.dispose();
    _phone.dispose();
    _emFirstName.dispose();
    _emLastName.dispose();
    _emPhone.dispose();
    _childFirst.dispose();
    _childLast.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      children: [
        _buildStepBar(context),
        SizedBox(height: spacing.md),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(context),
                  _buildStep2(context),
                  _buildStep3(context),
                  _buildStep4(context),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          child: Row(
            children: [
              if (_currentStep > 0)
                VerticOutlineButton(text: 'Zurück', onPressed: _prev, width: 160),
              const Spacer(),
              PrimaryButton(
                text: _currentStep < 3 ? 'Weiter' : 'Senden',
                onPressed: _handlePrimary,
                width: 200,
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
      ],
    );
  }

  Widget _buildStepBar(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final steps = ['Daten', 'Notfall', 'Kinder', 'Übersicht'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDone
                        ? colors.primary
                        : isActive
                            ? colors.primary.withValues(alpha: 0.5)
                            : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(spacing.radiusSm),
                  ),
                ),
              ),
              SizedBox(width: spacing.sm),
              Text(
                steps[i],
                style: typography.labelSmall.copyWith(
                  color: isActive || isDone ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
              if (i < steps.length - 1) SizedBox(width: spacing.md),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final typography = context.typography;

    // Layout: Foto links, rechts die Felder in gewünschter Reihenfolge
    final form = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Name-Reihe
          _row2(
            TextInput(label: 'Vorname', controller: _firstName, required: true),
            TextInput(label: 'Nachname', controller: _lastName, required: true),
          ),
          SizedBox(height: spacing.md),
        // Geburtsdatum + Geschlecht
          _row2(
            TextInput(
              label: 'Geburtsdatum (TT.MM.JJJJ)',
              controller: _birthDate,
              required: true,
              suffixIcon: Icons.calendar_today,
              onSuffixIconPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  initialDate: DateTime(now.year - 18, now.month, now.day),
                  lastDate: now,
                );
                if (date != null) {
                  _birthDate.text = DateFormat('dd.MM.yyyy').format(date);
                  setState(() {});
                }
              },
            ),
          _GenderDropdown(
            value: _gender,
            onChanged: (g) => setState(() => _gender = g),
          ),
        ),
        SizedBox(height: spacing.md),
        // E-Mail + Telefon
        _row2(
          EmailInput(label: 'E-Mail', controller: _email, required: true),
          PhoneInput(label: 'Telefonnummer', controller: _phone),
        ),
        SizedBox(height: spacing.md),
        // Adresse als vierer Grid auf zwei Reihen
        _row2(
          TextInput(label: 'Straße', controller: _address, required: true),
          TextInput(label: 'Hausnummer', controller: TextEditingController()),
          ),
          SizedBox(height: spacing.md),
          _row2(
          TextInput(label: 'Postleitzahl', controller: TextEditingController()),
          TextInput(label: 'Ort', controller: TextEditingController()),
        ),
        SizedBox(height: spacing.md),
        Text('Profilfoto ist verpflichtend. Aufnahme über Kamera (Desktop/Mobil), Upload nur im Web.',
            style: typography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
      ],
    );

    if (context.isCompact) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoPicker(onPicked: (data) => _profilePhoto = data, required: true),
            SizedBox(height: spacing.md),
            form,
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _PhotoPicker(onPicked: (data) => _profilePhoto = data, required: true)),
          SizedBox(width: spacing.lg),
          Expanded(flex: 2, child: form),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final spacing = context.spacing;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row2(
            TextInput(label: 'Notfall Vorname', controller: _emFirstName, required: true),
            TextInput(label: 'Notfall Nachname', controller: _emLastName, required: true),
          ),
          SizedBox(height: spacing.md),
          PhoneInput(label: 'Notfall Telefonnummer', controller: _emPhone, required: true),
        ],
      ),
    );
  }

  Widget _buildStep3(BuildContext context) {
    final spacing = context.spacing;
    final children = _children.map((c) => _ChildTile(
          child: c,
          onRemove: () => setState(() => _children.remove(c)),
        ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline-Eingabezeile
        Row(
          children: [
            Expanded(child: TextInput(label: 'Vorname', controller: _childFirst, required: true)),
            SizedBox(width: spacing.md),
            Expanded(child: TextInput(label: 'Nachname', controller: _childLast, required: true)),
          ],
        ),
        SizedBox(height: spacing.md),
        Row(
          children: [
            Expanded(
              child: VerticOutlineButton(
                text: _childBirth == null
                    ? 'Geburtsdatum wählen'
                    : DateFormat('dd.MM.yyyy').format(_childBirth!),
          onPressed: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
              context: context,
                    firstDate: DateTime(1900),
                    initialDate: DateTime(now.year - 10, now.month, now.day),
                    lastDate: now,
                  );
                  if (date != null) setState(() => _childBirth = date);
                },
              ),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: _GenderDropdown(
                value: _childGender,
                onChanged: (g) => setState(() => _childGender = g),
              ),
            ),
            SizedBox(width: spacing.md),
            PrimaryButton(
              text: 'Hinzufügen',
              onPressed: () {
                if (_childFirst.text.isEmpty || _childLast.text.isEmpty || _childBirth == null || _childGender == null) {
                  return;
                }
                setState(() {
                  _children.add(_ChildDraft(_childFirst.text.trim(), _childLast.text.trim(), _childBirth!, _childGender!));
                  _childFirst.clear();
                  _childLast.clear();
                  _childBirth = null;
                  _childGender = null;
                });
              },
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        Wrap(spacing: spacing.md, runSpacing: spacing.md, children: children.toList()),
      ],
    );
  }

  Widget _buildStep4(BuildContext context) {
    final spacing = context.spacing;

    final colors = context.colors;
    final typography = context.typography;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Übersicht', style: typography.titleMedium),
          SizedBox(height: spacing.md),
          _summaryRow('Name', '${_firstName.text} ${_lastName.text}'),
          _summaryRow('Geburtsdatum', _birthDate.text),
          _summaryRow('E-Mail', _email.text),
          _summaryRow('Telefon', _phone.text.isEmpty ? '—' : _phone.text),
          _summaryRow('Adresse', _address.text),
          _summaryRow('Geschlecht', _gender ?? '—'),
          SizedBox(height: spacing.lg),
          Text('Zustimmungen', style: typography.titleSmall),
          CheckboxListTile(
            value: _agreedHouseRules,
            onChanged: (v) => setState(() => _agreedHouseRules = v ?? false),
            title: const Text('Ich akzeptiere die Hallenordnung'),
          ),
          CheckboxListTile(
            value: _agreedAGB,
            onChanged: (v) => setState(() => _agreedAGB = v ?? false),
            title: const Text('Ich akzeptiere die Vertic AGBs'),
          ),
          CheckboxListTile(
            value: _agreedPrivacy,
            onChanged: (v) => setState(() => _agreedPrivacy = v ?? false),
            title: const Text('Ich akzeptiere die Datenschutzbestimmungen'),
          ),
          if (!(_agreedHouseRules && _agreedAGB && _agreedPrivacy))
            Text('Bitte alle Zustimmungen geben', style: typography.labelSmall.copyWith(color: colors.error)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    final typography = context.typography;
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(label, style: typography.labelMedium.copyWith(color: colors.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: typography.bodyMedium)),
        ],
      ),
    );
  }

  Widget _row2(Widget a, Widget b) {
    if (context.isCompact) {
      return Column(children: [a, SizedBox(height: context.spacing.md), b]);
    }
    return Row(children: [Expanded(child: a), SizedBox(width: context.spacing.md), Expanded(child: b)]);
  }

  void _prev() {
    setState(() => _currentStep = (_currentStep - 1).clamp(0, 3));
    _controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  Future<void> _handlePrimary() async {
    if (_currentStep < 3) {
      if (!_validateStep(_currentStep)) return;
      setState(() => _currentStep++);
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      return;
    }

    if (!(_agreedHouseRules && _agreedAGB && _agreedPrivacy)) return;

    final client = Provider.of<Client>(context, listen: false);
    try {
      // Registrierung direkt via unifiedAuth
      final tmpPassword = _generateTempPassword();
      final signupOk = await client.unifiedAuth.clientSignUpUnified(
        _email.text.trim(),
        tmpPassword,
        _firstName.text.trim(),
        _lastName.text.trim(),
      );
      if (!signupOk) throw Exception('Registrierung fehlgeschlagen');

      // Profil speichern
      final birth = _parseDate(_birthDate.text);
      final profile = await client.unifiedAuth.completeClientRegistration(
        _firstName.text.trim(),
        _lastName.text.trim(),
        null,
        birth,
        _gender,
        _address.text.trim(),
        null,
        null,
        _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (profile == null) throw Exception('Profil konnte nicht gespeichert werden');

      // Foto optional hochladen
      if (_profilePhoto != null) {
        await client.userProfile.uploadProfilePhoto(_email.text.trim(), _profilePhoto!);
      }

      // Kinder anlegen
      for (final c in _children) {
        await client.userProfile.addChildAccount(
          profile.id!,
          c.firstName,
          c.lastName,
          c.birthDate,
          c.gender,
          address: _address.text.trim(),
        );
      }

      if (!mounted) return;
      _showWelcome();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }

  DateTime? _parseDate(String v) {
    try {
      final parts = v.split('.');
      if (parts.length != 3) return null;
      final d = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final y = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  String _generateTempPassword() => 'Tmp@${DateTime.now().millisecondsSinceEpoch % 100000}X';

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        final hasPhoto = _profilePhoto != null;
        return _firstName.text.isNotEmpty &&
            _lastName.text.isNotEmpty &&
            _email.text.contains('@') &&
            _birthDate.text.isNotEmpty &&
            _address.text.isNotEmpty &&
            _gender != null &&
            hasPhoto;
      case 1:
        return _emFirstName.text.isNotEmpty && _emLastName.text.isNotEmpty && _emPhone.text.isNotEmpty;
      case 2:
        return true; // Kinder optional
      default:
        return true;
    }
  }

  Future<void> _showWelcome() async {
    final spacing = context.spacing;
    final typography = context.typography;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: context.spacing.iconXl),
              SizedBox(height: spacing.md),
              Text('Willkommen bei Vertic!', style: typography.titleLarge),
            ],
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pop(); // Dialog
    // Zurück zum Start der Registrierung
    setState(() {
      _currentStep = 0;
      _controller.jumpToPage(0);
    });
  }
}

class _PhotoPicker extends StatefulWidget {
  final ValueChanged<ByteData?> onPicked;
  final bool required;
  const _PhotoPicker({required this.onPicked, this.required = false});
  @override
  State<_PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<_PhotoPicker> {
  ByteData? _data;
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(spacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: typography.labelMedium.copyWith(color: colors.onSurface),
              children: [
                const TextSpan(text: 'Profilbild'),
                if (widget.required)
                  TextSpan(text: ' *', style: TextStyle(color: colors.error)),
              ],
            ),
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(spacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: _data == null
                    ? Icon(Icons.person, color: colors.onSurfaceVariant)
                    : Icon(Icons.check, color: Colors.green),
              ),
              SizedBox(width: spacing.md),
              _PhotoActions(
                onPicked: (d) {
                  setState(() => _data = d);
                  widget.onPicked(d);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoActions extends StatelessWidget {
  final ValueChanged<ByteData?> onPicked;
  const _PhotoActions({required this.onPicked});

  Future<void> _pickFromWeb() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes != null) {
      onPicked(ByteData.sublistView(file!.bytes!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final spacing = context.spacing;
    return Row(
      children: [
        PrimaryButton(
          text: 'Foto aufnehmen',
          onPressed: () async {
            try {
              if (kIsWeb) {
                // Im Web keine explizite Kameraberechtigung → Upload nutzen
                await _pickFromWeb();
                return;
              }
              // Plattformen mit verlässlicher Kamera-Unterstützung
              final supportsCamera = (Platform.isAndroid || Platform.isIOS);
              if (supportsCamera) {
                final picker = ImagePicker();
                final x = await picker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.front,
                );
                if (x != null) {
                  final bytes = await x.readAsBytes();
                  onPicked(ByteData.sublistView(bytes));
                }
                return;
              }
              // macOS/Windows/Linux Fallback: Datei wählen
              await _pickFromWeb();
            } catch (e) {
              // Zeige klare Fehlermeldung, wenn Kamera nicht verfügbar/erlaubt ist
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kamera nicht verfügbar: $e')),
              );
            }
          },
        ),
        SizedBox(width: spacing.sm),
        if (isWeb)
          VerticOutlineButton(
            text: 'Datei wählen',
            onPressed: () async {
              await _pickFromWeb();
            },
          ),
      ],
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  final String? value; final ValueChanged<String> onChanged;
  const _GenderDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: const [
        DropdownMenuItem(value: 'männlich', child: Text('männlich')),
        DropdownMenuItem(value: 'weiblich', child: Text('weiblich')),
        DropdownMenuItem(value: 'divers', child: Text('divers')),
      ],
      onChanged: (v) { if (v != null) onChanged(v); },
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Geschlecht (m/w/d)'),
    );
  }
}

class _ChildDraft {
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String gender;
  _ChildDraft(this.firstName, this.lastName, this.birthDate, this.gender);
}

class _ChildTile extends StatelessWidget {
  final _ChildDraft child;
  final VoidCallback onRemove;
  const _ChildTile({required this.child, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(spacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.child_care, color: colors.primary),
          SizedBox(width: spacing.sm),
          Text('${child.firstName} ${child.lastName} • ${DateFormat('dd.MM.yyyy').format(child.birthDate)}',
              style: typography.bodyMedium),
          SizedBox(width: spacing.md),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}

class _ChildDialog extends StatefulWidget {
  const _ChildDialog();
  @override
  State<_ChildDialog> createState() => _ChildDialogState();
}

class _ChildDialogState extends State<_ChildDialog> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _birth;
  String? _gender;
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return AlertDialog(
      title: const Text('Kind hinzufügen'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextInput(label: 'Vorname', controller: _first, required: true),
            SizedBox(height: spacing.md),
            TextInput(label: 'Nachname', controller: _last, required: true),
            SizedBox(height: spacing.md),
            VerticOutlineButton(
              text: _birth == null ? 'Geburtsdatum wählen' : DateFormat('dd.MM.yyyy').format(_birth!),
              onPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 18, now.month, now.day),
                  initialDate: DateTime(now.year - 10, now.month, now.day),
                  lastDate: now,
                );
                if (date != null) setState(() => _birth = date);
              },
            ),
            SizedBox(height: spacing.md),
            VerticOutlineButton(
              text: _gender ?? 'Geschlecht wählen',
              onPressed: () async {
                final g = await showMenu<String>(
                  context: context,
                  position: const RelativeRect.fromLTRB(200, 200, 0, 0),
                  items: const [
                    PopupMenuItem(value: 'männlich', child: Text('männlich')),
                    PopupMenuItem(value: 'weiblich', child: Text('weiblich')),
                    PopupMenuItem(value: 'divers', child: Text('divers')),
                  ],
                );
                if (g != null) setState(() => _gender = g);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
        PrimaryButton(
          text: 'Hinzufügen',
          onPressed: () {
            if (_first.text.isEmpty || _last.text.isEmpty || _birth == null || _gender == null) return;
            Navigator.of(context).pop(_ChildDraft(_first.text.trim(), _last.text.trim(), _birth!, _gender!));
          },
        )
      ],
    );
  }
}


