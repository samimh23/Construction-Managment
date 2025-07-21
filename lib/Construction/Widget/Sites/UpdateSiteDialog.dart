import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Provider/ConstructionSite/Provider.dart';

class AddSiteDialog extends StatefulWidget {
  final LatLng tappedPoint;
  final VoidCallback onSiteAdded;
  const AddSiteDialog({super.key, required this.tappedPoint, required this.onSiteAdded});

  @override
  State<AddSiteDialog> createState() => _AddSiteDialogState();
}

class _AddSiteDialogState extends State<AddSiteDialog> {
  late TextEditingController nameController;
  late TextEditingController adresseController;
  late TextEditingController geofenceController;
  late TextEditingController geofenceLatController;
  late TextEditingController geofenceLngController;
  late TextEditingController ownerController;
  late TextEditingController budgetController;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    adresseController = TextEditingController();
    geofenceController = TextEditingController();
    geofenceLatController = TextEditingController(text: widget.tappedPoint.latitude.toString());
    geofenceLngController = TextEditingController(text: widget.tappedPoint.longitude.toString());
    ownerController = TextEditingController();
    budgetController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    adresseController.dispose();
    geofenceController.dispose();
    geofenceLatController.dispose();
    geofenceLngController.dispose();
    ownerController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      title: Row(
        children: [
          Icon(Icons.add_location_alt, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text('Add Construction Site',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text("General", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondary)),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Site Name',
                prefixIcon: Icon(Icons.business, size: 20, color: AppColors.primaryDark),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: adresseController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_city, size: 20, color: AppColors.secondary),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: budgetController,
              decoration: InputDecoration(
                labelText: 'Budget',
                prefixIcon: Icon(Icons.attach_money, size: 20, color: AppColors.success),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text("Geofence", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondary)),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: geofenceController,
                    decoration: InputDecoration(
                      labelText: 'Radius (m)',
                      prefixIcon: Icon(Icons.circle_outlined, size: 20, color: AppColors.info),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: geofenceLatController,
                    decoration: InputDecoration(
                      labelText: 'Lat',
                      prefixIcon: Icon(Icons.my_location, size: 18, color: AppColors.accent),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: geofenceLngController,
                    decoration: InputDecoration(
                      labelText: 'Lng',
                      prefixIcon: Icon(Icons.my_location, size: 18, color: AppColors.accent),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text("Owner", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondary)),
            ),
            TextField(
              controller: ownerController,
              decoration: InputDecoration(
                labelText: 'Owner Mongo ID',
                prefixIcon: Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text("Project Dates", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondary)),
            ),
            Row(
              children: [
                Icon(Icons.date_range, size: 20, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  endDate == null
                      ? 'End Date: Not set'
                      : 'End: ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Pick', style: TextStyle(fontSize: 13)),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 10),
                    );
                    if (picked != null) setState(() => endDate = picked);
                  },
                ),
                if (endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: AppColors.error,
                    onPressed: () => setState(() => endDate = null),
                    tooltip: "Clear",
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Map: ${widget.tappedPoint.latitude.toStringAsFixed(5)}, ${widget.tappedPoint.longitude.toStringAsFixed(5)}',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Add', style: TextStyle(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final geofenceLat = double.tryParse(geofenceLatController.text) ?? widget.tappedPoint.latitude;
            final geofenceLng = double.tryParse(geofenceLngController.text) ?? widget.tappedPoint.longitude;

            final newSite = ConstructionSite(
              id: "",
              name: nameController.text,
              adresse: adresseController.text,
              latitude: widget.tappedPoint.latitude,
              longitude: widget.tappedPoint.longitude,
              geofenceRadius: double.tryParse(geofenceController.text),
              geofenceCenterLat: geofenceLat,
              geofenceCenterLng: geofenceLng,
              startDate: DateTime.now(),
              endDate: endDate,
              budget: budgetController.text.isNotEmpty ? budgetController.text : null,
              isActive: true,
              owner: ownerController.text.trim(),
            );
            await context.read<SiteProvider>().addSite(newSite);
            widget.onSiteAdded();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}