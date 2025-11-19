import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceStatusScreen extends StatelessWidget {
  final String? ticketId; // ✅ opcional

  const ServiceStatusScreen({super.key, this.ticketId});

  @override
  Widget build(BuildContext context) {
    if (ticketId == null || ticketId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estado del Servicio')),
        body: const Center(
          child: Text(
            "No hay ticket seleccionado.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final ticketRef =
        FirebaseFirestore.instance.collection('qr_codes').doc(ticketId);

    return Scaffold(
      appBar: AppBar(title: const Text('Estado del Servicio')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: ticketRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el ticket.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'desconocido';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ticket: $ticketId",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 20),
                const Text(
                  "Estado actual:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  status,
                  style: const TextStyle(fontSize: 22, color: Colors.blue),
                ),
                const SizedBox(height: 30),

                if (status == "iniciado")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ticketRef.update({
                          'status': 'solicitado_cliente',
                          'requestedAt': DateTime.now(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Solicitar mi vehículo"),
                    ),
                  ),

                if (status == "solicitado_cliente")
                  const Text(
                    "Tu solicitud fue enviada al valet. 🚗💨",
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),

                if (status == "entregado")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ticketRef.update({
                          'status': 'cerrado_cliente',
                          'closedAt': DateTime.now(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Marcar como recibido"),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
