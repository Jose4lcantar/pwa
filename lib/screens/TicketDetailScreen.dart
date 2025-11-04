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
  bool _received = false;
  bool _delivered = false;
  bool _requested = false;

  Future<void> _handleAction(String action) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      switch (action) {
        case 'receive':
          await _ticketService.updateTicket(
            ticketId: widget.ticketId,
            updates: {'received': true, 'receivedAt': DateTime.now().toIso8601String()},
          );
          setState(() => _received = true);
          _statusMessage = 'Vehículo recibido confirmado';
          break;
        case 'deliver':
          await _ticketService.updateTicket(
            ticketId: widget.ticketId,
            updates: {'delivered': true, 'deliveredAt': DateTime.now().toIso8601String()},
          );
          setState(() => _delivered = true);
          _statusMessage = 'Entrega del vehículo confirmada';
          break;
        case 'request':
          await _ticketService.updateTicket(
            ticketId: widget.ticketId,
            updates: {'requested': true, 'requestedAt': DateTime.now().toIso8601String()},
          );
          setState(() => _requested = true);
          _statusMessage = 'Solicitud de entrega enviada al valet';
          break;
      }
    } catch (e) {
      _statusMessage = '⚠️ Error: $e';
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Ticket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket ID: ${widget.ticketId}', style: const TextStyle(fontSize: 16)),
            Text('Placa: ${widget.plate}', style: const TextStyle(fontSize: 16)),
            Text('Modelo: ${widget.model}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _received ? null : () => _handleAction('receive'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('Confirmar Recepción'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _delivered ? null : () => _handleAction('deliver'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Confirmar Entrega'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _requested ? null : () => _handleAction('request'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Solicitar Vehículo'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
