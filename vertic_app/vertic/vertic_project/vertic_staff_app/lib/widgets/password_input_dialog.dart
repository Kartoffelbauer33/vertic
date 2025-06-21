import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🔐 **PASSWORD INPUT DIALOG** (Phase 3.3)
///
/// Wiederverwendbares Dialog-Widget für sichere Passwort-Eingabe
/// bei der Staff-User-Erstellung mit Validierung und Sicherheitsfeatures
class PasswordInputDialog extends StatefulWidget {
  final String staffName;
  final String username;
  final VoidCallback? onCancel;

  const PasswordInputDialog({
    super.key,
    required this.staffName,
    required this.username,
    this.onCancel,
  });

  /// **Zeigt den Password-Dialog und gibt das Passwort zurück**
  ///
  /// Returns: String? - Das eingegebene Passwort oder null bei Abbruch
  static Future<String?> show({
    required BuildContext context,
    required String staffName,
    required String username,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // Verhindert Schließen durch Tippen außerhalb
      builder: (context) => PasswordInputDialog(
        staffName: staffName,
        username: username,
      ),
    );
  }

  @override
  State<PasswordInputDialog> createState() => _PasswordInputDialogState();
}

class _PasswordInputDialogState extends State<PasswordInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isGenerating = false;

  // Password Strength Indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumbers = false;
  bool _hasSpecialChars = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// **Validiert Passwort-Stärke in Echtzeit**
  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumbers = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  /// **Generiert ein sicheres Zufallspasswort**
  void _generateSecurePassword() {
    setState(() {
      _isGenerating = true;
    });

    // Sichere Passwort-Generierung
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    const length = 12;

    final random = DateTime.now().millisecondsSinceEpoch;
    String password = '';

    // Stelle sicher, dass alle Kategorien enthalten sind
    password +=
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[(random + 1) % 26]; // Großbuchstabe
    password +=
        'abcdefghijklmnopqrstuvwxyz'[(random + 2) % 26]; // Kleinbuchstabe
    password += '0123456789'[(random + 3) % 10]; // Zahl
    password += '!@#\$%^&*'[(random + 4) % 9]; // Sonderzeichen

    // Fülle den Rest zufällig auf
    for (int i = 4; i < length; i++) {
      password += chars[(random + i * 7) % chars.length];
    }

    // Mische das Passwort
    final passwordList = password.split('');
    for (int i = passwordList.length - 1; i > 0; i--) {
      final j = (random + i) % (i + 1);
      final temp = passwordList[i];
      passwordList[i] = passwordList[j];
      passwordList[j] = temp;
    }

    final generatedPassword = passwordList.join('');

    setState(() {
      _passwordController.text = generatedPassword;
      _confirmPasswordController.text = generatedPassword;
      _isGenerating = false;
    });

    // Zeige Bestätigung
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔐 Sicheres Passwort generiert!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// **Kopiert Passwort in die Zwischenablage**
  void _copyToClipboard() {
    if (_passwordController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _passwordController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Passwort in Zwischenablage kopiert'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// **Berechnet Passwort-Stärke (0-100)**
  int _getPasswordStrength() {
    int strength = 0;
    if (_hasMinLength) strength += 20;
    if (_hasUppercase) strength += 20;
    if (_hasLowercase) strength += 20;
    if (_hasNumbers) strength += 20;
    if (_hasSpecialChars) strength += 20;
    return strength;
  }

  /// **Gibt Passwort-Stärke-Farbe zurück**
  Color _getStrengthColor() {
    final strength = _getPasswordStrength();
    if (strength < 40) return Colors.red;
    if (strength < 60) return Colors.orange;
    if (strength < 80) return Colors.yellow[700]!;
    return Colors.green;
  }

  /// **Gibt Passwort-Stärke-Text zurück**
  String _getStrengthText() {
    final strength = _getPasswordStrength();
    if (strength < 40) return 'Schwach';
    if (strength < 60) return 'Mittel';
    if (strength < 80) return 'Gut';
    return 'Sehr sicher';
  }

  /// **Validiert das Passwort-Formular**
  String? _validatePasswordField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Passwort ist erforderlich';
    }
    if (value.length < 8) {
      return 'Passwort muss mindestens 8 Zeichen haben';
    }
    if (_getPasswordStrength() < 60) {
      return 'Passwort ist zu schwach';
    }
    return null;
  }

  /// **Validiert die Passwort-Bestätigung**
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Passwort-Bestätigung ist erforderlich';
    }
    if (value != _passwordController.text) {
      return 'Passwörter stimmen nicht überein';
    }
    return null;
  }

  /// **Behandelt die Passwort-Bestätigung**
  void _handleConfirm() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔐 Passwort festlegen'),
                Text(
                  'für ${widget.staffName} (${widget.username})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passwort-Eingabe
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Passwort *',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'In Zwischenablage kopieren',
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          }),
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          tooltip: _isPasswordVisible
                              ? 'Passwort verbergen'
                              : 'Passwort anzeigen',
                        ),
                      ],
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validatePasswordField,
                ),
                const SizedBox(height: 16),

                // Passwort-Bestätigung
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Passwort bestätigen *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      }),
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 16),

                // Passwort generieren Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _generateSecurePassword,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(_isGenerating
                        ? 'Generiere...'
                        : 'Sicheres Passwort generieren'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Passwort-Stärke Anzeige
                if (_passwordController.text.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('Passwort-Stärke: ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        _getStrengthText(),
                        style: TextStyle(
                          color: _getStrengthColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text('$strength%',
                          style: TextStyle(color: _getStrengthColor())),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: strength / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                  ),
                  const SizedBox(height: 16),

                  // Passwort-Anforderungen
                  const Text('Anforderungen:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _buildRequirement('Mindestens 8 Zeichen', _hasMinLength),
                  _buildRequirement('Großbuchstaben (A-Z)', _hasUppercase),
                  _buildRequirement('Kleinbuchstaben (a-z)', _hasLowercase),
                  _buildRequirement('Zahlen (0-9)', _hasNumbers),
                  _buildRequirement(
                      'Sonderzeichen (!@#\$%^&*)', _hasSpecialChars),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: strength >= 60 ? _handleConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Passwort verwenden'),
        ),
      ],
    );
  }

  /// **Erstellt eine Anforderungs-Zeile mit Check-Icon**
  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
