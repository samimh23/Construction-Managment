import 'package:flutter/material.dart';

class ConfirmCodeScreen extends StatefulWidget {
  const ConfirmCodeScreen({Key? key}) : super(key: key);

  @override
  State<ConfirmCodeScreen> createState() => _ConfirmCodeScreenState();
}

class _ConfirmCodeScreenState extends State<ConfirmCodeScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  late final String email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    email = ModalRoute.of(context)?.settings.arguments as String;
  }

  Future<void> _handleConfirmCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Optionally, you can verify the code via API, or skip to reset password
    Navigator.of(context).pushReplacementNamed('/reset-password', arguments: {'email': email, 'code': _codeController.text.trim()});
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter the code sent to $email'),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reset Code'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _handleConfirmCode,
              child: _loading ? const CircularProgressIndicator() : const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}