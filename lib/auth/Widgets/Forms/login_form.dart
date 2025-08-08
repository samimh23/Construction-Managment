import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:constructionproject/auth/Widgets/Forms/custom_text%20_field.dart';
import 'package:constructionproject/auth/Widgets/Forms/error_display.dart';
import 'package:constructionproject/auth/Widgets/Forms/login_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constructionproject/core/constants/app_colors.dart';
import 'package:constructionproject/core/utils/validators.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onPasswordVisibilityToggle;
  final ValueChanged<bool?> onRememberMeChanged;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onLogin;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onPasswordVisibilityToggle,
    required this.onRememberMeChanged,
    required this.onEmailChanged,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          CustomTextField(
            key: const Key('email_field'),
            label: 'Email Address',
            hint: 'Enter your email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: Validators.email,
            required: true,
            onChanged: onEmailChanged,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            key: const Key('password_field'),
            label: 'Password',
            hint: 'Enter your password',
            controller: passwordController,
            obscureText: obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              key: const Key('password_visibility_toggle'),
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: onPasswordVisibilityToggle,
            ),
            validator: Validators.password,
            required: true,
          ),
          const SizedBox(height: 16),
          _RememberMeRow(
            rememberMe: rememberMe,
            onChanged: onRememberMeChanged,
          ),
          const SizedBox(height: 32),
          // Safe Selector with null check
          Builder(
            builder: (context) {
              try {
                return Selector<AuthProvider, String?>(
                  selector: (context, provider) => provider.errorMessage,
                  builder: (context, errorMessage, child) {
                    return ErrorDisplay(errorMessage: errorMessage);
                  },
                );
              } catch (e) {
                // Fallback if provider is not available
                return const SizedBox.shrink();
              }
            },
          ),
          const SizedBox(height: 16),
          // Safe Selector with null check
          Builder(
            builder: (context) {
              try {
                return Selector<AuthProvider, bool>(
                  selector: (context, provider) => provider.isLoading,
                  builder: (context, isLoading, child) {
                    return LoginButton(
                      isLoading: isLoading,
                      onPressed: onLogin,
                    );
                  },
                );
              } catch (e) {
                // Fallback if provider is not available
                return LoginButton(
                  isLoading: false,
                  onPressed: onLogin,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _RememberMeRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool?> onChanged;

  const _RememberMeRow({
    required this.rememberMe,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          key: const Key('remember_me_checkbox'),
          value: rememberMe,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        const Text('Remember me'),
        const Spacer(),
        TextButton(
          key: const Key('forgot_password_button'),
          onPressed: () {
             Navigator.of(context).pushNamed('/forgot-password');

          },
          child: const Text('Forgot Password?'),
        ),
      ],
    );
  }
}