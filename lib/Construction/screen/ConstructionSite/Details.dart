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

class _SiteDetailsScreenState extends State<SiteDetailsScreen> with TickerProviderStateMixin {
  bool isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
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
      _showSnackBar("Site ID is missing! Cannot update.", isError: true);
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
      final response = await dio.patch(endpoint, data: updatedSite);

      if (response.statusCode == ApiConstants.statusOk ||
          response.statusCode == ApiConstants.statusCreated) {
        final updatedData = response.data;
        setState(() {
          isEditing = false;
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
        _showSnackBar("Site updated successfully!", isError: false);
      } else {
        _showSnackBar("Failed to update site", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error occurred", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool isWebLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800;
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: EdgeInsets.all(isWeb ? 32.0 : 20.0),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: isWeb
                    ? _buildWebLayout(context)
                    : _buildMobileLayout(context),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isEditing ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primaryDark,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isEditing ? "Edit Site" : nameController.text,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        if (isEditing)
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check, color: AppColors.success),
              ),
              onPressed: _updateSite,
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _updateSite,
      label: const Text("Save Changes"),
      icon: const Icon(Icons.save_rounded),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SiteDetailsHeader(
                nameController: nameController,
                isEditing: isEditing,
                isActive: isActive,
                onEditToggle: () => setState(() => isEditing = !isEditing),
                onActiveToggle: (val) => setState(() => isActive = val),
              ),
              const SizedBox(height: 24),
              SiteDetailsLocationCard(
                isEditing: isEditing,
                adresseController: adresseController,
                geofenceRadiusController: geofenceRadiusController,
                geofenceLatController: geofenceLatController,
                geofenceLngController: geofenceLngController,
              ),
              const SizedBox(height: 20),
              SiteDetailsDatesCard(
                isEditing: isEditing,
                startDate: startDate,
                endDate: endDate,
                onStartDateChanged: (date) => setState(() => startDate = date),
                onEndDateChanged: (date) => setState(() => endDate = date),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SiteDetailsProjectInfoCard(
                isEditing: isEditing,
                budgetController: budgetController,
              ),
              const SizedBox(height: 20),
              SiteDetailsPeopleCard(
                isEditing: isEditing,
                ownerController: ownerController,
                managerController: managerController,
              ),
              if (isEditing) ...[
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SiteDetailsHeader(
          nameController: nameController,
          isEditing: isEditing,
          isActive: isActive,
          onEditToggle: () => setState(() => isEditing = !isEditing),
          onActiveToggle: (val) => setState(() => isActive = val),
        ),
        const SizedBox(height: 24),
        SiteDetailsLocationCard(
          isEditing: isEditing,
          adresseController: adresseController,
          geofenceRadiusController: geofenceRadiusController,
          geofenceLatController: geofenceLatController,
          geofenceLngController: geofenceLngController,
        ),
        const SizedBox(height: 20),
        SiteDetailsDatesCard(
          isEditing: isEditing,
          startDate: startDate,
          endDate: endDate,
          onStartDateChanged: (date) => setState(() => startDate = date),
          onEndDateChanged: (date) => setState(() => endDate = date),
        ),
        const SizedBox(height: 20),
        SiteDetailsProjectInfoCard(
          isEditing: isEditing,
          budgetController: budgetController,
        ),
        const SizedBox(height: 20),
        SiteDetailsPeopleCard(
          isEditing: isEditing,
          ownerController: ownerController,
          managerController: managerController,
        ),
        if (isEditing) ...[
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: const Text("Save"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _updateSite,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.close_rounded),
            label: const Text("Cancel"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.error.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => setState(() => isEditing = false),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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