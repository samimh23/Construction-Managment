import 'dart:convert';
import 'package:constructionproject/Construction/Core/Constants/api_constants.dart';
import 'package:constructionproject/Manger/Service/conectivty_service.dart';
import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String? ownerId;

  // Responsive breakpoints
  bool get isTablet => MediaQuery.of(context).size.width > 600;
  bool get isSmallScreen => MediaQuery.of(context).size.height < 650;

  // Responsive values
  EdgeInsets get responsivePadding => EdgeInsets.all(isTablet ? 24 : 16);
  double get responsiveSpacing => isTablet ? 24 : 16;
  double get cardPadding => isTablet ? 24 : 16;

  @override
  void initState() {
    super.initState();

    // Clear errors when user types
    _codeController.addListener(() {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      if (attendanceProvider.error != null) {
        attendanceProvider.clearError();
      }
    });

    Future.microtask(() async {
      await context.read<ManagerDataProvider>().loadSiteAndWorkers();
      await _fetchManagerAndStoreOwnerId();
    });
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
        if (mounted) {
          setState(() {
            ownerId = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          ownerId = null;
        });
      }
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
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          locationProvider.sendLocation(
            managerId: managerId,
            siteId: siteId,
            latitude: position.latitude,
            longitude: position.longitude,
            ownerId: ownerId,
          );
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
        maxWidth: 800,  // Optimize for mobile
        maxHeight: 600,
        imageQuality: 80,
      );
      return picked?.path;
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Camera access failed. Please try again.');
      }
      return null;
    }
  }

  Widget _buildOfflineIndicator(AttendanceProvider attendanceProvider) {
    if (!attendanceProvider.hasOfflineCapabilities || attendanceProvider.pendingRequestsCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: responsiveSpacing * 0.75),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange[600], size: isTablet ? 24 : 20),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(
              '${attendanceProvider.pendingRequestsCount} requests pending sync',
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (attendanceProvider.isSyncing)
            SizedBox(
              width: isTablet ? 20 : 16,
              height: isTablet ? 20 : 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
              ),
            )
          else
            TextButton(
              onPressed: () => attendanceProvider.syncPendingRequests(),
              style: TextButton.styleFrom(
                minimumSize: const Size(60, 32),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
              ),
              child: Text(
                'Sync',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(bottom: responsiveSpacing * 0.75),
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red[600], size: isTablet ? 24 : 20),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                child: Text(
                  'No internet connection - working offline',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Manager Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, attendanceProvider, child) {
              if (!attendanceProvider.hasOfflineCapabilities ||
                  attendanceProvider.pendingRequestsCount == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: EdgeInsets.only(right: isTablet ? 16 : 8),
                child: IconButton(
                  icon: attendanceProvider.isSyncing
                      ? SizedBox(
                    width: isTablet ? 24 : 20,
                    height: isTablet ? 24 : 20,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(Icons.sync, size: isTablet ? 28 : 24),
                  onPressed: attendanceProvider.isSyncing
                      ? null
                      : () => attendanceProvider.syncPendingRequests(),
                  tooltip: 'Sync pending requests',
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ManagerDataProvider>().loadSiteAndWorkers();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicators
              _buildConnectionStatus(),
              _buildOfflineIndicator(attendanceProvider),

              // Quick Actions Section
              _buildQuickActionsCard(attendanceProvider, managerProvider),
              SizedBox(height: responsiveSpacing),

              // Site Information Section
              _buildSiteInfoCard(managerProvider),
              SizedBox(height: responsiveSpacing),

              // Workers Section
              _buildWorkersCard(managerProvider),

              // Add bottom padding for better scrolling experience
              SizedBox(height: responsiveSpacing),
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
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                  ),
                  child: Icon(
                    Icons.work_outline,
                    color: Colors.blue[600],
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Text(
                    'Worker Management',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsiveSpacing),

            // Worker Code Input
            TextField(
              controller: _codeController,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: "Worker Code",
                hintText: "Enter worker code",
                prefixIcon: Icon(Icons.qr_code, size: isTablet ? 24 : 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  borderSide: BorderSide(color: Colors.blue[600]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
                labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                hintStyle: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
            SizedBox(height: responsiveSpacing * 0.75),

            // Error Message
            if (attendanceProvider.error != null)
              Container(
                margin: EdgeInsets.only(bottom: responsiveSpacing * 0.75),
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: isTablet ? 20 : 16),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: Text(
                        attendanceProvider.error!,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Manual Check-in/out Buttons
            _buildResponsiveButtonRow([
              _ActionButtonConfig(
                label: 'Check In',
                icon: Icons.login,
                color: Colors.green,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  final code = _codeController.text.trim();
                  if (code.isEmpty) {
                    _showErrorSnackBar('Please enter a worker code');
                    return;
                  }

                  final success = await attendanceProvider.checkIn(code);
                  if (success && mounted) {
                    _codeController.clear();
                    if (attendanceProvider.isOffline) {
                      _showSuccessSnackBar('Check-in saved offline. Will sync when online.');
                    } else {
                      _showSuccessSnackBar('Worker checked in successfully!');
                    }
                  }
                },
              ),
              _ActionButtonConfig(
                label: 'Check Out',
                icon: Icons.logout,
                color: Colors.orange,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  final success = await attendanceProvider.checkOut(_codeController.text.trim());
                  if (success && mounted) {
                    if (attendanceProvider.isOffline) {
                      _showSuccessSnackBar('Check-out saved offline. Will sync when online.');
                    } else {
                      _showSuccessSnackBar('Worker checked out successfully!');
                    }
                  }
                },
              ),
            ], attendanceProvider.isLoading),
            SizedBox(height: responsiveSpacing),

            // Face Recognition Section
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.face, color: Colors.purple[600], size: isTablet ? 24 : 20),
                      SizedBox(width: isTablet ? 12 : 8),
                      Expanded(
                        child: Text(
                          'Face Recognition',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsiveSpacing * 0.75),

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
                      },
                    ),
                  ),
                  SizedBox(height: responsiveSpacing * 0.5),

                  // Face Check-in/out Buttons
                  _buildResponsiveButtonRow([
                    _ActionButtonConfig(
                      label: 'Face Check In',
                      icon: Icons.camera_alt,
                      color: Colors.green,
                      isSecondary: true,
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
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
                    _ActionButtonConfig(
                      label: 'Face Check Out',
                      icon: Icons.camera_alt_outlined,
                      color: Colors.orange,
                      isSecondary: true,
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final photoPath = await pickPhoto();
                        if (photoPath != null) {
                          final success = await attendanceProvider.checkOutWithFace(photoPath);
                          if (success && mounted) {
                            _showSuccessSnackBar('Face check-out successful!');
                          }
                        }
                      },
                    ),
                  ], attendanceProvider.isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveButtonRow(List<_ActionButtonConfig> buttons, bool isLoading) {
    if (isSmallScreen && buttons.length > 1) {
      // Stack buttons vertically on small screens
      return Column(
        children: buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final button = entry.value;
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  label: button.label,
                  icon: button.icon,
                  color: button.color,
                  isLoading: isLoading,
                  isSecondary: button.isSecondary,
                  onPressed: button.onPressed,
                ),
              ),
              if (index < buttons.length - 1) SizedBox(height: responsiveSpacing * 0.5),
            ],
          );
        }).toList(),
      );
    } else {
      // Show buttons in a row for larger screens
      return Row(
        children: buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final button = entry.value;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: button.label,
                    icon: button.icon,
                    color: button.color,
                    isLoading: isLoading,
                    isSecondary: button.isSecondary,
                    onPressed: button.onPressed,
                  ),
                ),
                if (index < buttons.length - 1) SizedBox(width: responsiveSpacing * 0.5),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildSiteInfoCard(ManagerDataProvider managerProvider) {
    if (managerProvider.isLoading) {
      return Container(
        width: double.infinity,
        height: isTablet ? 140 : 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: isTablet ? 56 : 48),
              SizedBox(height: responsiveSpacing * 0.75),
              Text(
                'Error loading site info',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: responsiveSpacing * 0.5),
              Text(
                managerProvider.error!,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: isTablet ? 16 : 14,
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
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            children: [
              Icon(Icons.location_off, color: Colors.grey[400], size: isTablet ? 56 : 48),
              SizedBox(height: responsiveSpacing * 0.75),
              Text(
                'No assigned site',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isTablet ? 18 : 16,
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
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: Colors.green[600],
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        site.adresse,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 8,
                    vertical: isTablet ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: site.isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  ),
                  child: Text(
                    site.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: site.isActive ? Colors.green[600] : Colors.red[600],
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsiveSpacing),

            // Site details in responsive layout
            if (isTablet)
              Row(
                children: [
                  Expanded(
                    child: _buildSiteInfoItem(
                      icon: Icons.my_location,
                      label: 'Coordinates',
                      value: '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
                    ),
                  ),
                  SizedBox(width: responsiveSpacing),
                  Expanded(
                    child: _buildSiteInfoItem(
                      icon: Icons.radio_button_unchecked,
                      label: 'Geofence',
                      value: '${site.geofenceRadius ?? "N/A"} meters',
                    ),
                  ),
                  SizedBox(width: responsiveSpacing),
                  Expanded(
                    child: _buildSiteInfoItem(
                      icon: Icons.attach_money,
                      label: 'Budget',
                      value: site.budget ?? "Not set",
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildSiteInfoItem(
                    icon: Icons.my_location,
                    label: 'Coordinates',
                    value: '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
                  ),
                  SizedBox(height: responsiveSpacing * 0.75),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSiteInfoItem(
                          icon: Icons.radio_button_unchecked,
                          label: 'Geofence',
                          value: '${site.geofenceRadius ?? "N/A"} meters',
                        ),
                      ),
                      SizedBox(width: responsiveSpacing),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSiteInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: isTablet ? 20 : 16, color: Colors.grey[500]),
        SizedBox(width: isTablet ? 12 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                  ),
                  child: Icon(
                    Icons.group,
                    color: Colors.blue[600],
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Text(
                    'Workers (${managerProvider.workers.length})',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsiveSpacing),

            if (managerProvider.workers.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.group_off, color: Colors.grey[400], size: isTablet ? 56 : 48),
                    SizedBox(height: responsiveSpacing * 0.75),
                    Text(
                      'No workers assigned',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...managerProvider.workers.map((worker) => Container(
                margin: EdgeInsets.only(bottom: responsiveSpacing * 0.75),
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isTablet ? 56 : 48,
                      height: isTablet ? 56 : 48,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                      ),
                      child: Center(
                        child: Text(
                          (worker['firstName']?.toString() ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker['firstName']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),

                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 8,
                        vertical: isTablet ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: worker['faceRegistered'] == true ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            worker['faceRegistered'] == true ? Icons.verified : Icons.warning,
                            size: isTablet ? 18 : 14,
                            color: worker['faceRegistered'] == true ? Colors.green[600] : Colors.orange[600],
                          ),
                          SizedBox(width: isTablet ? 6 : 4),
                          Text(
                            worker['faceRegistered'] == true ? 'Verified' : 'Pending',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
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
        width: isTablet ? 20 : 16,
        height: isTablet ? 20 : 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isSecondary ? color : Colors.white,
          ),
        ),
      )
          : Icon(icon, size: isTablet ? 22 : 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? Colors.white : color,
        foregroundColor: isSecondary ? color : Colors.white,
        side: isSecondary ? BorderSide(color: color) : null,
        elevation: isSecondary ? 0 : 2,
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 12,
          horizontal: isTablet ? 20 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        ),
        minimumSize: Size(double.infinity, isTablet ? 56 : 48),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars(); // Clear existing snackbars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: isTablet ? 24 : 20),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        ),
        margin: EdgeInsets.all(isTablet ? 20 : 16),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 16 : 12,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars(); // Clear existing snackbars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: isTablet ? 24 : 20),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        ),
        margin: EdgeInsets.all(isTablet ? 20 : 16),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 16 : 12,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// Helper class for button configuration
class _ActionButtonConfig {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSecondary;

  const _ActionButtonConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isSecondary = false,
  });
}