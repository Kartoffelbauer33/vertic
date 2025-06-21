import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';

class SystemMessagesPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool, String?)? onUnsavedChanges;

  const SystemMessagesPage({
    super.key,
    this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<SystemMessagesPage> createState() => _SystemMessagesPageState();
}

class _SystemMessagesPageState extends State<SystemMessagesPage> {
  List<SystemMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemMessages();
  }

  Future<void> _loadSystemMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lade alle Ticket-Typen und User-Status
      final ticketTypes = await client.ticketType.getAllTicketTypes();
      final userStatusTypes = await client.userStatus.getAllStatusTypes();

      List<SystemMessage> messages = [];

      // Prüfe für jeden Altersbereich (Kind, Erwachsen, Senior)
      // und jeden Status, ob Tickets verfügbar sind
      final ageGroups = [
        {'name': 'Kinder (0-17)', 'minAge': 0, 'maxAge': 17},
        {'name': 'Erwachsene (18-64)', 'minAge': 18, 'maxAge': 64},
        {'name': 'Senioren (65+)', 'minAge': 65, 'maxAge': 120},
      ];

      for (final ageGroup in ageGroups) {
        for (final status in userStatusTypes) {
          // Prüfe Einzeltickets
          final singleTickets = ticketTypes
              .where((t) => !t.isSubscription && !t.isPointBased)
              .toList();
          if (singleTickets.isEmpty) {
            messages.add(SystemMessage(
              type: MessageType.warning,
              title: 'Keine Einzeltickets verfügbar',
              message:
                  'Für ${ageGroup['name']} mit Status "${status.name}" sind keine Einzeltickets verfügbar.',
              category: 'Ticket-Verfügbarkeit',
            ));
          }

          // Prüfe Monatsabos
          final monthlyTickets = ticketTypes
              .where((t) => t.isSubscription && t.billingInterval == -1)
              .toList();
          if (monthlyTickets.isEmpty) {
            messages.add(SystemMessage(
              type: MessageType.info,
              title: 'Keine Monatsabos verfügbar',
              message:
                  'Für ${ageGroup['name']} mit Status "${status.name}" sind keine Monatsabos verfügbar.',
              category: 'Abonnement-Verfügbarkeit',
            ));
          }

          // Prüfe Jahreskarten
          final yearlyTickets = ticketTypes
              .where((t) => t.isSubscription && t.billingInterval == -12)
              .toList();
          if (yearlyTickets.isEmpty) {
            messages.add(SystemMessage(
              type: MessageType.info,
              title: 'Keine Jahreskarten verfügbar',
              message:
                  'Für ${ageGroup['name']} mit Status "${status.name}" sind keine Jahreskarten verfügbar.',
              category: 'Abonnement-Verfügbarkeit',
            ));
          }
        }
      }

      // Entferne Duplikate basierend auf Titel
      final uniqueMessages = <String, SystemMessage>{};
      for (final message in messages) {
        uniqueMessages[message.title] = message;
      }

      setState(() {
        _messages = uniqueMessages.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages = [
          SystemMessage(
            type: MessageType.error,
            title: 'Fehler beim Laden',
            message: 'Fehler beim Laden der System-Meldungen: $e',
            category: 'System-Fehler',
          )
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom AppBar
        Container(
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    'System-Meldungen',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadSystemMessages,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Info-Header
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade600,
                            Colors.amber.shade400
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_active,
                                  color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'System-Meldungen',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Übersicht über Warnungen und Hinweise zu fehlenden Ticket-Status-Kombinationen.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Statistiken
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Warnungen',
                              _messages
                                  .where((m) => m.type == MessageType.warning)
                                  .length,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Hinweise',
                              _messages
                                  .where((m) => m.type == MessageType.info)
                                  .length,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Fehler',
                              _messages
                                  .where((m) => m.type == MessageType.error)
                                  .length,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Meldungen-Liste
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 64, color: Colors.green),
                                  SizedBox(height: 16),
                                  Text(
                                    'Keine System-Meldungen',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.green),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Alle Ticket-Status-Kombinationen sind verfügbar',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadSystemMessages,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return _buildMessageCard(message);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(SystemMessage message) {
    Color getTypeColor() {
      switch (message.type) {
        case MessageType.warning:
          return Colors.orange;
        case MessageType.error:
          return Colors.red;
        case MessageType.info:
          return Colors.blue;
      }
    }

    IconData getTypeIcon() {
      switch (message.type) {
        case MessageType.warning:
          return Icons.warning;
        case MessageType.error:
          return Icons.error;
        case MessageType.info:
          return Icons.info;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(getTypeIcon(), color: getTypeColor(), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getTypeColor(),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getTypeColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.category,
                    style: TextStyle(
                      color: getTypeColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.message,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Datenmodell für System-Meldungen
enum MessageType { warning, error, info }

class SystemMessage {
  final MessageType type;
  final String title;
  final String message;
  final String category;

  SystemMessage({
    required this.type,
    required this.title,
    required this.message,
    required this.category,
  });
}
