import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsPeopleCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController ownerController;
  final TextEditingController managerController;

  const SiteDetailsPeopleCard({
    super.key,
    required this.isEditing,
    required this.ownerController,
    required this.managerController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildManagerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.people_rounded, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          "Team Members",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerSection() {
    return _buildPersonField(
      label: "Project Owner",
      controller: ownerController,
      icon: Icons.person_rounded,
      color: AppColors.primary,
      hintText: "Enter owner name",
      isRequired: true,
    );
  }

  Widget _buildManagerSection() {
    return _buildPersonField(
      label: "Project Manager",
      controller: managerController,
      icon: Icons.supervisor_account_rounded,
      color: AppColors.secondary,
      hintText: "Enter manager name",
      isRequired: false,
    );
  }

  Widget _buildPersonField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    required String hintText,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                "*",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (isEditing)
          _buildEditablePersonField(controller, icon, color, hintText)
        else
          _buildDisplayPersonField(controller, icon, color, isRequired),
      ],
    );
  }

  Widget _buildEditablePersonField(
      TextEditingController controller,
      IconData icon,
      Color color,
      String hintText,
      ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDisplayPersonField(
      TextEditingController controller,
      IconData icon,
      Color color,
      bool isRequired,
      ) {
    final hasValue = controller.text.isNotEmpty;

    if (!hasValue && !isRequired) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasValue ? color.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasValue ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: hasValue ? color : AppColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasValue ? controller.text : "Not assigned",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? AppColors.primaryDark : AppColors.secondary,
                  ),
                ),
                if (hasValue)
                  Text(
                    "Team member",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (hasValue)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}