import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';

// Eigene Widget-Importe
import 'pages/registration_page.dart';
import 'pages/main_tab_controller.dart';
import 'config/environment.dart';

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app. The client is generated from your server code
/// and is set up to connect to a Serverpod running on a local server on
/// the default port. You will need to modify this to connect to staging or
/// production servers.
var client = Client('http://localhost:8080/');

// Globaler SessionManager
late SessionManager sessionManager;

void main() async {
  // Sicherstellen, dass Flutter Bindings initialisiert sind
  WidgetsFlutterBinding.ensureInitialized();

  // Client mit Environment-Konfiguration initialisieren
  client = Client(
    Environment.serverUrl,
    authenticationKeyManager: FlutterAuthenticationKeyManager(),
  )..connectivityMonitor = FlutterConnectivityMonitor();

  // Debug-Info ausgeben
  print('🚀 Vertic Client startet...');
  print('📡 Server: ${Environment.environmentInfo}');
  print('🔗 URL: ${Environment.serverUrl}');

  // SessionManager initialisieren
  sessionManager = SessionManager(
    caller: client.modules.auth,
  );
  await sessionManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertic - Deine Boulder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'),
      ],
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _loginErrorMessage;
  final _emailLoginFocusNode = FocusNode();
  final _passwordLoginFocusNode = FocusNode();

  // Instanz des EmailAuthController für die Login-Funktionalität
  late final EmailAuthController _emailAuthController;

  @override
  void initState() {
    super.initState();
    _emailAuthController = EmailAuthController(client.modules.auth);
    sessionManager.addListener(_onSessionChange);
  }

  @override
  void dispose() {
    sessionManager.removeListener(_onSessionChange);
    _emailController.dispose();
    _passwordController.dispose();
    _emailLoginFocusNode.dispose();
    _passwordLoginFocusNode.dispose();
    super.dispose();
  }

  void _onSessionChange() {
    setState(() {}); // UI neu zeichnen, wenn sich der Login-Status ändert
  }

  @override
  Widget build(BuildContext context) {
    // Wenn Benutzer eingeloggt ist, zum MainTabController navigieren
    if (sessionManager.isSignedIn) {
      return const MainTabController();
    }

    // Ansonsten Willkommensseite anzeigen
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade500],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/App-Name
                  const Icon(
                    Icons.terrain,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'VERTIC',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deine Boulder-Community',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login-Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _showLoginDialog(context);
                    },
                    child: const Text(
                      'Anmelden',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Registrierungs-Button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _showRegistrationDialog(context);
                    },
                    child: const Text(
                      'Registrieren',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dialog für Login anzeigen
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // dialogContext, um Verwechslung zu vermeiden
        return StatefulBuilder(
          // Für Fehlerstatus im Dialog
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Anmelden',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailLoginFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'E-Mail',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_passwordLoginFocusNode);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordLoginFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Passwort',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          // Hier Anmeldeversuch starten
                          _attemptLogin(dialogContext, setDialogState);
                        },
                      ),
                      if (_loginErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _loginErrorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50)),
                        onPressed: () {
                          _attemptLogin(dialogContext, setDialogState);
                        },
                        child: const Text('Anmelden'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop(); // Login-Dialog schließen
                          _clearLoginFields();
                        },
                        child: const Text('Abbrechen'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Nach Schließen des Dialogs die Felder und Fehlermeldung zurücksetzen
      _clearLoginFields();
    });
  }

  void _clearLoginFields() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _loginErrorMessage = null;
    });
  }

  Future<void> _attemptLogin(
      BuildContext dialogContext, StateSetter setDialogState) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setDialogState(() {
        _loginErrorMessage = 'E-Mail und Passwort dürfen nicht leer sein.';
      });
      return;
    }

    setDialogState(() {
      _loginErrorMessage = null;
    });

    try {
      // EINFACH: Nur natives Serverpod EmailAuth verwenden
      final userInfo = await _emailAuthController.signIn(email, password);
      if (userInfo != null) {
        // Erfolgreich angemeldet
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // Login-Dialog schließen
        }
        // WelcomePage wird durch den Listener auf sessionManager.isSignedIn automatisch zur MainTabController wechseln
      } else {
        setDialogState(() {
          _loginErrorMessage =
              'Anmeldung fehlgeschlagen. Bitte prüfe deine Eingaben.';
        });
      }
    } catch (e) {
      setDialogState(() {
        _loginErrorMessage = 'Fehler bei der Anmeldung: ${e.toString()}';
      });
    }
  }

  // Dialog für Registrierung anzeigen
  void _showRegistrationDialog(BuildContext context) {
    // Für die Registrierung nutzen wir das RegistrationPage-Widget
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegistrationPage(
          onRegistrationComplete: (String email, String password) {
            // Erweiterte Profildaten werden jetzt direkt in der RegistrationPage gespeichert
            debugPrint('Registration completed for: $email');
          },
        ),
      ),
    );
  }
}
