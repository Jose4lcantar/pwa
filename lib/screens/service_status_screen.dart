import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceStatusScreen extends StatelessWidget {
  final String? ticketId;

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
                        fontSize: 18, fontWeight: FontWeight.bold)),
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

                // --- Botones según estado ---
                if (status == "iniciado")
                  _StatusButton(
                    label: "Solicitar mi vehículo",
                    color: Colors.orange,
                    icon: Icons.local_parking,
                    onPressed: () async {
                      await ticketRef.update({
                        'status': 'solicitado_cliente',
                        'requestedAt': DateTime.now(),
                      });
                    },
                  ),

                if (status == "solicitado_cliente")
                  _StatusButton(
                    label: "Confirmar recibido",
                    color: Colors.green,
                    icon: Icons.check_circle,
                    onPressed: () async {
                      await ticketRef.update({
                        'status': 'entregado',
                        'deliveredAt': DateTime.now(),
                      });
                    },
                  ),

                if (status == "entregado")
                  _StatusButton(
                    label: "Cerrar servicio",
                    color: Colors.blue,
                    icon: Icons.flag,
                    onPressed: () async {
                      await ticketRef.update({
                        'status': 'cerrado_cliente',
                        'closedAt': DateTime.now(),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Servicio finalizado. ¡Gracias!"),
                        ),
                      );
                    },
                  ),

                if (status == "cerrado_cliente")
                  const Text(
                    "El servicio ha sido cerrado. ¡Gracias por usar el valet! 🚗",
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Widget Helper para botones ---
class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
