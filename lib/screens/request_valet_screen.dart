import 'package:flutter/material.dart';

class RequestValetScreen extends StatelessWidget {
  const RequestValetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Valet')),
      body: const Center(
        child: Text('Pantalla para solicitar servicio de valet.'),
      ),
    );
  }
}
