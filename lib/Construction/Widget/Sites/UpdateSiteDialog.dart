import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../../auth/services/auth/auth_service.dart';

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
  late TextEditingController budgetController;
  DateTime? endDate;
  String currentUserId = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    adresseController = TextEditingController();
    geofenceController = TextEditingController();
    budgetController = TextEditingController();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      if (mounted) {
        setState(() {
          currentUserId = user?.id ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    adresseController.dispose();
    geofenceController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final isMobile = screenSize.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isWeb ? 480 : double.infinity,
        constraints: BoxConstraints(
          maxWidth: isWeb ? 480 : screenSize.width - 32,
          maxHeight: screenSize.height * (isMobile ? 0.85 : 0.80),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMobile ? 12 : 16),
                  topRight: Radius.circular(isMobile ? 12 : 16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_location_alt_rounded,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Add Construction Site',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Create a new site at selected location',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Site Information
                    _buildCompactSection(
                      'Site Information',
                      Icons.business_rounded,
                      isMobile,
                      [
                        _buildCompactTextField(
                          controller: nameController,
                          label: 'Site Name',
                          hint: 'e.g., Downtown Project',
                          icon: Icons.business_rounded,
                          isRequired: true,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: adresseController,
                          label: 'Address',
                          hint: 'Enter complete address',
                          icon: Icons.location_on_rounded,
                          isRequired: true,
                          maxLines: 2,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: budgetController,
                          label: 'Budget (TND)',
                          hint: 'Project budget',
                          icon: Icons.account_balance_wallet_rounded,
                          keyboardType: TextInputType.number,
                          prefixText: 'TND ',
                          isMobile: isMobile,
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 16 : 20),

                    // Location & Geofence
                    _buildCompactSection(
                      'Location & Geofence',
                      Icons.my_location_rounded,
                      isMobile,
                      [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 14),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.place_rounded, color: Colors.blue[600], size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Selected Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 12 : 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Lat: ${widget.tappedPoint.latitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  color: Colors.grey[700],
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                'Lng: ${widget.tappedPoint.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  color: Colors.grey[700],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: geofenceController,
                          label: 'Geofence Radius',
                          hint: 'Optional - e.g., 100',
                          icon: Icons.radio_button_unchecked_rounded,
                          keyboardType: TextInputType.number,
                          suffixText: 'm',
                          isMobile: isMobile,
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 16 : 20),

                    // Project Timeline
                    _buildCompactSection(
                      'Project Timeline',
                      Icons.schedule_rounded,
                      isMobile,
                      [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.today_rounded, color: Colors.green[600], size: 16),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: isMobile ? 11 : 12,
                                          ),
                                        ),
                                        Text(
                                          'Today',
                                          style: TextStyle(
                                            fontSize: isMobile ? 10 : 11,
                                            color: Colors.green[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event_rounded, color: Colors.orange[600], size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'End Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: isMobile ? 11 : 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (endDate == null)
                                      GestureDetector(
                                        onTap: _selectEndDate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Select Date',
                                            style: TextStyle(
                                              fontSize: isMobile ? 10 : 11,
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                                              style: TextStyle(
                                                fontSize: isMobile ? 10 : 11,
                                                color: Colors.orange[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(() => endDate = null),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.red[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Icon(
                                                Icons.clear,
                                                size: 12,
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(isMobile ? 12 : 16),
                  bottomRight: Radius.circular(isMobile ? 12 : 16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: isMobile ? 14 : 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _createSite,
                      icon: isLoading
                          ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(Icons.add_location_alt_rounded, size: isMobile ? 16 : 18),
                      label: Text(
                        isLoading ? 'Creating...' : 'Create Site',
                        style: TextStyle(fontSize: isMobile ? 14 : 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSection(String title, IconData icon, bool isMobile, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: AppColors.primary, size: isMobile ? 14 : 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
    int maxLines = 1,
    String? prefixText,
    String? suffixText,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 13),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: isMobile ? 13 : 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: isMobile ? 12 : 13),
            prefixIcon: Icon(icon, size: isMobile ? 18 : 20, color: Colors.grey[600]),
            prefixText: prefixText,
            suffixText: suffixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 14,
              vertical: isMobile ? 12 : 14,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  Future<void> _createSite() async {
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter a site name');
      return;
    }

    if (adresseController.text.trim().isEmpty) {
      _showError('Please enter an address');
      return;
    }

    if (currentUserId.isEmpty) {
      _showError('Unable to get current user. Please try again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final geofenceRadius = geofenceController.text.isNotEmpty
          ? double.tryParse(geofenceController.text)
          : null;

      final newSite = ConstructionSite(
        id: "",
        name: nameController.text.trim(),
        adresse: adresseController.text.trim(),
        latitude: widget.tappedPoint.latitude,
        longitude: widget.tappedPoint.longitude,
        geofenceRadius: geofenceRadius,
        geofenceCenterLat: widget.tappedPoint.latitude,
        geofenceCenterLng: widget.tappedPoint.longitude,
        startDate: DateTime.now(),
        endDate: endDate,
        budget: budgetController.text.isNotEmpty ? budgetController.text.trim() : null,
        isActive: true,
        owner: currentUserId,
      );

      await context.read<SiteProvider>().addSite(newSite, currentUserId);
      if (mounted) {
        widget.onSiteAdded();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Site "${nameController.text.trim()}" created successfully!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError('Failed to create site: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}