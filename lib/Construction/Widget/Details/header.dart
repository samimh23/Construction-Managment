import 'package:flutter/material.dart';

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
    return Column(
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
            // Removed the action button from here since it's now in the card header
          ],
        ),
        if (isEditing && onActiveToggle != null) ...[
          const SizedBox(height: 20),
          _buildActiveToggle(),
        ],
      ],
    );
  }

  Widget _buildSiteIcon() {
    final statusColor = isActive == true ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
      ),
      child: Icon(
        Icons.domain_rounded,
        color: statusColor,
        size: 24,
      ),
    );
  }

  Widget _buildEditableTitle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: nameController,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: "Enter site name",
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDisplayTitle() {
    return Text(
      nameController.text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusIndicator() {
    final statusColor = isActive == true ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final statusText = isActive == true ? "Active" : "Inactive";

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.toggle_on, color: Color(0xFF3B82F6), size: 16),
          ),
          const SizedBox(width: 12),
          const Text(
            "Site Status",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: isActive ?? true,
            activeColor: const Color(0xFF10B981),
            inactiveThumbColor: const Color(0xFFEF4444),
            onChanged: onActiveToggle,
          ),
        ],
      ),
    );
  }
}