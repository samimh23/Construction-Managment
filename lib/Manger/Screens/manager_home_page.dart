import 'dart:convert';
import 'dart:math';
import 'package:constructionproject/Construction/Core/Constants/api_constants.dart';
import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/services/auth/auth_service.dart';

// Utility function for geofence check
bool isOutOfGeofence({
  required double userLat,
  required double userLng,
  required double siteLat,
  required double siteLng,
  required double radiusInMeters,
}) {
  double distance = _calculateDistance(userLat, userLng, siteLat, siteLng);
  return distance > radiusInMeters;
}

double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  // Haversine formula
  const double earthRadius = 6371000; // meters
  double dLat = _deg2rad(lat2 - lat1);
  double dLng = _deg2rad(lng2 - lng1);
  double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _deg2rad(double deg) => deg * (pi / 180.0);

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final _codeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _locationStarted = false;
  String? ownerId;
  // For storing manager location
  double? managerLat;
  double? managerLng;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      if (attendanceProvider.error != null) {
        attendanceProvider.clearError();
      }
    });
    Future.microtask(() async {
      await context.read<ManagerDataProvider>().loadSiteAndWorkers();
      final siteId = context.read<ManagerDataProvider>().site?.id;
      if (siteId != null && siteId.isNotEmpty) {
        await context.read<AttendanceProvider>().fetchSiteDailyAttendance(
          siteId,
        );
      }
      await _fetchManagerAndStoreOwnerId();
      await _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          managerLat = position.latitude;
          managerLng = position.longitude;
        });
      }
    } catch (e) {
      // Could not get location
    }
  }

  Future<void> _fetchManagerAndStoreOwnerId() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();
      final managerId = currentUser?.id ?? "unknown";
      final url = Uri.parse('${ApiConstants.baseUrl}users/$managerId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fetchedOwnerId = data['createdBy']?.toString();
        if (mounted) {
          setState(() {
            ownerId = fetchedOwnerId;
          });
        }
        await _startLocationTracking(ownerId: fetchedOwnerId);
      } else {
        if (mounted)
          setState(() {
            ownerId = null;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          ownerId = null;
        });
    }
  }

  Future<void> _startLocationTracking({required String? ownerId}) async {
    if (_locationStarted || ownerId == null) return;
    _locationStarted = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showErrorSnackBar(
            'Location permission required for attendance tracking',
          );
        }
        return;
      }
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();
      final managerId = currentUser?.id ?? "unknown";
      final managerProvider = context.read<ManagerDataProvider>();
      final site = managerProvider.site;
      final siteId = site != null ? site.id : "unknown";
      final locationProvider = Provider.of<ManagerLocationProvider>(
        context,
        listen: false,
      );
      locationProvider.connectAsManager(managerId, siteId, ownerId);
      locationProvider.onConnected(() {
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          locationProvider.sendLocation(
            managerId: managerId,
            siteId: siteId,
            latitude: position.latitude,
            longitude: position.longitude,
            ownerId: ownerId,
          );
          if (mounted) {
            setState(() {
              managerLat = position.latitude;
              managerLng = position.longitude;
            });
          }
        });
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<String?> pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      return picked?.path;
    } catch (e) {
      if (mounted)
        _showErrorSnackBar('Camera access failed. Please try again.');
      return null;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    Provider.of<ManagerLocationProvider>(context, listen: false).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managerProvider = Provider.of<ManagerDataProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    // Geofence check logic
    bool outOfGeofence = false;
    final site = managerProvider.site;
    if (site != null &&
        site.geofenceRadius != null &&
        managerLat != null &&
        managerLng != null) {
      outOfGeofence = isOutOfGeofence(
        userLat: managerLat!,
        userLng: managerLng!,
        siteLat: site.latitude,
        siteLng: site.longitude,
        radiusInMeters: site.geofenceRadius!.toDouble(),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(outOfGeofence),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: () async {
          await context.read<ManagerDataProvider>().loadSiteAndWorkers();
          await _getCurrentLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Gradient header with site summary
              _buildGradientHeader(
                managerProvider,
                attendanceProvider,
                outOfGeofence,
              ),
              // Geofence warning banner
              if (outOfGeofence) _buildGeofenceWarning(),
              // Main content with proper spacing
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildQuickStatsRow(attendanceProvider, managerProvider),
                    const SizedBox(height: 16),
                    _buildAttendanceCard(
                      attendanceProvider,
                      managerProvider,
                      outOfGeofence,
                    ),
                    const SizedBox(height: 16),
                    _buildSiteInfoCard(managerProvider),
                    const SizedBox(height: 16),
                    _buildWorkersCard(managerProvider, attendanceProvider),
                    const SizedBox(height: 20), // Extra bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool outOfGeofence) {
    return AppBar(
      title: const Text(
        'Site Manager',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                outOfGeofence
                    ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                    : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          ),
        ),
      ),
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  Widget _buildGradientHeader(
    ManagerDataProvider managerProvider,
    AttendanceProvider attendanceProvider,
    bool outOfGeofence,
  ) {
    final site = managerProvider.site;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              outOfGeofence
                  ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                  : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  outOfGeofence ? Icons.location_off : Icons.location_city,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site?.name ?? 'No Site Assigned',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          outOfGeofence
                              ? Icons.warning_amber
                              : Icons.check_circle,
                          color: Colors.white.withOpacity(0.9),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            outOfGeofence
                                ? 'Out of geofence area'
                                : site?.adresse ?? 'Address not available',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(
    AttendanceProvider attendanceProvider,
    ManagerDataProvider managerProvider,
  ) {
    final attendanceData = attendanceProvider.siteDailyAttendance;
    final presentCount =
        (attendanceData?['present'] as List<dynamic>?)?.length ?? 0;
    final absentCount =
        (attendanceData?['absent'] as List<dynamic>?)?.length ?? 0;
    final totalWorkers = managerProvider.workers.length;
    // Ensure pending count is never negative
    final pendingCount = (totalWorkers - (presentCount + absentCount)).clamp(
      0,
      totalWorkers,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            label: 'Present',
            value: '$presentCount',
            color: const Color(0xFF059669),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.cancel,
            label: 'Absent',
            value: '$absentCount',
            color: const Color(0xFFDC2626),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            label: 'Pending',
            value: '$pendingCount',
            color: const Color(0xFFF59E0B),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required LinearGradient gradient,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeofenceWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFEE2E2),
        border: Border(bottom: BorderSide(color: Color(0xFFFECACA), width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outside Geofence Area',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Check-in/check-out functions are disabled',
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    AttendanceProvider attendanceProvider,
    ManagerDataProvider managerProvider,
    bool outOfGeofence,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.how_to_reg,
              title: 'Worker Attendance',
              color: const Color(0xFF059669),
            ),
            const SizedBox(height: 24),
            // Worker code input
            Container(
              decoration: BoxDecoration(
                color: outOfGeofence ? const Color(0xFFF9FAFB) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      outOfGeofence
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _codeController,
                enabled: !outOfGeofence,
                decoration: InputDecoration(
                  labelText: "Worker Code",
                  labelStyle: TextStyle(
                    color:
                        outOfGeofence ? Colors.grey : const Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: "Enter worker code or scan QR",
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  prefixIcon: Icon(
                    Icons.qr_code_scanner,
                    color:
                        outOfGeofence ? Colors.grey : const Color(0xFF6366F1),
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            if (attendanceProvider.error != null) ...[
              const SizedBox(height: 12),
              _buildErrorMessage(attendanceProvider.error!),
            ],
            const SizedBox(height: 20),
            // Action buttons
            _buildActionButtons(
              attendanceProvider,
              managerProvider,
              outOfGeofence,
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            const SizedBox(height: 24),
            // Face recognition section
            _buildFaceRecognitionSection(
              attendanceProvider,
              managerProvider,
              outOfGeofence,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    AttendanceProvider attendanceProvider,
    ManagerDataProvider managerProvider,
    bool outOfGeofence,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildPrimaryButton(
            label: 'Check In',
            icon: Icons.login,
            color: const Color(0xFF059669),
            isLoading: attendanceProvider.isLoading,
            isEnabled: !outOfGeofence,
            onPressed:
                () => _handleCheckIn(attendanceProvider, managerProvider),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPrimaryButton(
            label: 'Check Out',
            icon: Icons.logout,
            color: const Color(0xFFEA580C),
            isLoading: attendanceProvider.isLoading,
            isEnabled: !outOfGeofence,
            onPressed:
                () => _handleCheckOut(attendanceProvider, managerProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildFaceRecognitionSection(
    AttendanceProvider attendanceProvider,
    ManagerDataProvider managerProvider,
    bool outOfGeofence,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.face_retouching_natural,
                color: const Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Face Recognition',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Register face button
          SizedBox(
            width: double.infinity,
            child: _buildSecondaryButton(
              label: 'Register Worker Face',
              icon: Icons.face_retouching_natural,
              color: const Color(0xFF7C3AED),
              isLoading: attendanceProvider.isLoading,
              isEnabled: !outOfGeofence,
              onPressed: () => _handleRegisterFace(attendanceProvider),
            ),
          ),
          const SizedBox(height: 12),
          // Face check-in/out buttons
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  label: 'Face Check In',
                  icon: Icons.camera_alt,
                  color: const Color(0xFF059669),
                  isLoading: attendanceProvider.isLoading,
                  isEnabled: !outOfGeofence,
                  onPressed:
                      () => _handleFaceCheckIn(
                        attendanceProvider,
                        managerProvider,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  label: 'Face Check Out',
                  icon: Icons.camera_alt_outlined,
                  color: const Color(0xFFEA580C),
                  isLoading: attendanceProvider.isLoading,
                  isEnabled: !outOfGeofence,
                  onPressed: () => _handleFaceCheckOut(attendanceProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSiteInfoCard(ManagerDataProvider managerProvider) {
    if (managerProvider.isLoading) {
      return _buildLoadingCard();
    }
    if (managerProvider.error != null) {
      return _buildErrorCard('Error loading site info', managerProvider.error!);
    }
    if (managerProvider.site == null) {
      return _buildEmptyCard(
        icon: Icons.location_off,
        title: 'No Site Assigned',
        subtitle: 'Contact your administrator to assign a construction site.',
      );
    }
    final site = managerProvider.site!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.location_city,
              title: 'Site Information',
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 20),
            // Site name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              site.adresse,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          site.isActive
                              ? [
                                const Color(0xFFD1FAE5),
                                const Color(0xFFA7F3D0),
                              ]
                              : [
                                const Color(0xFFFEE2E2),
                                const Color(0xFFFECACA),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (site.isActive
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626))
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    site.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color:
                          site.isActive
                              ? const Color(0xFF065F46)
                              : const Color(0xFF991B1B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Site details grid with gradient background
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0284C7).withOpacity(0.05),
                    const Color(0xFF0284C7).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0284C7).withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.my_location,
                          label: 'Coordinates',
                          value:
                              '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.radio_button_unchecked,
                          label: 'Geofence',
                          value: '${site.geofenceRadius ?? "N/A"}m',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.attach_money,
                          label: 'Budget',
                          value: site.budget ?? "Not set",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersCard(
    ManagerDataProvider managerProvider,
    AttendanceProvider attendanceProvider,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSectionHeader(
                    icon: Icons.group,
                    title: 'Workers',
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${managerProvider.workers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (managerProvider.workers.isEmpty)
              _buildEmptyState()
            else
              ...managerProvider.workers.map(
                (worker) => _buildWorkerItem(worker, attendanceProvider),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerItem(
    Map<String, dynamic> worker,
    AttendanceProvider attendanceProvider,
  ) {
    final isVerified = worker['faceRegistered'] == true;
    final firstName = worker['firstName']?.toString() ?? 'Unknown';
    final workerCode = worker['workerCode']?.toString() ?? '';

    // Get attendance status
    String attendanceStatus = 'Not recorded';
    Color attendanceColor = Colors.grey;
    IconData attendanceIcon = Icons.help_outline;
    String? checkInTime;

    final attendanceData = attendanceProvider.siteDailyAttendance;
    if (attendanceData != null) {
      final presentList = attendanceData['present'] as List<dynamic>? ?? [];
      final absentList = attendanceData['absent'] as List<dynamic>? ?? [];

      // Check if worker is present
      final presentWorker = presentList.firstWhere(
        (w) => w['workerCode'] == workerCode,
        orElse: () => null,
      );

      if (presentWorker != null) {
        attendanceStatus = 'Present';
        attendanceColor = const Color(0xFF059669);
        attendanceIcon = Icons.check_circle;
        checkInTime = presentWorker['checkInTime']?.toString();
      } else {
        // Check if worker is absent
        final absentWorker = absentList.firstWhere(
          (w) => w['workerCode'] == workerCode,
          orElse: () => null,
        );

        if (absentWorker != null) {
          attendanceStatus = 'Absent';
          attendanceColor = const Color(0xFFDC2626);
          attendanceIcon = Icons.cancel;
        }
      }
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      attendanceStatus == 'Present'
                          ? const Color(0xFF059669).withOpacity(0.2)
                          : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        attendanceStatus == 'Present'
                            ? const Color(0xFF059669).withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with gradient
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors:
                                attendanceStatus == 'Present'
                                    ? [
                                      const Color(0xFF059669),
                                      const Color(0xFF047857),
                                    ]
                                    : [
                                      const Color(0xFF6366F1),
                                      const Color(0xFF4F46E5),
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: (attendanceStatus == 'Present'
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF6366F1))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            firstName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Worker info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.badge,
                                  size: 14,
                                  color: const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workerCode.isNotEmpty
                                      ? workerCode
                                      : 'No code',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Face verification status with animation
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isVerified
                                    ? [
                                      const Color(0xFFD1FAE5),
                                      const Color(0xFFA7F3D0),
                                    ]
                                    : [
                                      const Color(0xFFFEF3C7),
                                      const Color(0xFFFDE68A),
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isVerified
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFF59E0B))
                                  .withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified ? Icons.verified : Icons.schedule,
                              size: 14,
                              color:
                                  isVerified
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF92400E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? 'Verified' : 'Pending',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    isVerified
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Attendance status with enhanced styling
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          attendanceColor.withOpacity(0.1),
                          attendanceColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: attendanceColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(attendanceIcon, size: 18, color: attendanceColor),
                        const SizedBox(width: 10),
                        Text(
                          attendanceStatus,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: attendanceColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        // Show check-in time if present
                        if (attendanceStatus == 'Present' &&
                            checkInTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: attendanceColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: attendanceColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  checkInTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: attendanceColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widgets
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isEnabled
                ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: ElevatedButton.icon(
        onPressed: (isLoading || !isEnabled) ? null : onPressed,
        icon:
            isLoading
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : const Color(0xFF9CA3AF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: (isLoading || !isEnabled) ? null : onPressed,
      icon:
          isLoading
              ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
              : Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: isEnabled ? color : const Color(0xFF9CA3AF),
        side: BorderSide(color: isEnabled ? color : const Color(0xFF9CA3AF)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title, String message) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF), size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.group_off, color: const Color(0xFF9CA3AF), size: 48),
          const SizedBox(height: 16),
          const Text(
            'No Workers Assigned',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Workers will appear here once they are assigned to this construction site.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _handleCheckIn(
    AttendanceProvider attendanceProvider,
    ManagerDataProvider managerProvider,
  ) async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackBar('Please enter a worker code');
      return;
    }
    final siteId = managerProvider.site?.id ?? '';
    if (siteId.isEmpty) {
      _showErrorSnackBar('No site assigned. Cannot check in.');
      return;
    }
    final success = await attendanceProvider.checkIn(code, siteId);
    if (success && mounted) {
      _codeController.clear();
      _showSuccessSnackBar('Worker checked in successfully!');
    }
  }

  Future<void> _handleCheckOut(
    AttendanceProvider attendanceProvider,
    ManagerDataProvider managerProvider,
  ) async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackBar('Please enter a worker code');
      return;
    }
    final siteId = managerProvider.site?.id ?? '';
    if (siteId.isEmpty) {
      _showErrorSnackBar('No site assigned. Cannot check out.');
      return;
    }
    final success = await attendanceProvider.checkOut(code, siteId);
    if (success && mounted) {
      _codeController.clear();
      _showSuccessSnackBar('Worker checked out successfully!');
    }
  }

  Future<void> _handleRegisterFace(
    AttendanceProvider attendanceProvider,
  ) async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackBar('Please enter worker code first');
      return;
    }
    final photoPath = await pickPhoto();
    if (photoPath != null) {
      final success = await attendanceProvider.registerFace(code, photoPath);
      if (success && mounted) {
        _showSuccessSnackBar('Face registered successfully!');
      }
    }
  }

  Future<void> _handleFaceCheckIn(
    AttendanceProvider attendanceProvider,
    ManagerDataProvider managerProvider,
  ) async {
    FocusScope.of(context).unfocus();
    final siteId = managerProvider.site?.id ?? '';
    final photoPath = await pickPhoto();
    if (photoPath != null) {
      final success = await attendanceProvider.checkInWithFace(
        photoPath,
        siteId,
      );
      if (success && mounted) {
        _showSuccessSnackBar('Face check-in successful!');
      }
    }
  }

  Future<void> _handleFaceCheckOut(
    AttendanceProvider attendanceProvider,
  ) async {
    FocusScope.of(context).unfocus();
    final photoPath = await pickPhoto();
    if (photoPath != null) {
      final success = await attendanceProvider.checkOutWithFace(photoPath);
      if (success && mounted) {
        _showSuccessSnackBar('Face check-out successful!');
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      // TODO: Navigate to login screen, replace with your routing logic
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      _showErrorSnackBar('Logout failed: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
