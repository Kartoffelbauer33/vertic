import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/staff_auth_provider.dart';
import '../auth/permission_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final staffAuth = Provider.of<StaffAuthProvider>(context, listen: false);

    // Staff-Login-Versuch
    final success = await staffAuth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        // Login erfolgreich - Navigation erfolgt automatisch über Consumer in main.dart
        debugPrint('✅ Staff-Login erfolgreich');

        // RBAC Permissions laden
        final permissionProvider =
            Provider.of<PermissionProvider>(context, listen: false);
        if (staffAuth.currentStaffUser?.id != null) {
          await permissionProvider
              .fetchPermissionsForStaff(staffAuth.currentStaffUser!.id!);
          debugPrint(
              '🔐 RBAC Permissions geladen: ${permissionProvider.permissions.length}');
        }
      } else {
        // Login fehlgeschlagen - Fehlermeldung anzeigen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(staffAuth.lastError ?? 'Login fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StaffAuthProvider>(
        builder: (context, staffAuth, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🎯 Logo & Titel
                            const Icon(
                              Icons.admin_panel_settings,
                              size: 80,
                              color: Color(0xFF00897B),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Vertic Staff',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00897B),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Staff-Authentication System',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 32),

                            // 📧 Email/Username Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !staffAuth.isLoading,
                              decoration: InputDecoration(
                                labelText: 'E-Mail oder Benutzername',
                                hintText: 'admin@vertic.local oder superuser',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'E-Mail oder Benutzername eingeben';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 🔒 Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              enabled: !staffAuth.isLoading,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Passwort',
                                hintText: 'Passwort eingeben',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Passwort eingeben';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // 🚀 Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed:
                                    staffAuth.isLoading ? null : _handleLogin,
                                icon: staffAuth.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.login),
                                label: Text(
                                  staffAuth.isLoading
                                      ? 'Wird angemeldet...'
                                      : 'Anmelden',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00897B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            // ⚠️ Error Display
                            if (staffAuth.lastError != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error,
                                        color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        staffAuth.lastError!,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // 💡 Demo-Credentials Hint
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.info,
                                          color: Colors.blue, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Demo-Zugang:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Benutzername: superuser\nPasswort: super123',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
