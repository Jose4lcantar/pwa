/// Representa un ticket generado cuando un cliente deja su auto.
/// Se vincula al valet que lo registró y al cliente que lo reclama.
class Ticket {
  final String id;            // ID único del ticket (ej. generado en Firestore)
  final String plateNumber;   // Placa del auto (reconocida por IA o validada por el cliente)
  final String valetId;       // ID del valet que registró el ticket
  final String? clientName;   // Nombre del cliente (opcional, solo si lo ingresa)
  final DateTime createdAt;   // Fecha y hora en que se generó el ticket
  final bool isActive;        // Indica si el auto sigue en resguardo
  final String? photoUrl;     // URL de la foto del auto (guardada en Firebase Storage)
  final double? tip;          // Propina (opcional, agregada por el cliente)
  final int? rating;          // Calificación del servicio (1-5, opcional)

  Ticket({
    required this.id,
    required this.plateNumber,
    required this.valetId,
    this.clientName,
    required this.createdAt,
    this.isActive = true,
    this.photoUrl,
    this.tip,
    this.rating,
  });

  /// Convierte el objeto a un mapa para guardar en Firebase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'valetId': valetId,
      'clientName': clientName,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'photoUrl': photoUrl,
      'tip': tip,
      'rating': rating,
    };
  }

  /// Crea un objeto Ticket desde un mapa (ej. cuando leemos de Firestore).
  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      valetId: map['valetId'] ?? '',
      clientName: map['clientName'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? true,
      photoUrl: map['photoUrl'],
      tip: map['tip']?.toDouble(),
      rating: map['rating'],
    );
  }
}
