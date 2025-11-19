import 'package:flutter/material.dart';
import '../services/ticket_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final String plate;
  final String model;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.plate,
    required this.model,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _ticketService = TicketService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await _ticketService.updateTicket(
        ticketId: widget.ticketId,
        updates: {
          'status': newStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _statusMessage = 'Estado actualizado a "$newStatus"';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '⚠️ Error: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _ticketService.getTicket(widget.ticketId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final ticket = snapshot.data!;
            final status = ticket['status'] ?? 'desconocido';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ticket ID: ${widget.ticketId}'),
                Text('Placa: ${widget.plate}'),
                Text('Modelo: ${widget.model}'),
                const SizedBox(height: 20),

                Text(
                  'Estado actual: $status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                if (_statusMessage.isNotEmpty)
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.green),
                  ),

                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: status == 'iniciado'
                            ? () => _updateStatus('solicitado_cliente')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Solicitar Vehículo'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: status == 'solicitado_cliente'
                            ? () => _updateStatus('entregado')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Marcar como Recibido'),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
