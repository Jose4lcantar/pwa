import 'package:flutter/material.dart';
import 'privacy_screen.dart';

// ✅ Importar servicio
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // ✅ Instancia de UserService
  final _userService = UserService();

  bool _hasAcceptedPrivacy = false;
  bool _isLoading = false;

  String _errorMessage = '';

  /// ✅ Guardar usuario usando UserService()
  Future<void> _saveUser() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa tu nombre.';
        _isLoading = false;
      });
      return;
    }

    if (!_hasAcceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar la Política de Privacidad.'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // ✅ Guarda usando UserService
    await _userService.saveUser(name: name, phone: phone);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }

    setState(() => _isLoading = false);
  }

  void _showPrivacy() {
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Registra tus datos',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0175C2),
                        ),
                      ),
                      const SizedBox(height: 24),

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
                        onPressed: _showPrivacy,
                        icon: Icon(
                          _hasAcceptedPrivacy
                              ? Icons.check_circle
                              : Icons.privacy_tip_outlined,
                          color: _hasAcceptedPrivacy ? Colors.green : null,
                        ),
                        label: Text(
                          _hasAcceptedPrivacy
                              ? 'Política aceptada'
                              : 'Leer Política de Privacidad',
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _saveUser,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: const Color(0xFF0175C2),
                                ),
                                child: const Text(
                                  'Continuar',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                      ),

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
}
