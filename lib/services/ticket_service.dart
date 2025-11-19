import 'package:cloud_firestore/cloud_firestore.dart';

class TicketService {
  final CollectionReference _tickets =
      FirebaseFirestore.instance.collection('qr_codes');

  /// Obtener los datos del ticket por ID
  Future<Map<String, dynamic>?> getTicket(String ticketId) async {
    try {
      DocumentSnapshot doc = await _tickets.doc(ticketId).get();

      if (!doc.exists) {
        return null;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener ticket: $e');
    }
  }

  /// Actualizar campos del ticket
  Future<void> updateTicket({
    required String ticketId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _tickets.doc(ticketId).update(updates);
    } catch (e) {
      throw Exception('Error al actualizar ticket: $e');
    }
  }
}
