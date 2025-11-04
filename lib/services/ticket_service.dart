// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TicketService {
  final _firestore = FirebaseFirestore.instance;
  final _box = Hive.box('valetData');

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// ✅ Guardar ticket (al escanear)
  Future<void> saveTicket({
    required String ticketId,
    required String plate,
    required String model,
  }) async {
    final data = {
      'ticketId': ticketId,
      'plate': plate,
      'model': model,
      'status': 'creado',
      'scannedAt': DateTime.now().toIso8601String(),
      'synced': await isOnline,
    };

    // Guardar offline
    final localTickets = (_box.get("tickets") as List?)?.cast<Map>() ?? [];
    localTickets.add(data);
    await _box.put("tickets", localTickets);

    if (await isOnline) {
      try {
        await _firestore
            .collection("valetTickets")
            .doc(ticketId)
            .set(data);
        print("✅ Ticket guardado online");
      } catch (e) {
        print("⚠️ Error guardando online, queda offline $e");
      }
    } else {
      print("📴 Sin internet → guardado offline");
    }
  }

  // -------------------------------------------------------------
  // ✅ Cambiar estado
  // -------------------------------------------------------------

  Future<void> _updateStatus(
    String ticketId,
    String status, {
    Map<String, dynamic>? extra,
  }) async {
    final data = {
      "status": status,
      "updatedAt": DateTime.now().toIso8601String(),
      "synced": await isOnline,
      ...?extra,
    };

    // Guardar local
    final tickets = (_box.get("tickets") as List?)?.cast<Map>() ?? [];
    final idx = tickets.indexWhere((t) => t["ticketId"] == ticketId);

    if (idx != -1) {
      tickets[idx].addAll(data);
    } else {
      print("⚠ Ticket $ticketId no está offline, agregando...");
      tickets.add({
        "ticketId": ticketId,
        ...data,
      });
    }

    await _box.put("tickets", tickets);

    // Online
    if (await isOnline) {
      try {
        await _firestore
            .collection("valetTickets")
            .doc(ticketId)
            .set(data, SetOptions(merge: true));
      } catch (e) {
        print("⚠ Error actualizando online $e");
      }
    }
  }

  /// ✅ Confirmar entrega del auto (cuando el cliente lo deja)
  Future<void> confirmDropOff(String ticketId) async {
    await _updateStatus(ticketId, "entregado", extra: {
      "deliveredAt": DateTime.now().toIso8601String(),
    });
  }

  /// ✅ Solicitar vehículo (RF-05)
  Future<void> requestVehicle(String ticketId) async {
    await _updateStatus(ticketId, "solicitado", extra: {
      "requestedAt": DateTime.now().toIso8601String(),
    });
  }

  /// ✅ Confirmar que ya recibió el vehículo
  Future<void> confirmPickup(String ticketId) async {
    await _updateStatus(ticketId, "recibido", extra: {
      "receivedAt": DateTime.now().toIso8601String(),
    });
  }

  /// ✅ Actualizar ticket genérico (estado u otros campos)
  Future<void> updateTicket({
    required String ticketId,
    required Map<String, dynamic> updates,
  }) async {
    final tickets = (_box.get("tickets") as List?)?.cast<Map<String, dynamic>>() ?? [];

    final idx = tickets.indexWhere((t) => t["ticketId"] == ticketId);

    final data = {
      ...updates,
      "updatedAt": DateTime.now().toIso8601String(),
      "synced": await isOnline,
    };

    if (idx != -1) {
      tickets[idx].addAll(data);
    } else {
      print("⚠ Ticket $ticketId no está offline, agregando...");
      tickets.add({"ticketId": ticketId, ...data});
    }

    await _box.put("tickets", tickets);

    if (await isOnline) {
      try {
        await _firestore
            .collection("valetTickets")
            .doc(ticketId)
            .set(data, SetOptions(merge: true));
        print("✅ Ticket actualizado online");
      } catch (e) {
        print("⚠️ Error actualizando online $e");
      }
    }
  }

  // -------------------------------------------------------------
  // ✅ Sincronizar cuando vuelve internet
  // -------------------------------------------------------------
  Future<void> syncOfflineTickets() async {
    if (!await isOnline) return;

    final tickets = (_box.get("tickets") as List?)?.cast<Map>() ?? [];

    for (var t in tickets) {
      if (t["synced"] == true) continue;

      try {
        final newData = Map<String, dynamic>.from(t);
        newData["synced"] = true;

        await _firestore
            .collection("valetTickets")
            .doc(t["ticketId"])
            .set(newData, SetOptions(merge: true));

        t["synced"] = true;
      } catch (e) {
        print("⚠️ No se pudo sincronizar $e");
      }
    }

    await _box.put("tickets", tickets);
  }
}
