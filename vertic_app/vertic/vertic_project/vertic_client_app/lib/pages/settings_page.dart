import 'package:flutter/material.dart';
import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';
import 'package:test_server_client/test_server_client.dart';
import '../main.dart';
import 'profile_page.dart';
import 'status_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: Column(
        children: [
          // Profil-Eintrag
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mein Profil'),
            subtitle: const Text('Persönliche Informationen bearbeiten'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyHomePage(title: 'Mein Profil'),
                ),
              );
            },
          ),
          const Divider(),

          // Kennwort ändern
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Kennwort ändern'),
            subtitle: const Text('Sicherheitseinstellungen verwalten'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementiere Kennwort-Änderungsseite
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Kennwortänderung noch nicht implementiert')),
              );
            },
          ),
          const Divider(),

          // Datenschutzrichtlinie
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Datenschutzrichtlinie'),
            subtitle: const Text(
                'Informationen zu Datenschutz und Nutzungsbedingungen'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementiere Datenschutzseite
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Datenschutzrichtlinie noch nicht implementiert')),
              );
            },
          ),
          const Divider(),

          // Benachrichtigungen
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Benachrichtigungen'),
            subtitle: const Text('Einstellungen für Push-Nachrichten'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementiere Benachrichtigungsseite
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Benachrichtigungseinstellungen noch nicht implementiert')),
              );
            },
          ),
          const Divider(),

          // Ermäßigung beantragen (Status)
          if (sessionManager.isSignedIn && sessionManager.signedInUser != null)
            FutureBuilder<AppUser?>(
              // ✅ UNIFIED AUTH: Verwende neuen Unified Endpoint
              future: client.unifiedAuth.getCurrentUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.discount),
                        title: const Text('Ermäßigung beantragen'),
                        subtitle: const Text(
                            'Beantrage einen Status (z.B. Ermäßigung) und lade einen Nachweis hoch.'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  StatusPage(user: snapshot.data!),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),

          // Abmelden
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Abmelden', style: TextStyle(color: Colors.red)),
            onTap: () async {
              try {
                await sessionManager.signOutDevice();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const WelcomePage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Abmelden: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class StatusWidget extends StatefulWidget {
  const StatusWidget({super.key, required this.user});
  final AppUser user;

  @override
  State<StatusWidget> createState() => _StatusWidgetState();
}

class _StatusWidgetState extends State<StatusWidget> {
  List<UserStatusType> _statusTypes = [];
  int? _selectedStatusTypeId;
  String? _uploadPath;
  bool _isLoadingStatus = false;
  String? _statusMessage;
  List<UserStatus> _userStatuses = [];

  @override
  void initState() {
    super.initState();
    _loadStatusTypes();
    _loadUserStatuses();
  }

  Future<void> _loadStatusTypes() async {
    setState(() => _isLoadingStatus = true);
    try {
      final types = await client.userStatus.getAllStatusTypes();
      final filtered =
          types.where((t) => t.name.toLowerCase() != 'standard').toList();
      setState(() {
        _statusTypes = filtered;
        if (filtered.isNotEmpty) _selectedStatusTypeId = filtered.first.id;
      });
    } catch (e) {
      setState(() => _statusMessage = 'Fehler beim Laden der Statusarten: $e');
    } finally {
      setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _loadUserStatuses() async {
    try {
      final statuses = await client.userStatus.getUserStatuses(widget.user.id!);
      setState(() => _userStatuses = statuses);
    } catch (e) {
      setState(() => _statusMessage = 'Fehler beim Laden des Status: $e');
    }
  }

  Future<void> _pickFile() async {
    // TODO: File-Picker später implementieren wenn Package verfügbar
    setState(() => _statusMessage = 'File-Upload noch nicht implementiert');
  }

  Future<void> _requestStatus() async {
    if (_selectedStatusTypeId == null) return;
    setState(() => _isLoadingStatus = true);
    try {
      final status = UserStatus(
        userId: widget.user.id!,
        statusTypeId: _selectedStatusTypeId!,
        isVerified: false,
        documentationPath: _uploadPath,
        createdAt: DateTime.now(),
      );
      await client.userStatus.requestStatus(status);
      setState(() => _statusMessage = 'Status-Antrag erfolgreich gestellt!');
      _loadUserStatuses();
    } catch (e) {
      setState(() => _statusMessage = 'Fehler beim Beantragen: $e');
    } finally {
      setState(() => _isLoadingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ermäßigung beantragen',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_isLoadingStatus) const CircularProgressIndicator(),
            if (!_isLoadingStatus) ...[
              DropdownButtonFormField<int>(
                value: _selectedStatusTypeId,
                items: _statusTypes
                    .map((type) => DropdownMenuItem(
                          value: type.id,
                          child: Text(type.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStatusTypeId = val),
                decoration:
                    const InputDecoration(labelText: 'Statusart wählen'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_uploadPath == null
                    ? 'Nachweis hochladen'
                    : 'Datei ausgewählt'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _requestStatus,
                child: const Text('Status beantragen'),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(_statusMessage!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const Divider(),
              const Text('Deine bisherigen Status:'),
              ..._userStatuses.map((s) => ListTile(
                    title: Text(_statusTypes
                        .firstWhere(
                          (t) => t.id == s.statusTypeId,
                          orElse: () => UserStatusType(
                            id: 0,
                            name: 'Unbekannt',
                            description: 'Unbekannt',
                            discountPercentage: 0,
                            requiresVerification: false,
                            requiresDocumentation: false,
                            validityPeriod: 365,
                            createdAt: DateTime.now(),
                          ),
                        )
                        .name),
                    subtitle: Text(s.isVerified ? 'Verifiziert' : 'Offen'),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
