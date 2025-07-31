import 'package:flutter/material.dart';
import 'package:constructionproject/core/constants/app_colors.dart';

class RegisterLink extends StatelessWidget {
  const RegisterLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          key: const Key('register_button'),
          onPressed: () {
            Navigator.of(context).pushNamed('/register');
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}