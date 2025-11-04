import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // <-- para kIsWeb
import 'privacy_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? ticketId;
  final String? plate;
  final String? model;

  const HomeScreen({
    super.key,
    this.ticketId,
    this.plate,
    this.model,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTicket = ticketId != null && ticketId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ValetFlowQR - Inicio'),
        backgroundColor: const Color(0xFF0175C2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Bienvenido a ValetFlowQR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF01579B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 🔹 Botón de escaneo QR o demo
              if (!hasTicket)
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 28),
                  label: const Text(
                    'Escanear QR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    // Datos de demo
                    const demoTicketId = 'DEMO123';
                    const demoPlate = 'ABC-1234';
                    const demoModel = 'Toyota Demo';

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          ticketId: demoTicketId,
                          plate: demoPlate,
                          model: demoModel,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0175C2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              // Mostrar info del vehículo si hay ticket (real o demo)
              if (hasTicket) _buildTicketInfo(),

              const SizedBox(height: 24),

              Expanded(
                child: GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                    // 🔹 Solicitar valet
                    _buildCard(
                      context,
                      'Solicitar Valet',
                      Icons.local_parking,
                      const Color(0xFF0175C2),
                      '',
                      requiresTicket: true,
                      onTap: () {
                        final id = ticketId ?? 'DEMO123';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConfirmationScreen(
                              title: 'Solicitud de Vehículo',
                              message: 'Se ha solicitado el vehículo con ticket: $id',
                              plate: plate ?? 'ABC-1234',
                              model: model ?? 'Toyota Demo',
                            ),
                          ),
                        );
                      },
                    ),
                    // 🔹 Confirmar recepción
                    _buildCard(
                      context,
                      'Confirmar recepción',
                      Icons.check_circle_outline,
                      const Color(0xFF43A047),
                      '',
                      requiresTicket: true,
                      onTap: () {
                        final id = ticketId ?? 'DEMO123';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConfirmationScreen(
                              title: 'Recepción del Vehículo',
                              message: 'Recepción confirmada para el vehículo con ticket: $id',
                              plate: plate ?? 'ABC-1234',
                              model: model ?? 'Toyota Demo',
                            ),
                          ),
                        );
                      },
                    ),
                    // 🔹 Estado del servicio
                    _buildCard(
                      context,
                      'Estado del servicio',
                      Icons.info,
                      const Color(0xFF43A047),
                      '/service_status',
                      requiresTicket: true,
                    ),
                    // 🔹 Historial
                    _buildCard(
                      context,
                      'Historial',
                      Icons.history,
                      const Color(0xFF8E24AA),
                      '/history',
                      requiresTicket: true,
                    ),
                    // 🔹 Configuración
                    _buildCard(
                      context,
                      'Configuración',
                      Icons.settings,
                      const Color(0xFF0288D1),
                      '',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.privacy_tip),
                                title: const Text('Política de Privacidad'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PrivacyScreen(readOnly: true),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void requireTicket(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Escanea el código QR para continuar",
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route, {
    bool requiresTicket = false,
    VoidCallback? onTap,
  }) {
    final bool hasTicket = ticketId != null && ticketId!.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (requiresTicket && !hasTicket) {
            requireTicket(context);
            return;
          }
          if (onTap != null) {
            onTap();
          } else if (route.isNotEmpty) {
            Navigator.pushNamed(context, route);
          }
        },
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo() {
    return Column(
      children: [
        const Text(
          "Información del vehículo",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF01579B),
          ),
        ),
        const SizedBox(height: 8),
        _displayField("Ticket ID", ticketId),
        _displayField("Placa", plate),
        _displayField("Modelo", model),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _displayField(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// 🔹 Pantalla de confirmación visual
class ConfirmationScreen extends StatelessWidget {
  final String title;
  final String message;
  final String plate;
  final String model;

  const ConfirmationScreen({
    super.key,
    required this.title,
    required this.message,
    required this.plate,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFF0175C2)),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text("Placa: $plate", style: const TextStyle(fontSize: 16)),
                Text("Modelo: $model", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0175C2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
