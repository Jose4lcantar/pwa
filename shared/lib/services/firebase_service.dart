// shared/lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';

class FirebaseService {
  static final _carsRef = FirebaseFirestore.instance.collection('cars');

  /// Guarda un coche en la colección 'cars'
  static Future<void> addCar(Car car) async {
    await _carsRef.add(car.toMap());
  }

  /// Obtiene todos los coches
  static Future<List<Car>> getCars() async {
    final query = await _carsRef.get();
    return query.docs.map((doc) => Car.fromMap(doc.data())).toList();
  }

  /// Escucha en tiempo real los cambios en la colección
  static Stream<List<Car>> listenCars() {
    return _carsRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Car.fromMap(doc.data())).toList(),
    );
  }
}
