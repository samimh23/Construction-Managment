import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Core/Constants/api_constants.dart';
import '../../Widget/Details/ProjectInfo.dart';
import '../../Widget/Details/WorkersCard.dart';
import '../../Widget/Details/dateCard.dart';
import '../../Widget/Details/header.dart';
import '../../Widget/Details/locationInfo.dart';



class SiteDetailsScreen extends StatefulWidget {
  final ConstructionSite site;
  const SiteDetailsScreen({super.key, required this.site});

  @override
  State<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends State<SiteDetailsScreen> {
  bool isEditing = false;

  // Controllers
  late TextEditingController nameController;
  late TextEditingController adresseController;
  late TextEditingController budgetController;
  late TextEditingController ownerController;
  late TextEditingController managerController;
  late TextEditingController geofenceRadiusController;
  late TextEditingController geofenceLatController;
  late TextEditingController geofenceLngController;
  DateTime? startDate;
  DateTime? endDate;
  bool? isActive;

  final Dio dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: ApiConstants.defaultHeaders,
    connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
    receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
    sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
  ));

  @override
  void initState() {
    super.initState();
    _initControllersFromSite(widget.site);
  }

  void _initControllersFromSite(ConstructionSite site) {
    nameController = TextEditingController(text: site.name);
    adresseController = TextEditingController(text: site.adresse);
    budgetController = TextEditingController(text: site.budget ?? "");
    ownerController = TextEditingController(text: site.owner);
    managerController = TextEditingController(text: site.manager ?? "");
    geofenceRadiusController = TextEditingController(text: site.geofenceRadius?.toString() ?? "");
    geofenceLatController = TextEditingController(text: site.geofenceCenterLat?.toString() ?? "");
    geofenceLngController = TextEditingController(text: site.geofenceCenterLng?.toString() ?? "");
    startDate = site.startDate;
    endDate = site.endDate;
    isActive = site.isActive;
  }

  Future<void> _updateSite() async {
    if (widget.site.id == null || widget.site.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Site ID is missing! Cannot update."), backgroundColor: AppColors.error),
      );
      return;
    }

    final endpoint = '${ApiConstants.UpdateConstructionsite}${widget.site.id}';

    final updatedSite = {
      "name": nameController.text,
      "adresse": adresseController.text,
      "Budget": budgetController.text.isNotEmpty ? budgetController.text : null,
      "owner": ownerController.text,
      "manager": managerController.text,
      "GeoLocation": {
        "longitude": widget.site.longitude.toString(),
        "Latitude": widget.site.latitude.toString()
      },
      "GeoFence": {
        "center": {
          "longitude": geofenceLngController.text,
          "Latitude": geofenceLatController.text
        },
        "radius": geofenceRadiusController.text
      },
      "StartDate": startDate?.toIso8601String(),
      "EndDate": endDate?.toIso8601String(),
      "isActive": isActive,
    };

    try {
      final response = await dio.patch(
        endpoint,
        data: updatedSite,
      );

      if (response.statusCode == ApiConstants.statusOk ||
          response.statusCode == ApiConstants.statusCreated) {
        final updatedData = response.data;
        setState(() {
          isEditing = false;
          // update controllers with new values
          nameController.text = updatedData['name'] ?? nameController.text;
          adresseController.text = updatedData['adresse'] ?? adresseController.text;
          budgetController.text = updatedData['Budget']?.toString() ?? '';
          ownerController.text = updatedData['owner'] ?? ownerController.text;
          managerController.text = updatedData['manager'] ?? managerController.text;
          geofenceRadiusController.text = updatedData['GeoFence']?['radius']?.toString() ?? '';
          geofenceLatController.text = updatedData['GeoFence']?['center']?['Latitude']?.toString() ?? '';
          geofenceLngController.text = updatedData['GeoFence']?['center']?['longitude']?.toString() ?? '';
          startDate = updatedData['StartDate'] != null ? DateTime.tryParse(updatedData['StartDate']) : null;
          endDate = updatedData['EndDate'] != null ? DateTime.tryParse(updatedData['EndDate']) : null;
          isActive = updatedData['isActive'] ?? isActive;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Site updated!", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update site", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error!", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      color: AppColors.secondary, fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      color: AppColors.primary, fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(isEditing ? "Edit Site" : nameController.text, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: "Save",
              onPressed: _updateSite,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          children: [
            SiteDetailsHeader(
              nameController: nameController,
              isEditing: isEditing,
              isActive: isActive,
              onEditToggle: () {
                setState(() {
                  isEditing = !isEditing;
                });
              },
              onActiveToggle: (val) => setState(() => isActive = val),
            ),
            const SizedBox(height: 18),
            SiteDetailsLocationCard(
              isEditing: isEditing,
              adresseController: adresseController,
              geofenceRadiusController: geofenceRadiusController,
              geofenceLatController: geofenceLatController,
              geofenceLngController: geofenceLngController,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            const SizedBox(height: 16),
            SiteDetailsDatesCard(
              isEditing: isEditing,
              startDate: startDate,
              endDate: endDate,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
              onStartDateChanged: (date) => setState(() => startDate = date),
              onEndDateChanged: (date) => setState(() => endDate = date),
            ),
            const SizedBox(height: 16),
            SiteDetailsProjectInfoCard(
              isEditing: isEditing,
              budgetController: budgetController,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            const SizedBox(height: 16),
            SiteDetailsPeopleCard(
              isEditing: isEditing,
              ownerController: ownerController,
              managerController: managerController,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            if (isEditing) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _updateSite,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    isEditing = false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    adresseController.dispose();
    budgetController.dispose();
    ownerController.dispose();
    managerController.dispose();
    geofenceRadiusController.dispose();
    geofenceLatController.dispose();
    geofenceLngController.dispose();
    super.dispose();
  }
}