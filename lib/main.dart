import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

      // 1. Leer parámetros normales (antes del #)
      String? ticketNormal =
          uri.queryParameters['ticket'] ?? uri.queryParameters['ticketId'];

      // 2. Leer parámetros después del hash (#/register?ticket=ABC)
      String? ticketHash;
      if (uri.fragment.contains('?')) {
        final hashParams =
            Uri.splitQueryString(uri.fragment.split('?').last);

        ticketHash = hashParams['ticket'] ?? hashParams['ticketId'];
      }

      // 3. Seleccionar el valor válido
      ticketIdFromUrl = ticketNormal ?? ticketHash;

      print("DEBUG ticketNormal: $ticketNormal");
      print("DEBUG ticketHash: $ticketHash");
      print("✅ FINAL TICKET ID: $ticketIdFromUrl");
    }
  }

  String _initialRoute() {
    final box = Hive.box('userData');
    final user = box.get('info');
    return user == null ? '/register' : '/home';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValetFlowQR PWA',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: _initialRoute(),

      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        // Fallback: ticketId vacío si no viene de argumentos ni URL
        final mergedTicketId = args?['ticketId'] ?? ticketIdFromUrl ?? '';

        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomeScreen(ticketId: mergedTicketId),
            );

          case '/register':
            return MaterialPageRoute(
              builder: (_) => RegisterScreen(ticketId: mergedTicketId),
            );

          case '/service_status':
            return MaterialPageRoute(
              builder: (_) => ServiceStatusScreen(ticketId: mergedTicketId),
            );
        }
        return null;
      },

      routes: {
        '/settings': (_) => const SettingsScreen(),
      },

      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => HomeScreen(ticketId: ticketIdFromUrl ?? ''),
      ),
    );
  }
}
