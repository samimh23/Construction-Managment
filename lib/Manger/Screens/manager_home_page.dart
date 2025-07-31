import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../auth/services/auth/auth_service.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final _codeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _locationStarted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ManagerDataProvider>().loadSiteAndWorkers();
      await _startLocationTracking();
    });
  }

  Future<void> _startLocationTracking() async {
    if (_locationStarted) return;
    _locationStarted = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();
      final managerId = currentUser?.id ?? "unknown";

      final managerProvider = context.read<ManagerDataProvider>();
      final site = managerProvider.site;
      final siteId = site != null ? site.id : "unknown";
      final locationProvider = Provider.of<ManagerLocationProvider>(context, listen: false);

      locationProvider.connect(managerId, siteId);

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        locationProvider.sendLocation(
          managerId: managerId,
          siteId: siteId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<String?> pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    return picked?.path;
  }

  @override
  void dispose() {
    Provider.of<ManagerLocationProvider>(context, listen: false).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managerProvider = Provider.of<ManagerDataProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manager Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ManagerDataProvider>().loadSiteAndWorkers();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions Section
              _buildQuickActionsCard(attendanceProvider, managerProvider),
              const SizedBox(height: 20),

              // Site Information Section
              _buildSiteInfoCard(managerProvider),
              const SizedBox(height: 20),

              // Workers Section
              _buildWorkersCard(managerProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(AttendanceProvider attendanceProvider, ManagerDataProvider managerProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.work_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Worker Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Worker Code Input
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: "Worker Code",
                hintText: "Enter worker code",
                prefixIcon: const Icon(Icons.qr_code, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[600]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Error Message
            if (attendanceProvider.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attendanceProvider.error!,
                        style: TextStyle(color: Colors.red[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (attendanceProvider.error != null) const SizedBox(height: 16),

            // Manual Check-in/out Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Check In',
                    icon: Icons.login,
                    color: Colors.green,
                    isLoading: attendanceProvider.isLoading,
                    onPressed: () async {
                      final success = await attendanceProvider.checkIn(_codeController.text.trim());
                      if (success && mounted) {
                        _showSuccessSnackBar('Worker checked in successfully!');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Check Out',
                    icon: Icons.logout,
                    color: Colors.orange,
                    isLoading: attendanceProvider.isLoading,
                    onPressed: () async {
                      final success = await attendanceProvider.checkOut(_codeController.text.trim());
                      if (success && mounted) {
                        _showSuccessSnackBar('Worker checked out successfully!');
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Face Recognition Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.face, color: Colors.purple[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Face Recognition',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Face Registration Button
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                      label: 'Register Face',
                      icon: Icons.face_retouching_natural,
                      color: Colors.purple,
                      isLoading: attendanceProvider.isLoading,
                      isSecondary: true,
                      onPressed: () async {
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
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Face Check-in/out Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'Face Check In',
                          icon: Icons.camera_alt,
                          color: Colors.green,
                          isLoading: attendanceProvider.isLoading,
                          isSecondary: true,
                          onPressed: () async {
                            final siteId = managerProvider.site?.id ?? '';
                            final photoPath = await pickPhoto();
                            if (photoPath != null) {
                              final success = await attendanceProvider.checkInWithFace(photoPath, siteId);
                              if (success && mounted) {
                                _showSuccessSnackBar('Face check-in successful!');
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Face Check Out',
                          icon: Icons.camera_alt_outlined,
                          color: Colors.orange,
                          isLoading: attendanceProvider.isLoading,
                          isSecondary: true,
                          onPressed: () async {
                            final photoPath = await pickPhoto();
                            if (photoPath != null) {
                              final success = await attendanceProvider.checkOutWithFace(photoPath);
                              if (success && mounted) {
                                _showSuccessSnackBar('Face check-out successful!');
                              }
                            }
                          },
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

  Widget _buildSiteInfoCard(ManagerDataProvider managerProvider) {
    if (managerProvider.isLoading) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (managerProvider.error != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 12),
              Text(
                'Error loading site info',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                managerProvider.error!,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (managerProvider.site == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.location_off, color: Colors.grey[400], size: 48),
              const SizedBox(height: 12),
              Text(
                'No assigned site',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: Colors.green[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        site.adresse,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: site.isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    site.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: site.isActive ? Colors.green[600] : Colors.red[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSiteInfoItem(
                    icon: Icons.my_location,
                    label: 'Coordinates',
                    value: '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSiteInfoItem(
                    icon: Icons.radio_button_unchecked,
                    label: 'Geofence',
                    value: '${site.geofenceRadius ?? "N/A"} meters',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSiteInfoItem(
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
    );
  }

  Widget _buildSiteInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.group,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Workers (${managerProvider.workers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (managerProvider.workers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.group_off, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No workers assigned',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...managerProvider.workers.map((worker) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          (worker['firstName']?.toString() ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker['firstName']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'ID: ${worker['_id']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: worker['faceRegistered'] == true ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            worker['faceRegistered'] == true ? Icons.verified : Icons.warning,
                            size: 14,
                            color: worker['faceRegistered'] == true ? Colors.green[600] : Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            worker['faceRegistered'] == true ? 'Verified' : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: worker['faceRegistered'] == true ? Colors.green[600] : Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
    bool isSecondary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isSecondary ? color : Colors.white,
          ),
        ),
      )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? Colors.white : color,
        foregroundColor: isSecondary ? color : Colors.white,
        side: isSecondary ? BorderSide(color: color) : null,
        elevation: isSecondary ? 0 : 2,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}