import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// --------------------------------------------------------------
/// PANTALLA PRINCIPAL: ServiceStatusScreen
/// --------------------------------------------------------------
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
          final phone = data['phone'] ?? ''; // <-- teléfono registrado
          final storedPin = phone.length >= 4
              ? phone.substring(phone.length - 4)
              : phone; // últimos 4 dígitos

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
                /// Wizard elegante
                _buildBeautifulWizard(status),
                const SizedBox(height: 40),

                //----------------------------------------------------------------
                // BOTONES SEGÚN ESTADO
                //----------------------------------------------------------------
                if (status == "iniciado")
                  _StatusButton(
                    label: "Solicitar mi vehículo",
                    color: Colors.orange,
                    icon: Icons.local_parking,
                    onPressed: () async {
                      final ok = await _validatePin(context, storedPin);
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
                      final ok = await _validatePin(context, storedPin);
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
                      final ok = await _validatePin(context, storedPin);
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
                const Spacer(),

                //---------------------------------------------------------
                // BOTÓN DEL ASISTENTE / CHATBOT
                //---------------------------------------------------------
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatBotScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  label:
                      const Text("¿Necesitas ayuda? Abrir asistente virtual"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  //                 WIZARD / LÍNEA DE TIEMPO
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
                            colors: [Colors.grey, Colors.grey]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    active ? Icons.check : Icons.circle,
                    color: active ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active ? Colors.green : Colors.grey.shade300,
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
            ),
          ],
        );
      }),
    );
  }

  // -------------------------------------------------------------------------
  //                      VALIDACIÓN DE PIN
  // -------------------------------------------------------------------------
  Future<bool> _validatePin(BuildContext context, String storedPin) async {
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
                    "Tu PIN son los últimos 4 dígitos del teléfono que registraste."),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "••••",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: "",
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim() != storedPin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("PIN incorrecto")),
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

  // Traducción de estados
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

/// ---------------------------------------------------------------------------
/// BOTÓN REUTILIZABLE
/// ---------------------------------------------------------------------------
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
          icon: Icon(icon, size: 22),
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

/// ---------------------------------------------------------------------------
///                        CHATBOT SCREEN (SENCILLO)
/// ---------------------------------------------------------------------------
class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, String>> messages = [];

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
    });

    controller.clear();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add({
          "sender": "bot",
          "text": _botResponse(text),
        });
      });
    });
  }

  String _botResponse(String msg) {
    msg = msg.toLowerCase();

    if (msg.contains("auto") || msg.contains("vehículo")) {
      return "Puedes solicitar tu auto desde la pantalla principal usando el botón naranja.";
    }

    if (msg.contains("pin")) {
      return "Tu PIN son los últimos 4 dígitos del número telefónico que registraste.";
    }

    if (msg.contains("estado") || msg.contains("servicio")) {
      return "El servicio avanza por etapas: creado → iniciado → solicitado → entregado → cerrado.";
    }

    return "Puedo ayudarte con información sobre el PIN, el estado de tu servicio o la entrega del vehículo.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asistente Virtual")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final isUser = msg["sender"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe tu mensaje...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
