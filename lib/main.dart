import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/request_valet_screen.dart';
import 'screens/service_status_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/scan_qr_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('userData');
  await Hive.openBox('valetData');

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
  String? plateFromUrl;
  String? modelFromUrl;

  @override
  void initState() {
    super.initState();
    _getURLParams();
  }

  /// ✅ Extrae datos desde URL cuando corre en Web
  void _getURLParams() {
    if (!kIsWeb) return;

    final uri = Uri.base;
    final id = uri.queryParameters['ticketId'];
    final plate = uri.queryParameters['plate'];
    final model = uri.queryParameters['model'];

    if (id != null && id.isNotEmpty) {
      setState(() {
        ticketIdFromUrl = id;
        plateFromUrl = plate;
        modelFromUrl = model;
      });

      print("✅ Parámetros detectados desde URL →");
      print("   ticketId = $id");
      print("   plate    = $plate");
      print("   model    = $model");
    } else {
      print("ℹ️ No hay parámetros válidos en URL");
    }
  }

  /// ✅ Decide si mandar Register o Home
  String _initialRoute() {
    final box = Hive.box('userData');
    final user = box.get('info');

    if (user == null) {
      print("ℹ️ Usuario NO registrado → Mandar a /register");
      return '/register';
    }

    print("✅ Usuario registrado → Mandar a /home");
    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValetFlowQR PWA',
      theme: ThemeData(primarySwatch: Colors.blue),

      /// ✅ Nuevo flujo
      initialRoute: _initialRoute(),

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;

            final mergedTicketId = args?["ticketId"] ?? ticketIdFromUrl;
            final mergedPlate    = args?["plate"]    ?? plateFromUrl;
            final mergedModel    = args?["model"]    ?? modelFromUrl;

            return MaterialPageRoute(
              builder: (_) => HomeScreen(
                ticketId: mergedTicketId,
                plate: mergedPlate,
                model: mergedModel,
              ),
            );

          default:
            return null;
        }
      },

      routes: {
        '/register': (_) => const RegisterScreen(),
        '/request_valet': (_) => const RequestValetScreen(),
        '/service_status': (_) => const ServiceStatusScreen(),
        '/history': (_) => const HistoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/scan_qr': (_) => const ScanQRScreen(),
      },

      /// ✅ fallback
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
