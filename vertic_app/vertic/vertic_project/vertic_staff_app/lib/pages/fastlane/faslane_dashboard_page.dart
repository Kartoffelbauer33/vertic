// Tippfehler-Datei belassen, leitet auf FastlanePage weiter oder zeigt Auswahl
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';
import 'package:vertic_staff/pages/fastlane/fastlane_page.dart';

/// Minimaler, integrierter Login-Screen für Fastlane-Modus, der gegen den
/// Server authentifiziert und danach per Callback die Client-Session bereitstellt.
class FastlaneLoginPanel extends StatefulWidget {
  final Client client;
  final void Function(SessionManager sessionManager, EmailAuthController emailAuth) onLoggedIn;
  const FastlaneLoginPanel({super.key, required this.client, required this.onLoggedIn});

  @override
  State<FastlaneLoginPanel> createState() => _FastlaneLoginPanelState();
}

class _FastlaneLoginPanelState extends State<FastlaneLoginPanel> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  late final SessionManager _sessionManager;
  late final EmailAuthController _emailAuth;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager(caller: widget.client.modules.auth);
    _emailAuth = EmailAuthController(widget.client.modules.auth);
    _sessionManager.initialize();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final userInfo = await _emailAuth.signIn(_email.text.trim(), _password.text);
      if (userInfo == null) {
        setState(() { _error = 'Anmeldung fehlgeschlagen'; });
      } else {
        if (!mounted) return;
        widget.onLoggedIn(_sessionManager, _emailAuth);
      }
    } catch (e) {
      setState(() { _error = 'Fehler: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'E-Mail', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v?.contains('@') ?? false) ? null : 'Gültige E-Mail eingeben',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Passwort', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => (v != null && v.isNotEmpty) ? null : 'Passwort eingeben',
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _doLogin,
                  child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Anmelden'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class FaslaneDashboardPage extends StatelessWidget {
  const FaslaneDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FastlanePage();
  }
}

/// Vollbild-Ansicht nach erfolgreichem Fastlane-Login mit Tabs: ID, Abos, Profil
class FastlaneClientHome extends StatefulWidget {
  final Client client;
  const FastlaneClientHome({super.key, required this.client});

  @override
  State<FastlaneClientHome> createState() => _FastlaneClientHomeState();
}

class _FastlaneClientHomeState extends State<FastlaneClientHome> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  AppUser? _appUser;
  UserIdentity? _identity;
  ByteData? _profilePhoto;
  List<UserExternalMembership> _memberships = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final appUser = await widget.client.unifiedAuth.getCurrentUserProfile();
      if (appUser == null) {
        setState(() { _error = 'Profil nicht verfügbar'; _loading = false; });
        return;
      }
      final identity = await widget.client.identity.getCurrentUserIdentity();
      final email = appUser.email;
      ByteData? photo;
      if (email != null) {
        photo = await widget.client.userProfile.getProfilePhoto(email);
      }
      final memberships = await widget.client.externalProvider
          .getUserMemberships(appUser.id!);
      setState(() {
        _appUser = appUser;
        _identity = identity;
        _profilePhoto = photo;
        _memberships = memberships;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Fehler: $e'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fastlane – Mein Bereich'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.badge), text: 'ID'),
            Tab(icon: Icon(Icons.card_membership), text: 'Abos'),
            Tab(icon: Icon(Icons.person), text: 'Profil'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIdTab(),
                    _buildMembershipsTab(),
                    _buildProfileTab(),
                  ],
                ),
    );
  }

  Widget _buildIdTab() {
    final user = _appUser!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            child: _profilePhoto != null
                ? ClipOval(
                    child: Image.memory(
                      _profilePhoto!.buffer.asUint8List(),
                      fit: BoxFit.cover,
                      width: 96,
                      height: 96,
                    ),
                  )
                : Text(
                    '${user.firstName[0]}${user.lastName[0]}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 12),
          Text('${user.firstName} ${user.lastName}', style: Theme.of(context).textTheme.titleLarge),
          Text(user.email ?? '—'),
          const SizedBox(height: 24),
          if (_identity != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: UserQrDisplay(data: _identity!.qrCodeData),
            ),
          const SizedBox(height: 8),
          const Text('Für Check-in an der Rezeption vorzeigen'),
        ],
      ),
    );
  }

  Widget _buildMembershipsTab() {
    if (_memberships.isEmpty) {
      return const Center(child: Text('Keine Mitgliedschaften'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _memberships.length,
      itemBuilder: (context, index) {
        final m = _memberships[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.card_membership),
            title: Text('Provider ${m.providerId}'),
            subtitle: Text('ID: ${m.externalUserId}\nStatus: ${m.isActive == true ? 'AKTIV' : 'INAKTIV'}'),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final user = _appUser!;
    final birthText = user.birthDate != null ? DateFormat('dd.MM.yyyy').format(user.birthDate!) : '—';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _kv('Vorname', user.firstName),
        _kv('Nachname', user.lastName),
        _kv('E-Mail', user.email ?? '—'),
        _kv('Geburtsdatum', birthText),
        _kv('Geschlecht', user.gender ?? '—'),
        _kv('Adresse', user.address ?? '—'),
        _kv('Ort', user.city ?? '—'),
        _kv('PLZ', user.postalCode ?? '—'),
        _kv('Telefon', user.phoneNumber ?? '—'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _loadAll,
          icon: const Icon(Icons.refresh),
          label: const Text('Aktualisieren'),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

/// Kleines QR-Widget (vereinfachte Variante)
class UserQrDisplay extends StatelessWidget {
  final String data;
  const UserQrDisplay({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Minimaler Platzhalter: String anzeigen (in Client-App nutzen wir QrImageView)
    // Für Fastlane genügt eine klare Darstellung des Codes; Integration eines QR Widgets ist optional.
    return SelectableText(data, textAlign: TextAlign.center);
  }
}

