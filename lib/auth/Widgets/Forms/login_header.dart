import 'package:flutter/material.dart';
import 'package:constructionproject/core/constants/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _AppLogo(),
        SizedBox(height: 24),
        _WelcomeText(),
        SizedBox(height: 8),
        _SubtitleText(),
      ],
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.construction,
        size: 40,
        color: Colors.white,
      ),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Welcome Back',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
}

class _SubtitleText extends StatelessWidget {
  const _SubtitleText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Sign in to continue to Construction Management',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }
}