import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constructionproject/auth/Providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _handleSendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    // Optional: Basic email validation
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _loading = false;
        _error = "Please enter a valid email address.";
      });
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.sendResetCode(email);

      if (success) {
        Navigator.of(context).pushReplacementNamed('/confirm-code', arguments: email);
      } else {
        setState(() {
          _error = authProvider.errorMessage ?? "Failed to send reset code.";
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Enter your email to receive a reset code.'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _handleSendCode,
              child: _loading ? const CircularProgressIndicator() : const Text('Send Code'),
            ),
          ],
        ),
      ),
    );
  }
}