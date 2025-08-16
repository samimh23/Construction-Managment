import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Core/Constants/api_constants.dart';
import '../../Widget/Details/ProjectInfo.dart';
import '../../Widget/Details/WorkersCard.dart';
import '../../Widget/Details/dateCard.dart';
import '../../Widget/Details/header.dart';
import '../../Widget/Details/locationInfo.dart';

import '../../Widget/Sites/SiteMap.dart';
import 'Home.dart';

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
      duration: const Duration(milliseconds: 800),
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = await authService.getCurrentUser();
    final endpoint = '${ApiConstants.UpdateConstructionsite}${widget.site.id}';

    final updatedSite = {
      "name": nameController.text,
      "adresse": adresseController.text,
      "Budget": budgetController.text.isNotEmpty ? budgetController.text : null,
      "owner": currentUser,
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

  Future<void> _deleteSite() async {
    if (widget.site.id == null || widget.site.id!.isEmpty) {
      _showSnackBar("Site ID is missing! Cannot delete.", isError: true);
      return;
    }
    final endpoint = '${ApiConstants.DeleteConstructionsite}${widget.site.id}';

    try {
      final response = await dio.delete(endpoint);

      if (response.statusCode == ApiConstants.statusOk ||
          response.statusCode == ApiConstants.statusNoContent) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete_forever, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Site deleted successfully!")),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        _showSnackBar("Failed to delete site", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error occurred", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool isWebLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  String _getStatusText() {
    if (isActive == true) return 'Active';
    if (isActive == false) return 'Inactive';
    return 'Unknown';
  }

  Color _getStatusColor() {
    if (isActive == true) return const Color(0xFF10B981);
    if (isActive == false) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  int _getProjectProgress() {
    if (startDate == null || endDate == null) return 0;
    final now = DateTime.now();
    final total = endDate!.difference(startDate!).inDays;
    final elapsed = now.difference(startDate!).inDays;
    if (elapsed <= 0) return 0;
    if (elapsed >= total) return 100;
    return ((elapsed / total) * 100).round();
  }

  void _goToMapTab(BuildContext context) {
    final double? lat = double.tryParse(geofenceLatController.text);
    final double? lng = double.tryParse(geofenceLngController.text);

    LatLng? initialCenter;
    if (lat != null && lng != null) {
      initialCenter = LatLng(lat, lng);
    } else if (widget.site.latitude != null && widget.site.longitude != null) {
      initialCenter = LatLng(widget.site.latitude!, widget.site.longitude!);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          mapInitialCenter: initialCenter,
          mapInitialZoom: 17,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isWeb ? 120 : 160,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E3A8A),
                          Color(0xFF3B82F6),
                          Color(0xFF06B6D4),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GeometricPatternPainter(),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 20,
                          right: 20,
                          child: isWeb ? _buildWebHeaderContent() : _buildMobileHeaderContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: isWeb ? _buildWebContent(context) : _buildMobileContent(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FutureBuilder(
        future: Provider.of<AuthService>(context, listen: false).getCurrentUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final isOwner = user != null && user.id == widget.site.owner;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'editBtn',
                backgroundColor: isEditing ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                onPressed: () => setState(() => isEditing = !isEditing),
                child: Icon(isEditing ? Icons.close_rounded : Icons.edit_rounded, color: Colors.white),
                tooltip: isEditing ? "Cancel" : "Edit Site",
              ),
              const SizedBox(height: 12),
              if (isOwner)
                FloatingActionButton(
                  heroTag: 'deleteBtn',
                  backgroundColor: const Color(0xFFEF4444),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Site'),
                        content: const Text('Are you sure you want to delete this site?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm ?? false) {
                      await _deleteSite();
                    }
                  },
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                  tooltip: "Delete Site",
                ),
              if (isEditing) ...[
                const SizedBox(height: 24),
                _buildModernFAB(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildWebHeaderContent() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  isEditing ? 'Edit Site' : nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  isEditing ? 'Modify construction site details' : 'Construction site overview',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              children: [
                Expanded(
                  child: _buildWebStatCard('Status', _getStatusText(), Icons.info_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWebStatCard('Progress', '${_getProjectProgress()}%', Icons.trending_up_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            isEditing ? 'Edit Site' : nameController.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            isEditing ? 'Modify construction site details' : 'Construction site overview',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              Expanded(
                child: _buildMobileStatCard('Status', _getStatusText(), Icons.info_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileStatCard('Progress', '${_getProjectProgress()}%', Icons.trending_up_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildCard(
                title: 'Site Information',
                icon: Icons.location_city_rounded,
                child: SiteDetailsHeader(
                  nameController: nameController,
                  isEditing: isEditing,
                  isActive: isActive,
                  onEditToggle: () => setState(() => isEditing = !isEditing),
                  onActiveToggle: (val) => setState(() => isActive = val),
                ),
                isWeb: true,
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Location & Geofence',
                icon: Icons.location_on_rounded,
                child: SiteDetailsLocationCard(
                  isEditing: isEditing,
                  adresseController: adresseController,
                  geofenceRadiusController: geofenceRadiusController,
                  geofenceLatController: geofenceLatController,
                  geofenceLngController: geofenceLngController,
                  onGoToMap: (lat, lng) {
                    _goToMapTab(context);
                  },
                ),
                isWeb: true,
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Project Timeline',
                icon: Icons.schedule_rounded,
                child: SiteDetailsDatesCard(
                  isEditing: isEditing,
                  startDate: startDate,
                  endDate: endDate,
                  onStartDateChanged: (date) => setState(() => startDate = date),
                  onEndDateChanged: (date) => setState(() => endDate = date),
                ),
                isWeb: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildCard(
                title: 'Project Details',
                icon: Icons.account_balance_wallet_rounded,
                child: SiteDetailsProjectInfoCard(
                  isEditing: isEditing,
                  budgetController: budgetController,
                ),
                isWeb: true,
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Management Team',
                icon: Icons.supervisor_account_rounded,
                child: SiteDetailsPeopleCard(
                  isEditing: isEditing,
                  managerController: managerController,
                  siteId: widget.site.id ?? '',
                  managerId: widget.site.manager,
                ),
                isWeb: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCard(
          title: 'Site Information',
          icon: Icons.location_city_rounded,
          child: SiteDetailsHeader(
            nameController: nameController,
            isEditing: isEditing,
            isActive: isActive,
            onEditToggle: () => setState(() => isEditing = !isEditing),
            onActiveToggle: (val) => setState(() => isActive = val),
          ),
          isWeb: false,
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Location & Geofence',
          icon: Icons.location_on_rounded,
          child: SiteDetailsLocationCard(
            isEditing: isEditing,
            adresseController: adresseController,
            geofenceRadiusController: geofenceRadiusController,
            geofenceLatController: geofenceLatController,
            geofenceLngController: geofenceLngController,
            onGoToMap: (lat, lng) {
              _goToMapTab(context);
            },
          ),
          isWeb: false,
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Project Timeline',
          icon: Icons.schedule_rounded,
          child: SiteDetailsDatesCard(
            isEditing: isEditing,
            startDate: startDate,
            endDate: endDate,
            onStartDateChanged: (date) => setState(() => startDate = date),
            onEndDateChanged: (date) => setState(() => endDate = date),
          ),
          isWeb: false,
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Project Details',
          icon: Icons.account_balance_wallet_rounded,
          child: SiteDetailsProjectInfoCard(
            isEditing: isEditing,
            budgetController: budgetController,
          ),
          isWeb: false,
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Management Team',
          icon: Icons.supervisor_account_rounded,
          child: SiteDetailsPeopleCard(
            isEditing: isEditing,
            managerController: managerController,
            siteId: widget.site.id,
            managerId: widget.site.manager,
          ),
          isWeb: false,
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildWebStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isWeb,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? 16 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isWeb ? 12 : 16),
                topRight: Radius.circular(isWeb ? 12 : 16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isWeb ? 6 : 8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3B82F6),
                    size: isWeb ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isWeb ? 16 : 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          onPressed: _updateSite,
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.save_rounded),
          label: const Text(
            'Save Changes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: () => setState(() => isEditing = false),
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.close_rounded),
          label: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
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
    managerController.dispose();
    geofenceRadiusController.dispose();
    geofenceLatController.dispose();
    geofenceLngController.dispose();
    super.dispose();
  }
}

// Custom painter for geometric pattern
class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const spacing = 60.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 30, 30),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}