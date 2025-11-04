// ignore_for_file: avoid_print
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Comprueba conexión a internet de forma compatible con Web y móvil
  Future<bool> get isOnline async {
    try {
      if (kIsWeb) {
        // En web usamos ConnectivityPlus (no dart:io)
        final result = await Connectivity().checkConnectivity();
        return result != ConnectivityResult.none;
      } else {
        // En Android/iOS, también con ConnectivityPlus
        final result = await Connectivity().checkConnectivity();
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      print('⚠️ Error verificando conexión: $e');
      return false;
    }
  }

  /// Registro híbrido (Firebase si hay red, Hive si no)
  Future<void> register(String email, String password) async {
    if (await isOnline) {
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Guarda copia local para modo offline
        final box = Hive.box('valetData');
        await box.put('offlineUser', {'email': email, 'password': password});
        print('✅ Usuario registrado online y guardado offline');
      } on FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'Error al registrar usuario');
      } catch (e) {
        throw Exception('Error inesperado: $e');
      }
    } else {
      await registerOffline(email, password);
      print('📦 Usuario registrado en modo offline');
    }
  }

  /// Inicio de sesión híbrido (online/offline)
  Future<bool> login(String email, String password) async {
    if (await isOnline) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Guarda sesión local
        final box = Hive.box('valetData');
        await box.put('offlineUser', {'email': email, 'password': password});
        print('✅ Sesión iniciada online y sincronizada offline');
        return true;
      } on FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'Error al iniciar sesión');
      } catch (e) {
        throw Exception('Error inesperado: $e');
      }
    } else {
      final ok = await loginOffline(email, password);
      if (ok) {
        print('📴 Sesión iniciada en modo offline');
      } else {
        print('❌ No hay conexión ni usuario local válido');
      }
      return ok;
    }
  }

  /// Registro offline
  Future<void> registerOffline(String email, String password) async {
    final box = Hive.box('valetData');
    await box.put('offlineUser', {'email': email, 'password': password});
  }

  /// Login offline
  Future<bool> loginOffline(String email, String password) async {
    final box = Hive.box('valetData');
    final user = box.get('offlineUser');
    if (user != null) {
      return user['email'] == email && user['password'] == password;
    }
    return false;
  }

  /// Logout (Firebase + Hive)
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    final box = Hive.box('valetData');
    await box.delete('offlineUser');
  }

  /// Usuario actual (solo si está autenticado online)
  User? get currentUser => _auth.currentUser;
}
