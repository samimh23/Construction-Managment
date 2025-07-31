import 'dart:async';
import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:constructionproject/auth/Widgets/Forms/login_form.dart';
import 'package:constructionproject/auth/Widgets/Forms/login_header.dart';
import 'package:constructionproject/auth/Widgets/register_link.dart';
import 'package:constructionproject/auth/Widgets/auth_responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constructionproject/auth/models/auth_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final loginRequest = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    try {
      final success = await authProvider.login(loginRequest);
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // Error is handled by the AuthProvider
    }
  }

  void _onRememberMeChanged(bool? value) {
    setState(() {
      _rememberMe = value ?? false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _onEmailChanged(String value) {
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _emailController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveLayout(
      child: _buildLoginContent(),
    );
  }

  Widget _buildLoginContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoginHeader(),
            SizedBox(height: isSmallScreen ? 32 : 48),
            LoginForm(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              rememberMe: _rememberMe,
              onPasswordVisibilityToggle: _togglePasswordVisibility,
              onRememberMeChanged: _onRememberMeChanged,
              onEmailChanged: _onEmailChanged,
              onLogin: _handleLogin,
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            const RegisterLink(),
          ],
        );
      },
    );
  }
}