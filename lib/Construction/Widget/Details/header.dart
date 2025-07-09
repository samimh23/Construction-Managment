import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsHeader extends StatelessWidget {
  final TextEditingController nameController;
  final bool isEditing;
  final bool? isActive;
  final VoidCallback onEditToggle;
  final ValueChanged<bool>? onActiveToggle;

  const SiteDetailsHeader({
    super.key,
    required this.nameController,
    required this.isEditing,
    required this.isActive,
    required this.onEditToggle,
    this.onActiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.headlineSmall?.copyWith(
      color: AppColors.primaryDark,
      fontWeight: FontWeight.bold,
    );
    return Row(
      children: [
        Icon(Icons.business, color: AppColors.primary, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: isEditing
              ? TextField(
            controller: nameController,
            enabled: isEditing,
            decoration: const InputDecoration(
              labelText: "Site Name",
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          )
              : Text(
            nameController.text,
            style: headerStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isActive == true)
          Chip(
            label: const Text("Active", style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.success,
            avatar: const Icon(Icons.check_circle, color: Colors.white, size: 18),
          )
        else
          Chip(
            label: const Text("Inactive", style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
            avatar: const Icon(Icons.remove_circle, color: Colors.white, size: 18),
          ),
        if (isEditing && onActiveToggle != null)
          Switch(
            value: isActive ?? true,
            activeColor: AppColors.success,
            inactiveThumbColor: AppColors.error,
            onChanged: onActiveToggle,
          ),
        IconButton(
          icon: Icon(isEditing ? Icons.cancel : Icons.edit, color: AppColors.accent),
          tooltip: isEditing ? "Cancel" : "Edit",
          onPressed: onEditToggle,
        ),
      ],
    );
  }
}