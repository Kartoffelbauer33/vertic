import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_server_client/test_server_client.dart';

class TicketDetailPage extends StatelessWidget {
  final Ticket ticket;
  final AppUser user;

  const TicketDetailPage({
    super.key,
    required this.ticket,
    required this.user,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _ticketTypeName(int id) {
    switch (id) {
      case 1:
        return 'Tageskarte Kind';
      case 2:
        return 'Tageskarte Regulär';
      case 3:
        return 'Tageskarte Senior';
      case 4:
        return 'Familienkarte';
      case 5:
        return 'Gruppenkarte';
      default:
        return 'Unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket-Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Ticket-Icon-Container anstatt QR-Code
            Container(
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Großes Ticket-Icon
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.confirmation_number,
                      size: 100,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ticket-ID: ${ticket.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ticket.isUsed
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.isUsed ? 'VERWENDET' : 'AKTIV',
                      style: TextStyle(
                        color: ticket.isUsed ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ticket-Informationen
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket-Typ
                  const Text(
                    'Ticket-Informationen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow(
                      'Ticket-Typ', _ticketTypeName(ticket.ticketTypeId)),
                  _buildInfoRow(
                      'Status', ticket.isUsed ? 'Verwendet' : 'Aktiv'),
                  _buildInfoRow('Gültig am', _formatDate(ticket.expiryDate)),
                  _buildInfoRow(
                      'Preis', '${ticket.price.toStringAsFixed(2)} €'),
                  _buildInfoRow(
                      'Erworben am', _formatDate(ticket.purchaseDate)),
                ],
              ),
            ),

            // Benutzer-Informationen
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Besitzer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Name', '${user.firstName} ${user.lastName}'),
                  _buildInfoRow('E-Mail', user.email ?? 'Keine E-Mail'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
