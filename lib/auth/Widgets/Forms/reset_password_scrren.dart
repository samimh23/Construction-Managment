import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constructionproject/auth/Providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  late final String email;
  late final String code;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    email = args?['email'];
    code = args?['code'];
  }

  Future<void> _handleResetPassword() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.resetPasswordWithCode(
        email: email,
        code: code,
        newPassword: _passwordController.text,
      );
      if (success) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() {
          _error = authProvider.errorMessage ?? "Failed to reset password.";
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
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter your new password for $email'),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _handleResetPassword,
              child: _loading ? const CircularProgressIndicator() : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}