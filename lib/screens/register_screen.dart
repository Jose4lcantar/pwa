import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'privacy_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String ticketId;

  const RegisterScreen({super.key, required this.ticketId});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _hasAcceptedPrivacy = false;
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, dynamic>? ticketData;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  /// 🟦 Cargar datos existentes desde Firestore
  Future<void> _loadTicket() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("qr_codes")
          .doc(widget.ticketId)
          .get();

      if (!doc.exists) {
        setState(() {
          error = "Este ticket no existe.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        ticketData = doc.data()!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Error al cargar datos.";
        _isLoading = false;
      });
    }
  }

  /// 🟦 Guardar datos del cliente
  Future<void> _saveData() async {
    if (!_hasAcceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes aceptar la Política de Privacidad.")),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa tu nombre.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection("qr_codes")
          .doc(widget.ticketId)
          .update({
        "clientName": _nameController.text.trim(),
        "clientPhone": _phoneController.text.trim(),
        "status": "iniciado",
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, "/service_status");
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar. Inténtalo.")),
      );
    }
  }

  /// 🟦 Mostrar pantalla
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(child: Text(error!, style: const TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0175C2), Color(0xFF00AEEF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Datos del vehículo",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0175C2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _infoTile("Placa", ticketData?["plate"]),
                      _infoTile("Modelo", ticketData?["model"]),
                      _infoTile("Lugar asignado", ticketData?["parkingSpot"]),
                      _infoTile("Hora de llegada", ticketData?["arrivalTime"]?.toString()),

                      const SizedBox(height: 24),

                      const Text(
                        "Ingresa tus datos",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivacyScreen(
                                readOnly: false,
                                onAccepted: () {
                                  setState(() => _hasAcceptedPrivacy = true);
                                  Navigator.pop(context);
                                },
                                onDeclined: () {
                                  setState(() => _hasAcceptedPrivacy = false);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          _hasAcceptedPrivacy ? Icons.check_circle : Icons.privacy_tip,
                          color: _hasAcceptedPrivacy ? Colors.green : null,
                        ),
                        label: Text(_hasAcceptedPrivacy
                            ? "Política aceptada"
                            : "Leer Política de Privacidad"),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: _isSaving
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _saveData,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF0175C2),
                                ),
                                child: const Text("Continuar", style: TextStyle(fontSize: 18)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String? value) {
    if (value == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
