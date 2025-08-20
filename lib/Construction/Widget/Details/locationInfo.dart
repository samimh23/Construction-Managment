import 'package:flutter/material.dart';

class SiteDetailsLocationCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController adresseController;
  final TextEditingController geofenceRadiusController;
  final TextEditingController siteLatController;
  final TextEditingController siteLngController;
  final void Function(double lat, double lng)? onGoToMap;

  const SiteDetailsLocationCard({
    super.key,
    required this.isEditing,
    required this.adresseController,
    required this.geofenceRadiusController,
    required this.siteLatController,
    required this.siteLngController,
    this.onGoToMap,
  });

  // Dashboard colors
  static const Color _primaryBlue = Color(0xFF4285F4);
  static const Color _successGreen = Color(0xFF34A853);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _borderGray = Color(0xFFE8EAED);
  static const Color _textGray = Color(0xFF5F6368);
  static const Color _darkText = Color(0xFF202124);

  @override
  Widget build(BuildContext context) {
    final latText = siteLatController.text;
    final lngText = siteLngController.text;
    final latIsValid = latText.isNotEmpty && double.tryParse(latText) != null;
    final lngIsValid = lngText.isNotEmpty && double.tryParse(lngText) != null;
    final canShowButton = latIsValid && lngIsValid && onGoToMap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddressSection(),
        const SizedBox(height: 16),
        _buildCoordinatesSection(context, latText, lngText, canShowButton),
        const SizedBox(height: 16),
        _buildGeofenceSection(),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textGray,
          ),
        ),
        const SizedBox(height: 8),
        isEditing
            ? _buildTextField(
          controller: adresseController,
          hintText: "Enter site address",
          maxLines: 2,
        )
            : _buildDisplayField(
          adresseController.text.isNotEmpty
              ? adresseController.text
              : "No address provided",
        ),
      ],
    );
  }

  Widget _buildCoordinatesSection(BuildContext context, String lat, String lng, bool canShowButton) {
    final latIsValid = lat.isNotEmpty && double.tryParse(lat) != null;
    final lngIsValid = lng.isNotEmpty && double.tryParse(lng) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GPS Coordinates',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textGray,
          ),
        ),
        const SizedBox(height: 8),
        isEditing
            ? Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: siteLatController,
                hintText: "Latitude",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: siteLngController,
                hintText: "Longitude",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        )
            : Column(
          children: [
            _buildDisplayField(
              latIsValid && lngIsValid
                  ? "$lat, $lng"
                  : "No coordinates provided",
            ),
            if (canShowButton) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text("View on Map"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () {
                    final double latVal = double.parse(lat);
                    final double lngVal = double.parse(lng);
                    onGoToMap!(latVal, lngVal);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGeofenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geofence Radius (meters)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textGray,
          ),
        ),
        const SizedBox(height: 8),
        isEditing
            ? _buildTextField(
          controller: geofenceRadiusController,
          hintText: "Radius in meters",
          keyboardType: TextInputType.number,
        )
            : _buildDisplayField(
          geofenceRadiusController.text.isNotEmpty
              ? "${geofenceRadiusController.text} meters"
              : "No geofence radius set",
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderGray),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _textGray.withOpacity(0.7)),
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

  Widget _buildDisplayField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderGray),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _darkText,
        ),
      ),
    );
  }
}