import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showLabel;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final strength = Validators.getPasswordStrength(password);
    final strengthText = Validators.getPasswordStrengthText(strength);
    final strengthColor = _getStrengthColor(strength);
    final progress = _getStrengthProgress(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.lightGrey,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: strengthColor,
                    ),
                  ),
                ),
              ),
            ),
            if (showLabel && password.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: strengthColor,
                ),
              ),
            ],
          ],
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildRequirements(),
        ],
      ],
    );
  }

  Widget _buildRequirements() {
    final requirements = [
      _RequirementItem(
        text: 'At least 8 characters',
        isMet: password.length >= 8,
      ),
      _RequirementItem(
        text: 'One uppercase letter',
        isMet: password.contains(RegExp(r'[A-Z]')),
      ),
      _RequirementItem(
        text: 'One lowercase letter',
        isMet: password.contains(RegExp(r'[a-z]')),
      ),
      _RequirementItem(
        text: 'One number',
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      _RequirementItem(
        text: 'One special character',
        isMet: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];

    return Column(
      children: requirements
          .map((requirement) => _buildRequirementRow(requirement))
          .toList(),
    );
  }

  Widget _buildRequirementRow(_RequirementItem requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            requirement.isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: requirement.isMet ? AppColors.success : AppColors.mediumGrey,
          ),
          const SizedBox(width: 8),
          Text(
            requirement.text,
            style: TextStyle(
              fontSize: 12,
              color: requirement.isMet ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.primaryBlue;
      case PasswordStrength.veryStrong:
        return AppColors.success;
    }
  }

  double _getStrengthProgress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}

class _RequirementItem {
  final String text;
  final bool isMet;

  _RequirementItem({
    required this.text,
    required this.isMet,
  });
}