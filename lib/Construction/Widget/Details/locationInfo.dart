import 'package:flutter/material.dart';

class SiteDetailsLocationCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController adresseController;
  final TextEditingController geofenceRadiusController;
  final TextEditingController geofenceLatController;
  final TextEditingController geofenceLngController;
  final void Function(double lat, double lng)? onGoToMap;

  const SiteDetailsLocationCard({
    super.key,
    required this.isEditing,
    required this.adresseController,
    required this.geofenceRadiusController,
    required this.geofenceLatController,
    required this.geofenceLngController,
    this.onGoToMap,
  });

  @override
  Widget build(BuildContext context) {
    final latText = geofenceLatController.text;
    final lngText = geofenceLngController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddressSection(),
        const SizedBox(height: 16),
        _buildCoordinatesSection(context, latText, lngText),
        const SizedBox(height: 16),
        _buildGeofenceSection(),
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
            color: Color(0xFF6B7280),
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
                  child: const Icon(Icons.location_city_rounded, color: Color(0xFF3B82F6), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    adresseController.text.isNotEmpty ? adresseController.text : "No address provided",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: adresseController.text.isNotEmpty
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCoordinatesSection(BuildContext context, String lat, String lng) {
    final latIsValid = lat.isNotEmpty && double.tryParse(lat) != null;
    final lngIsValid = lng.isNotEmpty && double.tryParse(lng) != null;
    final canShowButton = latIsValid && lngIsValid && onGoToMap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Coordinates",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  latIsValid && lngIsValid
                      ? "$lat, $lng"
                      : "No coordinates provided",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (canShowButton)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text("Go to map", style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () {
                      final double latVal = double.parse(lat);
                      final double lngVal = double.parse(lng);
                      onGoToMap!(latVal, lngVal);
                    },
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
            color: Color(0xFF6B7280),
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
        // Only radius is editable
        _buildStyledTextField(
          controller: geofenceRadiusController,
          hintText: "Radius (meters)",
          prefixIcon: Icons.radio_button_unchecked_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        // Coordinates are displayed as read-only
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: Color(0xFF6B7280), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  geofenceLatController.text.isNotEmpty && geofenceLngController.text.isNotEmpty
                      ? "${geofenceLatController.text}, ${geofenceLngController.text}"
                      : "Coordinates are set automatically",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Info text about coordinates
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Coordinates are automatically set based on site location",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
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
            const Color(0xFF3B82F6),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
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
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF3B82F6), size: 20),
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
}