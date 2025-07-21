import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsLocationCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController adresseController;
  final TextEditingController geofenceRadiusController;
  final TextEditingController geofenceLatController;
  final TextEditingController geofenceLngController;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const SiteDetailsLocationCard({
    super.key,
    required this.isEditing,
    required this.adresseController,
    required this.geofenceRadiusController,
    required this.geofenceLatController,
    required this.geofenceLngController,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text("Location", style: labelStyle),
              ],
            ),
            const SizedBox(height: 4),
            isEditing
                ? TextField(
              controller: adresseController,
              enabled: true,
              decoration: const InputDecoration(
                labelText: "Address",
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            )
                : Row(
              children: [
                Icon(Icons.location_city, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(adresseController.text, style: labelStyle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Lat: ${geofenceLatController.text}, Lng: ${geofenceLngController.text}", style: valueStyle),
            const SizedBox(height: 8),
            isEditing
                ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: geofenceRadiusController,
                    enabled: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Geofence Radius",
                      prefixIcon: Icon(Icons.circle_outlined, color: AppColors.info),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: geofenceLatController,
                    enabled: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Geofence Lat",
                      prefixIcon: Icon(Icons.my_location, color: AppColors.accent),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: geofenceLngController,
                    enabled: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Geofence Lng",
                      prefixIcon: Icon(Icons.my_location, color: AppColors.accent),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (geofenceRadiusController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.circle_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text("Geofence radius: ", style: labelStyle),
                        Text(geofenceRadiusController.text, style: valueStyle),
                      ],
                    ),
                  ),
                if (geofenceLatController.text.isNotEmpty && geofenceLngController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text("Geofence center: ", style: labelStyle),
                        Text("${geofenceLatController.text}, ${geofenceLngController.text}", style: valueStyle),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}