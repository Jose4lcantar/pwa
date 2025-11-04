import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/auth_service.dart'; // 👈 Importa tu servicio de autenticación

class PrivacyScreen extends StatefulWidget {
  final bool readOnly; // 👈 Solo lectura
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  const PrivacyScreen({
    Key? key,
    this.readOnly = false,
    this.onAccepted,
    this.onDeclined,
  }) : super(key: key);

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _hasRead = false;
  bool _isAccepted = false;
  String _privacyText = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPrivacyText();

    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        setState(() => _hasRead = true);
      }
    });
  }

  Future<void> _loadPrivacyText() async {
    final text =
        await rootBundle.loadString('shared/documents/privacy_policy.md');
    setState(() => _privacyText = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protección de Datos Personales'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _privacyText.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Text(
                          _privacyText,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (!widget.readOnly)
              CheckboxListTile(
                title: const Text(
                  'He leído y acepto la Política de Privacidad',
                  style: TextStyle(fontSize: 16),
                ),
                value: _isAccepted,
                onChanged: _hasRead
                    ? (value) {
                        setState(() => _isAccepted = value ?? false);
                      }
                    : null,
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDeclined ??
                        () async {
                          if (widget.readOnly) {
                            // 👈 Cierra sesión
                            await AuthService().logout();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Debes aceptar los términos para usar la app.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );

                              // 👈 Redirige al login eliminando historial
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
                            }
                          } else {
                            Navigator.pop(context);
                          }
                        },
                    child: Text(widget.readOnly
                        ? 'Deniego los términos y condiciones'
                        : 'No aceptar'),
                  ),
                ),
                if (!widget.readOnly) const SizedBox(width: 10),
                if (!widget.readOnly)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAccepted ? widget.onAccepted : null,
                      child: const Text('Continuar'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
