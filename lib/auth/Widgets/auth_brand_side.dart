import 'package:flutter/material.dart';
import 'package:constructionproject/core/constants/app_colors.dart';

class AuthBrandSide extends StatelessWidget {
  const AuthBrandSide({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}