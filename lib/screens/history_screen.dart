import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatelessWidget {
  final String ticketId;

  const HistoryScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial del servicio"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("qr_codes")
            .doc(ticketId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null || data["history"] == null) {
            return const Center(
              child: Text("Aún no hay historial disponible."),
            );
          }

          final List history = data["history"];

          // Ordenar por fecha (recientes arriba)
          history.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final status = item["status"];
              final timestamp = item["timestamp"];

              final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

              return _timelineTile(
                status: status,
                date: date,
                isFirst: index == 0,
                isLast: index == history.length - 1,
              );
            },
          );
        },
      ),
    );
  }

  Widget _timelineTile({
    required String status,
    required DateTime date,
    required bool isFirst,
    required bool isLast,
  }) {
    final formattedDate =
        "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea vertical izquierda
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 3,
                height: 20,
                color: Colors.grey.shade400,
              ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 40,
                color: Colors.grey.shade400,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Contenido de cada evento
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Traducción bonita del status
  String _statusLabel(String status) {
    switch (status) {
      case "iniciado":
        return "Registro completado";
      case "solicitado_cliente":
        return "Cliente solicitó el vehículo";
      case "preparando":
        return "Vehículo en preparación";
      case "entregado":
        return "Vehículo entregado";
      case "cerrado_cliente":
        return "Servicio finalizado";
      default:
        return status;
    }
  }
}
