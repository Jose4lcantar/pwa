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

    // 🔹 Habilitar persistencia offline
    if (kIsWeb) {
      await FirebaseFirestore.instance.enablePersistence();
      print('✅ Firestore persistencia web habilitada');
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('✅ Firestore persistencia móvil habilitada');
    }

    final messaging = FirebaseMessaging.instance;

    // Pedir permisos de notificación
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Registrar token
      await registerTokenForPlatform();
    } else {
      print("⚠️ Permiso de notificaciones denegado");
    }
  } catch (e) {
    print('⚠️ Error inicializando Firebase: $e');
  }

  runApp(const ValetFlowQRApp());
}

Future<void> registerTokenForPlatform() async {
  final token = await FirebaseMessaging.instance.getToken(
    vapidKey: kIsWeb
        ? "BObcTSbD5V3yjUPVzOmydB_0phZbQLakieo2d_yj5AHrWdh2y78c_4f4FqhJF167kHfhAunwc2FbfSusxUxMUa0"
        : null,
  );

  if (token == null) {
    print("⚠️ No se pudo generar token FCM");
    return;
  }

  final isWeb = kIsWeb;
  final collectionName = isWeb ? 'user_tokens_web' : 'user_tokens_mobile';

  // Guardar en colección por plataforma
  await FirebaseFirestore.instance.collection(collectionName).doc(token).set({
    'token': token,
    'platform': isWeb ? 'web' : 'mobile',
    'createdAt': FieldValue.serverTimestamp(),
  });

  print('✅ Token FCM guardado en $collectionName: $token');

  // Guardar token en el ticket si existe
  final box = Hive.box('userData');
  final ticketId = box.get('ticketId');
  if (ticketId != null && ticketId.isNotEmpty) {
    final ticketUpdate = isWeb
        ? {'fcmTokenWeb': token}
        : {'fcmTokenMobile': token};
    await FirebaseFirestore.instance
        .collection('qr_codes')
        .doc(ticketId)
        .update(ticketUpdate);

    print('✅ Token FCM guardado para ticket $ticketId, plataforma: ${isWeb ? 'web' : 'mobile'}');
  }
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
    _loadTicketFromUrlOrHive();
  }

  Future<void> _loadTicketFromUrlOrHive() async {
    final box = Hive.box('userData');

    if (kIsWeb) {
      final uri = Uri.base;
      final ticketNormal =
          uri.queryParameters['ticket'] ?? uri.queryParameters['ticketId'];

      String? ticketHash;
      if (uri.fragment.contains("?")) {
        final hashParams =
            Uri.splitQueryString(uri.fragment.split("?").last);
        ticketHash = hashParams['ticket'] ?? hashParams['ticketId'];
      }

      ticketIdFromUrl = ticketNormal ?? ticketHash;

      if (ticketIdFromUrl != null && ticketIdFromUrl!.isNotEmpty) {
        box.put('ticketId', ticketIdFromUrl);
      } else {
        ticketIdFromUrl = box.get('ticketId');
      }

      print("🎯 TICKET FINAL: $ticketIdFromUrl");
    } else {
      ticketIdFromUrl = box.get('ticketId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('userData');
    final user = box.get('info');

    return MaterialApp(
      title: 'ValetFlowQR PWA',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: user == null
          ? RegisterScreen(ticketId: ticketIdFromUrl ?? '')
          : HomeScreen(ticketId: ticketIdFromUrl ?? ''),
      routes: {
        '/register': (_) => RegisterScreen(ticketId: ticketIdFromUrl ?? ''),
        '/home': (_) => HomeScreen(ticketId: ticketIdFromUrl ?? ''),
        '/service_status': (_) =>
            ServiceStatusScreen(ticketId: ticketIdFromUrl ?? ''),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
