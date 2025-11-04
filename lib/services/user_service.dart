// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _box = Hive.box('valetData');

  /// ✅ Detectar conexión
  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// ✅ Guardar usuario (Firestore + offline)
  Future<void> saveUser({
    required String name,
    String? phone,
  }) async {
    final data = {
      'name': name,
      'phone': phone,
      'createdAt': DateTime.now().toIso8601String()
    };

    // ✅ Guardar local para offline o backup
    await _box.put('userInfo', data);

    if (await isOnline) {
      try {
        await _firestore.collection("users").add(data);
        print("✅ Usuario guardado online");
      } catch (e) {
        print("⚠️ Error guardando online, quedará offline: $e");
      }
    } else {
      print("📴 Sin internet → datos guardados offline");
    }
  }

  /// ✅ Obtener información de usuario
  Map<String, dynamic>? getLocalUser() {
    return _box.get('userInfo');
  }
}
