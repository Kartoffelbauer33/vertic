import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:typed_data'; // Für ByteData
import 'settings_page.dart';
import 'ticket_purchase_page.dart';
import '../main.dart'; // Für Zugriff auf client und sessionManager

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;
  AppUser? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      if (sessionManager.isSignedIn && sessionManager.signedInUser != null) {
        final email = sessionManager.signedInUser!.email;
        if (email != null) {
          // ✅ UNIFIED AUTH: Verwende neuen Unified Endpoint
          final user = await client.unifiedAuth.getCurrentUserProfile();
          setState(() {
            _user = user;
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Benutzerdaten: $e');
    } finally {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  // Vereinfachte Seitenstruktur: Nur Ticket, ID, Settings
  List<Widget> _buildPages() {
    return [
      // Ticket Tab - JETZT ERSTE POSITION für Ticketverkauf-Fokus
      _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Text('Benutzerdetails nicht verfügbar'),
                )
              : TicketPurchasePage(
                  sessionManager: sessionManager,
                  client: client,
                  user: _user!,
                ),

      // ID Tab - ZWEITE POSITION
      _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Text('Benutzerdetails nicht verfügbar'),
                )
              : IdPage(
                  sessionManager: sessionManager,
                  client: client,
                  user: _user!,
                ),

      // Settings Tab - DRITTE POSITION
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildPages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF00897B),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Ticket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: 'ID',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Neue ID-Seite mit rotierendem QR-Code
class IdPage extends StatefulWidget {
  final SessionManager sessionManager;
  final Client client;
  final AppUser user;

  const IdPage({
    super.key,
    required this.sessionManager,
    required this.client,
    required this.user,
  });

  @override
  State<IdPage> createState() => _IdPageState();
}

class _IdPageState extends State<IdPage> {
  UserIdentity? _userIdentity;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  ByteData? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _loadUserIdentity();
    _loadProfilePhoto();
    // Überprüfe alle 30 Sekunden, ob ein neuer QR-Code verfügbar ist
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadUserIdentity();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserIdentity() async {
    try {
      final identity = await widget.client.identity.getCurrentUserIdentity();
      setState(() {
        _userIdentity = identity;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der ID: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final email = widget.user.email;
      if (email != null) {
        final photoData =
            await widget.client.userProfile.getProfilePhoto(email);
        setState(() {
          _profilePhoto = photoData;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Profilbilds: $e');
      // Kein setState hier - Foto ist optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine ID'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserIdentity,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserIdentity,
                        child: Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Benutzerinformationen
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.2),
                                child: _profilePhoto != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          _profilePhoto!.buffer.asUint8List(),
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      )
                                    : Text(
                                        '${widget.user.firstName[0]}${widget.user.lastName[0]}',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '${widget.user.firstName} ${widget.user.lastName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.user.email ?? 'Keine E-Mail',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24),

                              // QR-Code
                              if (_userIdentity != null)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.grey.withValues(alpha: 0.2),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: QrImageView(
                                    data: _userIdentity!.qrCodeData,
                                    version: QrVersions.auto,
                                    size: 200, // Feste, angemessene Größe
                                    gapless: false,
                                    eyeStyle: QrEyeStyle(
                                      eyeShape: QrEyeShape.circle,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                              SizedBox(height: 16),

                              // Nur allgemeine Info - KEINE sensiblen Daten mehr
                              Text(
                                'Für Check-in an der Rezeption vorzeigen',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Info-Text
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(height: 8),
                              Text(
                                'Dieser QR-Code ist deine persönliche ID für den Check-in. '
                                'Nach jedem erfolgreichen Check-in wird automatisch ein neuer QR-Code generiert.',
                                style: TextStyle(color: Colors.blue.shade700),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
