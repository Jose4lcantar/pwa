import 'package:flutter/material.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  // Respuestas básicas del bot
  final Map<String, String> botResponses = {
    "hola": "¡Hola! ¿En qué puedo ayudarte hoy?",
    "estado": "Puedes ver el estado de tu vehículo en la pantalla principal.",
    "vehiculo": "El valet está preparando tu vehículo, podrás verlo cuando cambie el estado.",
    "pago": "El servicio no requiere pago dentro de la aplicación.",
    "salir": "Puedes cerrar sesión desde el menú principal.",
    "qr": "Tu código QR sirve para identificar tu ticket con el valet.",
    "gracias": "¡Para servirte! ¿Necesitas algo más?",
  };

  // Procesa lo que escribe el usuario
  String getBotReply(String msg) {
    msg = msg.toLowerCase().trim();

    for (var key in botResponses.keys) {
      if (msg.contains(key)) return botResponses[key]!;
    }

    return "Lo siento, no entendí eso. ¿Puedes escribirlo de otra forma?";
  }

  void sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "msg": text});
    });

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({"role": "bot", "msg": getBotReply(text)});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asistente virtual")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final role = _messages[i]["role"];
                final msg = _messages[i]["msg"] ?? "";

                return Align(
                  alignment: role == "user"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: role == "user"
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg,
                      style: TextStyle(
                        color: role == "user" ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Caja para escribir
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Escribe tu mensaje...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
