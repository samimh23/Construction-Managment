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
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSiteIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing)
                      _buildEditableTitle()
                    else
                      _buildDisplayTitle(),
                    const SizedBox(height: 8),
                    _buildStatusIndicator(),
                  ],
                ),
              ),
              _buildActionButton(),
            ],
          ),
          if (isEditing && onActiveToggle != null) ...[
            const SizedBox(height: 20),
            _buildActiveToggle(),
          ],
        ],
      ),
    );
  }

  Widget _buildSiteIcon() {
    final statusColor = isActive == true ? AppColors.success : AppColors.error;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Icon(
        Icons.domain_rounded,
        color: statusColor,
        size: 28,
      ),
    );
  }

  Widget _buildEditableTitle() {
    return TextFormField(
      controller: nameController,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
      decoration: InputDecoration(
        hintText: "Enter site name",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  Widget _buildDisplayTitle() {
    return Text(
      nameController.text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusIndicator() {
    final statusColor = isActive == true ? AppColors.success : AppColors.error;
    final statusText = isActive == true ? "Active" : "Inactive";
    final statusIcon = isActive == true ? Icons.check_circle_rounded : Icons.pause_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: isEditing ? AppColors.error.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          isEditing ? Icons.close_rounded : Icons.edit_rounded,
          color: isEditing ? AppColors.error : AppColors.accent,
        ),
        onPressed: onEditToggle,
        tooltip: isEditing ? "Cancel" : "Edit",
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.toggle_on, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          const Text(
            "Site Status",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: isActive ?? true,
            activeColor: AppColors.success,
            inactiveThumbColor: AppColors.error,
            onChanged: onActiveToggle,
          ),
        ],
      ),
    );
  }
}