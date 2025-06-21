import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'settings_page.dart';

class StatusPage extends StatelessWidget {
  final AppUser user;
  const StatusPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ermäßigung beantragen'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StatusWidget(user: user),
        ),
      ),
    );
  }
}
