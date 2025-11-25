class Car { 
  
  final String plateNumber; /// Número de placa del auto (dato obligatorio)
  final String? color;
  final String? model;

  final String? valetId; /// ID del valet que registró este auto (referencia a un usuario empleado)

  final bool isInCustody; /// Indica si el auto está actualmente en resguardo

  /// Constructor: usamos `required` para la placa,
  /// los demás datos son opcionales
  Car({
    required this.plateNumber,
    this.color,
    this.model,
    this.valetId,
    this.isInCustody = true,
  });

  /// Convierte el objeto Car a un Map<String, dynamic>  para guardar los datos en Firebase Firestore
  Map<String, dynamic> toMap() {
    return {
      'plateNumber': plateNumber,
      'color': color,
      'model': model,
      'valetId': valetId,
      'isInCustody': isInCustody,
    };
  }

  /// Crea un objeto Car desde un Map<String, dynamic>
  /// Esto sirve cuando traemos los datos de Firestore y queremos
  /// reconstruir el objeto en la app
  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      plateNumber: map['plateNumber'] ?? '',
      color: map['color'],
      model: map['model'],
      valetId: map['valetId'],
      isInCustody: map['isInCustody'] ?? true,
    );
  }
}
