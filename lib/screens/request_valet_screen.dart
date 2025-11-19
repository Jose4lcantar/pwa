import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestValetScreen extends StatefulWidget {
  const RequestValetScreen({super.key});

  @override
  State<RequestValetScreen> createState() => _RequestValetScreenState();
}

class _RequestValetScreenState extends State<RequestValetScreen> {
  late String ticketId;

  @override
  void initState() {
    super.initState();

    // Leer ticketId desde la URL
    ticketId = Uri.base.queryParameters['ticket'] ?? '';

    if (ticketId.isEmpty) {
      debugPrint("⚠ No ticketId found in URL");
    }
  }

  Future<void> updateStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('qr_codes')
        .doc(ticketId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    if (ticketId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Error: ticket no encontrado.")),
      );
    }

    final docRef =
        FirebaseFirestore.instance.collection('qr_codes').doc(ticketId);

    return Scaffold(
      appBar: AppBar(title: const Text("Solicitar mi auto")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("No se encontró información."));
          }

          final status = data['status'] ?? 'sin_estado';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Estado actual del servicio:",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                /// --- BOTÓN PARA SOLICITAR EL AUTO ---
                if (status == "iniciado" || status == "validado_cliente")
                  ElevatedButton(
                    onPressed: () async {
                      await updateStatus("solicitado_cliente");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Solicitud enviada al valet 🚗"),
                        ),
                      );
                    },
                    child: const Text("Solicitar mi auto"),
                  ),

                /// --- MENSAJE CUANDO YA SOLICITÓ ---
                if (status == "solicitado_cliente")
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "El valet está trayendo tu auto...",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                const SizedBox(height: 20),

                /// --- BOTÓN PARA CONFIRMAR RECEPCIÓN DEL AUTO ---
                if (status == "auto_listo" || status == "solicitado_cliente")
                  ElevatedButton(
                    onPressed: () async {
                      await updateStatus("entregado");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("¡Gracias! Servicio finalizado."),
                        ),
                      );
                    },
                    child: const Text("Ya recibí mi auto"),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
