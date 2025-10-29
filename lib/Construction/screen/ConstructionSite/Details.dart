import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

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
  // Dashboard Color Palette (matching your dashboard exactly)
  static const Color _primaryBlue = Color(0xFF4285F4);
  static const Color _successGreen = Color(0xFF34A853);
  static const Color _warningRed = Color(0xFFEA4335);
  static const Color _warningOrange = Color(0xFFFBBC04);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _borderGray = Color(0xFFE8EAED);
  static const Color _textGray = Color(0xFF5F6368);
  static const Color _darkText = Color(0xFF202124);
  static const Color _cardWhite = Colors.white;

  bool isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late TextEditingController nameController;
  late TextEditingController adresseController;
  late TextEditingController budgetController;
  late TextEditingController managerController;
  late TextEditingController geofenceRadiusController;
  late TextEditingController geofenceLatController;
  late TextEditingController geofenceLngController;
  late TextEditingController siteLatController;
  late TextEditingController siteLngController;
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    siteLatController = TextEditingController(text: site.latitude?.toString() ?? "");
    siteLngController = TextEditingController(text: site.longitude?.toString() ?? "");
    startDate = site.startDate;
    endDate = site.endDate;
    isActive = site.isActive;
  }

  // FIXED: Get proper owner string instead of object
  String _getOwnerString(dynamic user) {
    if (user == null) return 'AyariAladine'; // Fallback

    // If it's already a string, return it
    if (user is String) return user;

    // If it's a user object, extract the right field
    if (user is Map) {
      // Try different possible ID fields
      return user['id']?.toString() ??
          user['_id']?.toString() ??
          user['uid']?.toString() ??
          user['email']?.toString() ??
          user['username']?.toString() ??
          'AyariAladine';
    }

    // If it has an id property
    try {
      return user.id?.toString() ??
          user.uid?.toString() ??
          user.email?.toString() ??
          user.username?.toString() ??
          'AyariAladine';
    } catch (e) {
      // Fallback if user object doesn't have expected properties
      return 'AyariAladine';
    }
  }

  Future<void> _updateSite() async {
    if (widget.site.id == null || widget.site.id!.isEmpty) {
      _showSnackBar("Site ID is missing! Cannot update.", isError: true);
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = await authService.getCurrentUser();
    final endpoint = '${ApiConstants.UpdateConstructionsite}${widget.site.id}';

    // FIXED: Get owner as string, not object
    final ownerString = _getOwnerString(currentUser);

    if (kDebugMode) {
      print('🔍 DEBUG: Update site - Current user: $currentUser');
      print('🔍 DEBUG: Update site - Owner string: $ownerString');
      print('🔍 DEBUG: Update site - Original owner: ${widget.site.owner}');
    }

    final updatedSite = {
      "name": nameController.text,
      "adresse": adresseController.text,
      "Budget": budgetController.text.isNotEmpty ? budgetController.text : null,
      "owner": ownerString, // ✅ FIXED: Send string, not object
      "manager": managerController.text,
      "GeoLocation": {
        "longitude": siteLngController.text,
        "Latitude": siteLatController.text
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

    if (kDebugMode) {
      print('🔍 DEBUG: Update payload: $updatedSite');
    }

    try {
      final response = await dio.patch(endpoint, data: updatedSite);

      if (response.statusCode == ApiConstants.statusOk ||
          response.statusCode == ApiConstants.statusCreated) {
        final updatedData = response.data;

        if (kDebugMode) {
          print('✅ DEBUG: Update response: $updatedData');
        }

        setState(() {
          isEditing = false;
          nameController.text = updatedData['name'] ?? nameController.text;
          adresseController.text = updatedData['adresse'] ?? adresseController.text;
          budgetController.text = updatedData['Budget']?.toString() ?? '';
          managerController.text = updatedData['manager'] ?? managerController.text;
          geofenceRadiusController.text = updatedData['GeoFence']?['radius']?.toString() ?? '';
          geofenceLatController.text = updatedData['GeoFence']?['center']?['Latitude']?.toString() ?? '';
          geofenceLngController.text = updatedData['GeoFence']?['center']?['longitude']?.toString() ?? '';
          siteLatController.text = updatedData['GeoLocation']?['Latitude']?.toString() ?? siteLatController.text;
          siteLngController.text = updatedData['GeoLocation']?['longitude']?.toString() ?? siteLngController.text;
          startDate = updatedData['StartDate'] != null ? DateTime.tryParse(updatedData['StartDate']) : null;
          endDate = updatedData['EndDate'] != null ? DateTime.tryParse(updatedData['EndDate']) : null;
          isActive = updatedData['isActive'] ?? isActive;
        });
        _showSnackBar("Site updated successfully!", isError: false);
      } else {
        _showSnackBar("Failed to update site", isError: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DEBUG: Update error: $e');
      }
      _showSnackBar("Network error occurred: $e", isError: true);
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
              content: const Text("Site deleted successfully!"),
              backgroundColor: _successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        content: Text(message),
        backgroundColor: isError ? _warningRed : _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool isWebLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);

    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        backgroundColor: _cardWhite,
        elevation: 0,
        title: Text(
          'Site Details',
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Modern action buttons in header (NO DATE DISPLAY)
          if (isEditing) ...[
            // Save button
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _updateSite,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _successGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            // Cancel button
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: TextButton.icon(
                onPressed: () => setState(() => isEditing = false),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: _textGray,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Edit button
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => isEditing = true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            // Delete button
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: IconButton(
                onPressed: _showDeleteDialog,
                icon: const Icon(Icons.delete_outline),
                color: _warningRed,
                tooltip: 'Delete Site',
              ),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _borderGray,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
          child: Column(
            children: [
              // Header metrics section
              _buildHeaderMetrics(),
              const SizedBox(height: 24),

              // Content cards
              if (isWeb)
                _buildWebContent(context)
              else
                _buildMobileContent(context),
            ],
          ),
        ),
      ),
      // REMOVED: No floating action button
    );
  }

  Widget _buildHeaderMetrics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.domain,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameController.text.isNotEmpty ? nameController.text : 'Untitled Site',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive == true ? _successGreen : _warningRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive == true ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: _textGray,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _warningOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: _warningOrange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Editing',
                        style: TextStyle(
                          color: _warningOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Metrics row (like dashboard cards)
          _buildMetricsRow(),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final progress = _getProjectProgress();
    final budget = budgetController.text;
    final status = isActive == true ? 'Active' : 'Inactive';

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.trending_up,
            title: 'Progress',
            value: '$progress%',
            change: progress > 50 ? '+${progress - 50}%' : null,
            isPositive: progress > 50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.account_balance_wallet,
            title: 'Budget',
            value: _formatBudgetValue(budget),
            change: null,
            isPositive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.info_outline,
            title: 'Status',
            value: status,
            change: null,
            isPositive: isActive == true,
          ),
        ),
      ],
    );
  }

  // ADDED: Helper method to format budget values properly
  String _formatBudgetValue(String budget) {
    if (budget.isEmpty) return '0';

    final value = double.tryParse(budget) ?? 0;

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  // FIXED: Improved metric card with better text overflow handling
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    String? change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ADDED: Prevent expansion
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPositive ? _successGreen : _warningRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 14, // Reduced icon size
                ),
              ),
              if (change != null) ...[
                const Spacer(),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 10, // Reduced font size
                    fontWeight: FontWeight.w500,
                    color: isPositive ? _successGreen : _warningRed,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // FIXED: Better text handling with overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20, // Reduced from 24
                fontWeight: FontWeight.w500,
                color: _darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Text(
            title,
            style: TextStyle(
              fontSize: 12, // Reduced from 14
              color: _textGray,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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

  Widget _buildWebContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildDashboardCard(
                'Site Information',
                Icons.domain,
                SiteDetailsHeader(
                  nameController: nameController,
                  isEditing: isEditing,
                  isActive: isActive,
                  onEditToggle: () => setState(() => isEditing = !isEditing),
                  onActiveToggle: (val) => setState(() => isActive = val),
                ),
              ),
              const SizedBox(height: 16),
              _buildDashboardCard(
                'Location & Geofence',
                Icons.location_on,
                SiteDetailsLocationCard(
                  isEditing: isEditing,
                  adresseController: adresseController,
                  geofenceRadiusController: geofenceRadiusController,
                  siteLatController: siteLatController,
                  siteLngController: siteLngController,
                  onGoToMap: (lat, lng) => _goToMapTab(context),
                ),
              ),
              const SizedBox(height: 16),
              _buildDashboardCard(
                'Project Timeline',
                Icons.schedule,
                SiteDetailsDatesCard(
                  isEditing: isEditing,
                  startDate: startDate,
                  endDate: endDate,
                  onStartDateChanged: (date) => setState(() => startDate = date),
                  onEndDateChanged: (date) => setState(() => endDate = date),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildDashboardCard(
                'Project Budget',
                Icons.account_balance_wallet,
                SiteDetailsProjectInfoCard(
                  isEditing: isEditing,
                  budgetController: budgetController,
                ),
              ),
              const SizedBox(height: 16),
              _buildDashboardCard(
                'Management Team',
                Icons.supervisor_account,
                SiteDetailsPeopleCard(
                  isEditing: isEditing,
                  managerController: managerController,
                  siteId: widget.site.id ?? '',
                  managerId: widget.site.manager,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      children: [
        _buildDashboardCard(
          'Site Information',
          Icons.domain,
          SiteDetailsHeader(
            nameController: nameController,
            isEditing: isEditing,
            isActive: isActive,
            onEditToggle: () => setState(() => isEditing = !isEditing),
            onActiveToggle: (val) => setState(() => isActive = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          'Location & Geofence',
          Icons.location_on,
          SiteDetailsLocationCard(
            isEditing: isEditing,
            adresseController: adresseController,
            geofenceRadiusController: geofenceRadiusController,
            siteLatController: siteLatController,
            siteLngController: siteLngController,
            onGoToMap: (lat, lng) => _goToMapTab(context),
          ),
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          'Project Timeline',
          Icons.schedule,
          SiteDetailsDatesCard(
            isEditing: isEditing,
            startDate: startDate,
            endDate: endDate,
            onStartDateChanged: (date) => setState(() => startDate = date),
            onEndDateChanged: (date) => setState(() => endDate = date),
          ),
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          'Project Budget',
          Icons.account_balance_wallet,
          SiteDetailsProjectInfoCard(
            isEditing: isEditing,
            budgetController: budgetController,
          ),
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          'Management Team',
          Icons.supervisor_account,
          SiteDetailsPeopleCard(
            isEditing: isEditing,
            managerController: managerController,
            siteId: widget.site.id,
            managerId: widget.site.manager,
          ),
        ),
        const SizedBox(height: 24), // REDUCED: Less space at bottom since no floating button
      ],
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lightGray,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: _borderGray),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _textGray, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _darkText,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _warningRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_rounded, color: _warningRed, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Site'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this site? This action cannot be undone and will remove all associated data.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: _textGray,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _warningRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Delete Site'),
          ),
        ],
      ),
    );
    if (confirm ?? false) {
      await _deleteSite();
    }
  }

  void _goToMapTab(BuildContext context) {
    final double? lat = double.tryParse(siteLatController.text);
    final double? lng = double.tryParse(siteLngController.text);

    LatLng? initialCenter;
    if (lat != null && lng != null) {
      initialCenter = LatLng(lat, lng);
    } else if (widget.site.latitude != null && widget.site.longitude != null) {
      initialCenter = LatLng(widget.site.latitude!, widget.site.longitude!);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          initialTabIndex: 2,
          mapInitialCenter: initialCenter,
          mapInitialZoom: 17,
        ),
      ),
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
    siteLatController.dispose();
    siteLngController.dispose();
    super.dispose();
  }
}