import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class PrivacyScreen extends StatefulWidget {
  final bool readOnly; 
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
        title: const Text('Política de Privacidad'),
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

            // 🔹 Si es solo lectura → NO mostrar controles
            if (!widget.readOnly) ...[
              CheckboxListTile(
                title: const Text(
                  'He leído y acepto la Política de Privacidad',
                  style: TextStyle(fontSize: 16),
                ),
                value: _isAccepted,
                onChanged: _hasRead
                    ? (value) => setState(() => _isAccepted = value ?? false)
                    : null,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDeclined ??
                          () {
                            Navigator.pop(context);
                          },
                      child: const Text('No aceptar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAccepted ? widget.onAccepted : null,
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
