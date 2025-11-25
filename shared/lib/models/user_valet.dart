/// Representa a un usuario del sistema que es personal de valet parking.
class UserValet {
  final String id;       // Identificador único del valet (ej. UID de Firebase Auth)
  final String name;     // Nombre completo del valet
  final String email;    // Correo electrónico usado para login
  final String? phone;   // Teléfono de contacto (opcional)
  final bool isActive;   // Indica si el valet está activo en el sistema

  UserValet({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.isActive = true,
  });

  /// Convierte el objeto a un mapa para guardar en Firebase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isActive': isActive,
    };
  }

  /// Crea un objeto UserValet desde un mapa (ej. cuando leemos de Firestore).
  factory UserValet.fromMap(Map<String, dynamic> map) {
    return UserValet(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      isActive: map['isActive'] ?? true,
    );
  }
}
