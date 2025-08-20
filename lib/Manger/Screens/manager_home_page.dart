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
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
          sin(dLng / 2) * sin(dLng / 2);
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
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      if (attendanceProvider.error != null) {
        attendanceProvider.clearError();
      }
    });

    Future.microtask(() async {
      await context.read<ManagerDataProvider>().loadSiteAndWorkers();
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
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
        if (mounted) setState(() { ownerId = null; });
      }
    } catch (e) {
      if (mounted) setState(() { ownerId = null; });
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
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showErrorSnackBar('Location permission required for attendance tracking');
        }
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();
      final managerId = currentUser?.id ?? "unknown";

      final managerProvider = context.read<ManagerDataProvider>();
      final site = managerProvider.site;
      final siteId = site != null ? site.id : "unknown";
      final locationProvider = Provider.of<ManagerLocationProvider>(context, listen: false);

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
      if (mounted) _showErrorSnackBar('Camera access failed. Please try again.');
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
    if (site != null && site.geofenceRadius != null && managerLat != null && managerLng != null) {
      outOfGeofence = isOutOfGeofence(
        userLat: managerLat!,
        userLng: managerLng!,
        siteLat: site.latitude,
        siteLng: site.longitude,
        radiusInMeters: site.geofenceRadius!.toDouble(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(outOfGeofence),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ManagerDataProvider>().loadSiteAndWorkers();
          await _getCurrentLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Geofence warning banner
              if (outOfGeofence) _buildGeofenceWarning(),

              // Main content with proper spacing
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildAttendanceCard(attendanceProvider, managerProvider, outOfGeofence),
                    const SizedBox(height: 16),
                    _buildSiteInfoCard(managerProvider),
                    const SizedBox(height: 16),
                    _buildWorkersCard(managerProvider),
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
      backgroundColor: outOfGeofence ? const Color(0xFFDC2626) : const Color(0xFF1E40AF),
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
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceProvider attendanceProvider, ManagerDataProvider managerProvider, bool outOfGeofence) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.how_to_reg,
              title: 'Worker Attendance',
              color: const Color(0xFF059669),
            ),
            const SizedBox(height: 20),

            // Worker code input
            TextField(
              controller: _codeController,
              enabled: !outOfGeofence,
              decoration: InputDecoration(
                labelText: "Worker Code",
                hintText: "Enter worker code or scan QR",
                prefixIcon: Icon(Icons.qr_code_scanner,
                    color: outOfGeofence ? Colors.grey : const Color(0xFF6366F1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                filled: true,
                fillColor: outOfGeofence ? const Color(0xFFF9FAFB) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            if (attendanceProvider.error != null) ...[
              const SizedBox(height: 12),
              _buildErrorMessage(attendanceProvider.error!),
            ],

            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(attendanceProvider, managerProvider, outOfGeofence),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 20),

            // Face recognition section
            _buildFaceRecognitionSection(attendanceProvider, managerProvider, outOfGeofence),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AttendanceProvider attendanceProvider, ManagerDataProvider managerProvider, bool outOfGeofence) {
    return Row(
      children: [
        Expanded(
          child: _buildPrimaryButton(
            label: 'Check In',
            icon: Icons.login,
            color: const Color(0xFF059669),
            isLoading: attendanceProvider.isLoading,
            isEnabled: !outOfGeofence,
            onPressed: () => _handleCheckIn(attendanceProvider),
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
            onPressed: () => _handleCheckOut(attendanceProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildFaceRecognitionSection(AttendanceProvider attendanceProvider, ManagerDataProvider managerProvider, bool outOfGeofence) {
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
              Icon(Icons.face_retouching_natural,
                  color: const Color(0xFF7C3AED), size: 20),
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
                  onPressed: () => _handleFaceCheckIn(attendanceProvider, managerProvider),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.location_city,
              title: 'Site Information',
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 16),

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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        site.adresse,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: site.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    site.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: site.isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Site details grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.my_location,
                          label: 'Coordinates',
                          value: '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
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

  Widget _buildWorkersCard(ManagerDataProvider managerProvider) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.group,
              title: 'Workers (${managerProvider.workers.length})',
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 16),

            if (managerProvider.workers.isEmpty)
              _buildEmptyState()
            else
              ...managerProvider.workers.map((worker) => _buildWorkerItem(worker)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerItem(Map<String, dynamic> worker) {
    final isVerified = worker['faceRegistered'] == true;
    final firstName = worker['firstName']?.toString() ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                firstName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Worker info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isVerified ? 'Face verified' : 'Face registration pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: isVerified ? const Color(0xFF059669) : const Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.schedule,
                  size: 12,
                  color: isVerified ? const Color(0xFF059669) : const Color(0xFF92400E),
                ),
                const SizedBox(width: 4),
                Text(
                  isVerified ? 'Verified' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isVerified ? const Color(0xFF059669) : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
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
    return ElevatedButton.icon(
      onPressed: (isLoading || !isEnabled) ? null : onPressed,
      icon: isLoading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : const Color(0xFF9CA3AF),
        foregroundColor: Colors.white,
        elevation: isEnabled ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
      icon: isLoading
          ? SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      )
          : Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: isEnabled ? color : const Color(0xFF9CA3AF),
        side: BorderSide(
          color: isEnabled ? color : const Color(0xFF9CA3AF),
        ),
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

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
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
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard({required IconData icon, required String title, required String subtitle}) {
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
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
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
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _handleCheckIn(AttendanceProvider attendanceProvider) async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackBar('Please enter a worker code');
      return;
    }
    final success = await attendanceProvider.checkIn(code);
    if (success && mounted) {
      _codeController.clear();
      _showSuccessSnackBar('Worker checked in successfully!');
    }
  }

  Future<void> _handleCheckOut(AttendanceProvider attendanceProvider) async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackBar('Please enter a worker code');
      return;
    }
    final success = await attendanceProvider.checkOut(code);
    if (success && mounted) {
      _codeController.clear();
      _showSuccessSnackBar('Worker checked out successfully!');
    }
  }

  Future<void> _handleRegisterFace(AttendanceProvider attendanceProvider) async {
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

  Future<void> _handleFaceCheckIn(AttendanceProvider attendanceProvider, ManagerDataProvider managerProvider) async {
    FocusScope.of(context).unfocus();
    final siteId = managerProvider.site?.id ?? '';
    final photoPath = await pickPhoto();
    if (photoPath != null) {
      final success = await attendanceProvider.checkInWithFace(photoPath, siteId);
      if (success && mounted) {
        _showSuccessSnackBar('Face check-in successful!');
      }
    }
  }

  Future<void> _handleFaceCheckOut(AttendanceProvider attendanceProvider) async {
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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