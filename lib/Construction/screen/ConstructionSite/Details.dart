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

    final endpoint = '${ApiConstants.UpdateConstructionsite}${widget.site.id}';

    final updatedSite = {
      "name": nameController.text,
      "adresse": adresseController.text,
      "Budget": budgetController.text.isNotEmpty ? budgetController.text : null,
      "owner": "AyariAladine", // Set as current user
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

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Compact SliverAppBar - FIXED HEIGHT
          SliverAppBar(
            expandedHeight: isWeb ? 120 : 160, // ✅ Much smaller heights
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
                    // Simple pattern using CustomPaint
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GeometricPatternPainter(),
                      ),
                    ),
                    // Content that adapts to screen size
                    Positioned(
                      bottom: 16, // Reduced bottom padding
                      left: 20,
                      right: 20,
                      child: isWeb ? _buildWebHeaderContent() : _buildMobileHeaderContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content that adapts to screen size
          SliverPadding(
            padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: isWeb ? _buildWebContent() : _buildMobileContent(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isEditing ? _buildModernFAB() : null,
    );
  }

  // Web header content - horizontal layout with only Status and Progress
  Widget _buildWebHeaderContent() {
    return Row(
      children: [
        // Left side - Title and subtitle
        Expanded(
          flex: 3, // More space for title
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ Use minimum space
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  isEditing ? 'Edit Site' : nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // ✅ Smaller font size
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4), // ✅ Reduced spacing
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  isEditing ? 'Modify construction site details' : 'Construction site overview',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12, // ✅ Smaller font size
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24), // ✅ Reduced spacing
        // Right side - Only Status and Progress (removed Budget and Radius)
        Expanded(
          flex: 2, // ✅ Reduced flex for smaller stat section
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

  // Mobile header content - vertical layout with only Status and Progress
  Widget _buildMobileHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ Use minimum space
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            isEditing ? 'Edit Site' : nameController.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22, // ✅ Reduced font size
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4), // ✅ Reduced spacing
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            isEditing ? 'Modify construction site details' : 'Construction site overview',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12, // ✅ Smaller font size
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12), // ✅ Reduced spacing
        // Only Status and Progress in mobile (removed Budget and Radius)
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

  // Web content - two column layout
  Widget _buildWebContent() {
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

  // Mobile content - single column layout
  Widget _buildMobileContent() {
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
            siteId: widget.site.id ?? '',
            managerId: widget.site.manager,
          ),
          isWeb: false,
        ),
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  // Web stat card - compact and simplified
  Widget _buildWebStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ More compact padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row( // ✅ Changed to Row layout for more compact design
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 14), // ✅ Smaller icon
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
                    fontSize: 12, // ✅ Smaller font
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10, // ✅ Smaller font
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

  // Mobile stat card - compact and simplified
  Widget _buildMobileStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // ✅ More compact padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row( // ✅ Changed to Row layout for more compact design
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16), // ✅ Smaller icon
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
                    fontSize: 12, // ✅ Smaller font
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10, // ✅ Smaller font
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

  // Universal card builder that adapts to web/mobile
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
          // Card header
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
                // Add edit button only for Site Information card
                if (title == 'Site Information')
                  Container(
                    decoration: BoxDecoration(
                      color: isEditing
                          ? const Color(0xFFEF4444).withOpacity(0.1)
                          : const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isWeb ? 6 : 8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        color: isEditing ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                        size: isWeb ? 18 : 20,
                      ),
                      onPressed: () => setState(() => isEditing = !isEditing),
                      tooltip: isEditing ? "Cancel" : "Edit Site",
                    ),
                  ),
              ],
            ),
          ),
          // Card content
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
        // Draw small rectangles
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