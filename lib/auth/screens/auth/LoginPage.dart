import 'dart:async';
import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:constructionproject/auth/Widgets/Forms/login_form.dart';
import 'package:constructionproject/auth/Widgets/Forms/login_header.dart';
import 'package:constructionproject/auth/Widgets/register_link.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constructionproject/auth/models/auth_models.dart';
import 'package:constructionproject/core/constants/app_colors.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _buildResponsiveLayout(context, isDesktop, isTablet, isMobile, screenHeight),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, bool isDesktop, bool isTablet, bool isMobile, double screenHeight) {
    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else if (isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context, screenHeight);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Brand/Image section
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary ?? Colors.blue,
                  AppColors.primary?.withOpacity(0.8) ?? Colors.blue.withOpacity(0.8),
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: 120,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Construction Project',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Manage your projects efficiently',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right side - Login form
        Expanded(
          flex: 2,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(48),
                child: _buildLoginContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: _buildLoginContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double screenHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if content might overflow
        final availableHeight = constraints.maxHeight;
        final isSmallScreen = availableHeight < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSmallScreen ? 16 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availableHeight - (isSmallScreen ? 32 : 48),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Flexible spacing at top
                  SizedBox(height: isSmallScreen ? 20 : 40),
                  _buildLoginContent(isMobile: true, isSmallScreen: isSmallScreen),
                  // Flexible spacing at bottom
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginContent({bool isMobile = false, bool isSmallScreen = false}) {
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
  }
}