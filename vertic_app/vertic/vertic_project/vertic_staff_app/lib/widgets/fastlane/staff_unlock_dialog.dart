import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vertic_staff/auth/staff_auth_provider.dart';

class StaffUnlockDialog extends StatefulWidget {
  const StaffUnlockDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StaffUnlockDialog(),
    );
    return result == true;
  }

  @override
  State<StaffUnlockDialog> createState() => _StaffUnlockDialogState();
}

class _StaffUnlockDialogState extends State<StaffUnlockDialog> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fastlane entsperren'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: 'E-Mail oder Benutzername',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Pflichtfeld'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Pflichtfeld'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUnlock,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Entsperren'),
        ),
      ],
    );
  }

  Future<void> _handleUnlock() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final staffAuth = context.read<StaffAuthProvider>();
      final ok = await staffAuth.signIn(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = staffAuth.lastError ?? 'Anmeldung fehlgeschlagen');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }
}


