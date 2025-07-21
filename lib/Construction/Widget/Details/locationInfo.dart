import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsLocationCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController adresseController;
  final TextEditingController geofenceRadiusController;
  final TextEditingController geofenceLatController;
  final TextEditingController geofenceLngController;

  const SiteDetailsLocationCard({
    super.key,
    required this.isEditing,
    required this.adresseController,
    required this.geofenceRadiusController,
    required this.geofenceLatController,
    required this.geofenceLngController,
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
            const SizedBox(height: 20),
            _buildAddressSection(),
            const SizedBox(height: 20),
            _buildCoordinatesSection(),
            const SizedBox(height: 20),
            _buildGeofenceSection(),
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
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_on_rounded, color: AppColors.info, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          "Location & Geofence",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Address",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          _buildStyledTextField(
            controller: adresseController,
            hintText: "Enter site address",
            prefixIcon: Icons.location_city_rounded,
            maxLines: 2,
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_city_rounded,
                    color: AppColors.secondary.withOpacity(0.7), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    adresseController.text.isNotEmpty ? adresseController.text : "No address provided",
                    style: TextStyle(
                      fontSize: 14,
                      color: adresseController.text.isNotEmpty
                          ? AppColors.primaryDark
                          : AppColors.secondary.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCoordinatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Coordinates",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.my_location_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Lat: ${geofenceLatController.text}, Lng: ${geofenceLngController.text}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeofenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Geofence Settings",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        if (isEditing)
          _buildGeofenceEditFields()
        else
          _buildGeofenceDisplayInfo(),
      ],
    );
  }

  Widget _buildGeofenceEditFields() {
    return Column(
      children: [
        _buildStyledTextField(
          controller: geofenceRadiusController,
          hintText: "Radius (meters)",
          prefixIcon: Icons.radio_button_unchecked_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStyledTextField(
                controller: geofenceLatController,
                hintText: "Latitude",
                prefixIcon: Icons.south_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStyledTextField(
                controller: geofenceLngController,
                hintText: "Longitude",
                prefixIcon: Icons.east_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeofenceDisplayInfo() {
    return Column(
      children: [
        if (geofenceRadiusController.text.isNotEmpty)
          _buildInfoRow(
            Icons.radio_button_unchecked_rounded,
            "Radius",
            "${geofenceRadiusController.text} meters",
            AppColors.info,
          ),
        if (geofenceLatController.text.isNotEmpty && geofenceLngController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.gps_fixed_rounded,
            "Center",
            "${geofenceLatController.text}, ${geofenceLngController.text}",
            AppColors.accent,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.accent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}