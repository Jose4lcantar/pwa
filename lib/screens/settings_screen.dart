import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF0175C2),
      ),
      body: const Center(
        child: Text('Pantalla de configuración del usuario.'),
      ),
    );
  }
}
