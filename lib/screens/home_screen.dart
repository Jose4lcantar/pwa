import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'privacy_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? ticketId; // ✅ Cambiado a opcional

  const HomeScreen({
    super.key,
    this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    if (ticketId == null || ticketId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ValetFlowQR - Inicio'),
          backgroundColor: const Color(0xFF0175C2),
        ),
        body: const Center(
          child: Text("No hay Ticket ID disponible."),
        ),
      );
    }

    final docStream = FirebaseFirestore.instance
        .collection('qr_codes')
        .doc(ticketId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ValetFlowQR - Inicio'),
        backgroundColor: const Color(0xFF0175C2),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text("Ticket no encontrado."),
            );
          }

          final data = snapshot.data!;
          final status = data['status'] ?? '';
          final plate = data['plate'] ?? '';
          final model = data['model'] ?? '';

          return _buildHome(context, status, plate, model);
        },
      ),
    );
  }

  Widget _buildHome(
      BuildContext context, String status, String plate, String model) {
    return Container(
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
            _buildTicketInfo(plate, model),
            const SizedBox(height: 16),
            if (status == 'iniciado' || status == 'estacionado')
              _buildSolicitarAutoButton(context),
            if (status == 'en_camino')
              const Text(
                'Tu vehículo viene en camino...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            if (status == 'listo_para_confirmar') _buildConfirmarRecibido(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolicitarAutoButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.directions_car),
      label: const Text(
        "Solicitar mi auto",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        if (ticketId == null) return;

        await FirebaseFirestore.instance
            .collection('qr_codes')
            .doc(ticketId)
            .update({
          'status': 'solicitado_cliente',
          'requestTime': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Solicitud enviada al valet")),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildConfirmarRecibido() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.check_circle),
      label: const Text(
        "Marcar como recibido",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        if (ticketId == null) return;

        await FirebaseFirestore.instance
            .collection('qr_codes')
            .doc(ticketId)
            .update({
          'status': 'entregado',
          'deliveredTime': DateTime.now(),
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTicketInfo(String plate, String model) {
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

  Widget _buildMenu(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _menuCard(
          context,
          'Estado del servicio',
          Icons.info,
          '/service_status',
        ),
        _menuCard(
          context,
          'Historial',
          Icons.history,
          '/history',
        ),
        _menuCard(
          context,
          'Configuración',
          Icons.settings,
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
    );
  }

  Widget _menuCard(
    BuildContext context,
    String title,
    IconData icon,
    String route, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (onTap != null) return onTap();
          if (route.isNotEmpty) Navigator.pushNamed(context, route);
        },
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.black87),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
