import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

    if (kIsWeb) {
      final uri = Uri.base;

      // 1. Leer parámetros normales (?ticket=)
      String? ticketNormal =
          uri.queryParameters['ticket'] ?? uri.queryParameters['ticketId'];

      // 2. Leer parámetros después del hash (#/register?ticket=)
      String? ticketHash;
      if (uri.fragment.contains('?')) {
        final hashParams =
            Uri.splitQueryString(uri.fragment.split('?').last);

        ticketHash = hashParams['ticket'] ?? hashParams['ticketId'];
      }

      ticketIdFromUrl = ticketNormal ?? ticketHash;

      print("DEBUG ticketNormal: $ticketNormal");
      print("DEBUG ticketHash: $ticketHash");
      print("🎯 FINAL TICKET ID: $ticketIdFromUrl");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValetFlowQR PWA',
      theme: ThemeData(primarySwatch: Colors.blue),

      initialRoute: '/',

      onGenerateRoute: (settings) {
        final box = Hive.box('userData');
        final user = box.get('info');

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
              builder: (_) =>
                  ServiceStatusScreen(ticketId: mergedTicketId),
            );
        }

        return null;
      },

      routes: {
        '/': (_) => HomeScreen(ticketId: ticketIdFromUrl ?? ''),
        '/home': (_) => HomeScreen(ticketId: ticketIdFromUrl ?? ''),
        '/register': (_) => RegisterScreen(ticketId: ticketIdFromUrl ?? ''),
        '/service_status': (_) =>
            ServiceStatusScreen(ticketId: ticketIdFromUrl ?? ''),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
