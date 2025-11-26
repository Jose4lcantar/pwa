import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/service_status_screen.dart';
import 'screens/settings_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('userData');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');

    // 🔹 Inicializar FCM y pedir permiso
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permiso de notificaciones: ${settings.authorizationStatus}');
  } catch (e) {
    print('⚠️ No se pudo inicializar Firebase (modo offline): $e');
  }

  runApp(const ValetFlowQRApp());
}

class ValetFlowQRApp extends StatefulWidget {
  const ValetFlowQRApp({super.key});

  @override
  State<ValetFlowQRApp> createState() => _ValetFlowQRAppState();
}

class _ValetFlowQRAppState extends State<ValetFlowQRApp> {
  String? ticketIdFromUrl;

  @override
  void initState() {
    super.initState();

    final box = Hive.box('userData');

    if (kIsWeb) {
      final uri = Uri.base;

      // 1️⃣ Leer parámetros normales (?ticket=)
      String? ticketNormal =
          uri.queryParameters['ticket'] ?? uri.queryParameters['ticketId'];

      // 2️⃣ Leer parámetros después del hash (#/register?ticket=)
      String? ticketHash;
      if (uri.fragment.contains('?')) {
        final hashParams =
            Uri.splitQueryString(uri.fragment.split('?').last);

        ticketHash = hashParams['ticket'] ?? hashParams['ticketId'];
      }

      ticketIdFromUrl = ticketNormal ?? ticketHash;

      // 🔹 Guardar ticket en Hive para persistencia
      if (ticketIdFromUrl != null && ticketIdFromUrl!.isNotEmpty) {
        box.put('ticketId', ticketIdFromUrl);
      } else {
        // Si no hay ticket en URL, usar el guardado
        ticketIdFromUrl = box.get('ticketId');
      }

      print("DEBUG ticketNormal: $ticketNormal");
      print("DEBUG ticketHash: $ticketHash");
      print("🎯 FINAL TICKET ID: $ticketIdFromUrl");

      // 🔹 Registrar token FCM con ticketId
      if (ticketIdFromUrl != null && ticketIdFromUrl!.isNotEmpty) {
        registerToken(ticketIdFromUrl!);
      }
    } else {
      // Para móviles o PWA sin URL (abrir desde icono)
      ticketIdFromUrl = box.get('ticketId');
      if (ticketIdFromUrl != null && ticketIdFromUrl!.isNotEmpty) {
        registerToken(ticketIdFromUrl!);
      }
    }
  }

  Future<void> registerToken(String ticketId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('qr_codes')
            .doc(ticketId)
            .update({'fcmToken': token});

        print('✅ Token FCM registrado para ticket $ticketId');
      }
    } catch (e) {
      print('⚠️ Error registrando token FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('userData');
    final user = box.get('info');

    return MaterialApp(
      title: 'ValetFlowQR PWA',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',

      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;
        final mergedTicketId = args?['ticketId'] ?? ticketIdFromUrl ?? '';

        print("🎯 Navegando → ${settings.name} con ticket $mergedTicketId");

        if (mergedTicketId.isEmpty && settings.name == "/register") {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text(
                  "No se recibió un ticket válido.\nEscanea nuevamente el QR.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) =>
                  user == null
                      ? RegisterScreen(ticketId: mergedTicketId)
                      : HomeScreen(ticketId: mergedTicketId),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => RegisterScreen(ticketId: mergedTicketId),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomeScreen(ticketId: mergedTicketId),
            );
          case '/service_status':
            return MaterialPageRoute(
              builder: (_) => ServiceStatusScreen(ticketId: mergedTicketId),
            );
        }
        return null;
      },

    
    );
  }
}

