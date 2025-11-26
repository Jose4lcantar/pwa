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
          final status = data['status'] ?? 'creado';
          final pin = data['pin']; // <- PIN desde el registro

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
                  _statusLabel(status),
                  style: const TextStyle(fontSize: 22, color: Colors.blue),
                ),

                const SizedBox(height: 30),

                /// 🌟 Nuevo Wizard elegante
                _buildBeautifulWizard(status),
                const SizedBox(height: 40),

                //-----------------------------------------
                // BOTONES CON VALIDACIÓN POR PIN
                //-----------------------------------------
                if (status == "iniciado")
                  _StatusButton(
                    label: "Solicitar mi vehículo",
                    color: Colors.orange,
                    icon: Icons.local_parking,
                    onPressed: () async {
                      final ok = await _validatePin(context, pin);
                      if (!ok) return;

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
                      final ok = await _validatePin(context, pin);
                      if (!ok) return;

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
                      final ok = await _validatePin(context, pin);
                      if (!ok) return;

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

  // -------------------------------------------------------------------------
  //                 WIZARD BONITO / LÍNEA DE TIEMPO MEJORADA
  // -------------------------------------------------------------------------
  Widget _buildBeautifulWizard(String status) {
    final steps = [
      "creado",
      "iniciado",
      "solicitado_cliente",
      "entregado",
      "cerrado_cliente"
    ];

    int current = steps.indexOf(status);
    if (current < 0) current = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (i) {
        final active = i <= current;
        final isLast = i == steps.length - 1;

        return Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                          )
                        : LinearGradient(
                            colors: [Colors.grey.shade300, Colors.grey.shade200],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (active)
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                    ],
                  ),
                  child: Icon(
                    active ? Icons.check : Icons.circle,
                    color: active ? Colors.white : Colors.grey,
                    size: active ? 20 : 14,
                  ),
                ),

                // ---------- CONECTOR ENTRE CÍRCULOS ----------
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i < current ? Colors.green : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(
                steps[i].replaceAll("_", "\n"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.green : Colors.grey,
                ),
              ),
            )
          ],
        );
      }),
    );
  }

  // -------------------------------------------------------------------------
  //                      VALIDACIÓN DE PIN
  // -------------------------------------------------------------------------
  Future<bool> _validatePin(BuildContext context, String? storedPin) async {
    final controller = TextEditingController();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Validación de identidad"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Tu PIN son los últimos 4 dígitos del teléfono que registraste.",
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "••••",
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  final enteredPin = controller.text.trim();

                  if (enteredPin != storedPin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("PIN incorrecto"),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, true);
                },
                child: const Text("Validar"),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _statusLabel(String status) {
    switch (status) {
      case "creado":
        return "Ticket creado";
      case "iniciado":
        return "Registro completado";
      case "solicitado_cliente":
        return "Solicitud enviada al valet";
      case "entregado":
        return "Vehículo entregado";
      case "cerrado_cliente":
        return "Servicio cerrado";
      default:
        return status;
    }
  }
}

// ---------------------------------------------------------------------------
//                             BOTÓN REUTILIZABLE
// ---------------------------------------------------------------------------
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
        height: 55,
        child: ElevatedButton.icon(
          icon: icon != null ? Icon(icon, size: 22) : const SizedBox.shrink(),
          label: Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
