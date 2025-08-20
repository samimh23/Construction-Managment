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

  // Dashboard colors
  static const Color _primaryBlue = Color(0xFF4285F4);
  static const Color _successGreen = Color(0xFF34A853);
  static const Color _warningRed = Color(0xFFEA4335);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _borderGray = Color(0xFFE8EAED);
  static const Color _textGray = Color(0xFF5F6368);
  static const Color _darkText = Color(0xFF202124);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing)
          _buildEditableNameField()
        else
          _buildDisplayNameField(),

        const SizedBox(height: 16),

        _buildStatusSection(),

        if (isEditing && onActiveToggle != null) ...[
          const SizedBox(height: 16),
          _buildActiveToggle(),
        ],
      ],
    );
  }

  Widget _buildEditableNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderGray),
      ),
      child: TextFormField(
        controller: nameController,
        enabled: isEditing,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _darkText,
        ),
        decoration: InputDecoration(
          labelText: 'Site Name',
          labelStyle: TextStyle(color: _textGray, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: _primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayNameField() {
    return Text(
      nameController.text.isNotEmpty ? nameController.text : 'Untitled Site',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: _darkText,
      ),
    );
  }

  Widget _buildStatusSection() {
    final statusColor = isActive == true ? _successGreen : _warningRed;
    final statusText = isActive == true ? 'Active' : 'Inactive';

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
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: _textGray,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderGray),
      ),
      child: Row(
        children: [
          Icon(
            Icons.toggle_on,
            color: _textGray,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Site Status',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: _darkText,
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: isActive ?? true,
            activeColor: _successGreen,
            inactiveThumbColor: _warningRed,
            onChanged: onActiveToggle,
          ),
        ],
      ),
    );
  }
}