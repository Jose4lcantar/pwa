import 'package:flutter/material.dart';

class ServiceStatusScreen extends StatelessWidget {
  const ServiceStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado del Servicio')),
      body: const Center(
        child: Text('Pantalla para ver el estado del servicio.'),
      ),
    );
  }
}
