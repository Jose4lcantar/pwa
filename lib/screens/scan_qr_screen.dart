import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  String? _scannedData;
  bool _isSaving = false;
  bool _alreadyProcessed = false;   // ✅ evita doble procesamiento

  /// ✅ Valida formato base
  bool _isValidQR(String data) {
    return data.startsWith("valet:");
  }

  /// ✅ Parsea valores del QR
  ///
  /// Formato esperado:
  /// valet:ID=123;PLATE=XXX000;MODEL=COROLLA
  Map<String, String> _parseQR(String raw) {
    try {
      final content = raw.replaceFirst("valet:", "");
      final parts = content.split(";");
      final data = <String, String>{};

      for (var p in parts) {
        final kv = p.split("=");
        if (kv.length == 2) {
          data[kv[0].toUpperCase()] = kv[1];
        }
      }

      return data;
    } catch (_) {
      return {};
    }
  }

  /// ✅ Guarda offline + Firebase
  Future<void> _saveData(Map<String, String> parsed) async {
    setState(() => _isSaving = true);

    final box = Hive.box('valetData');
    final timestamp = DateTime.now().toIso8601String();

    await box.put('lastQR', {
      'data': parsed,
      'timestamp': timestamp,
    });

    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;

    if (hasInternet) {
      try {
        await FirebaseFirestore.instance.collection('valet_scans').add({
          'data': parsed,
          'timestamp': timestamp,
        });
      } catch (e) {
        debugPrint('⚠️ Error al sincronizar con Firebase: $e');
      }
    } else {
      debugPrint('📴 Sin conexión — guardado offline');
    }

    setState(() => _isSaving = false);
  }

  /// ✅ Procesa QR leído
  Future<void> _onQRDetected(String raw) async {
    if (_isSaving || _alreadyProcessed) return;

    _alreadyProcessed = true; // ✅ evita re-trigger

    if (!_isValidQR(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR inválido")),
      );
      return;
    }

    final parsed = _parseQR(raw);

    if (!parsed.containsKey("ID") || !parsed.containsKey("PLATE")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QR incompleto: requiere ID y PLACA"),
        ),
      );
      return;
    }

    await _saveData(parsed);

    if (!mounted) return;

    final id = parsed["ID"];
    final plate = parsed["PLATE"];
    final model = parsed["MODEL"];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("QR leído: ID $id • Placa $plate"),
      ),
    );

    /// ✅ Navega a HOME
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
      arguments: {
        "ticketId": id,
        "plate": plate,
        "model": (model?.isEmpty ?? true) ? null : model,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: const Color(0xFF0175C2),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _scannedData = barcode.rawValue!;
                  await _onQRDetected(_scannedData!);
                  return;
                }
              }
            },
          ),

          /// ✅ Loading overlay
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
