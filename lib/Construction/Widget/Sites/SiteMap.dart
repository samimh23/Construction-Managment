import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:constructionproject/Construction/service/nominatim_search_service.dart';
import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:constructionproject/profile/provider/profile_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../Core/Constants/app_colors.dart';
import '../../Core/Constants/api_constants.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../screen/ConstructionSite/Details.dart';

class SiteMap extends StatefulWidget {
  final Function(BuildContext, LatLng) onAddSite;
  final LatLng? initialCenter;
  final double? initialZoom;
  final dynamic focusSite;

  const SiteMap({
    super.key,
    required this.onAddSite,
    this.initialCenter,
    this.initialZoom,
    this.focusSite,
  });

  @override
  State<SiteMap> createState() => _SiteMapState();
}

class _SiteMapState extends State<SiteMap> with AutomaticKeepAliveClientMixin {
  // Separate caches for immediate socket updates
  final Map<String, Marker> _siteMarkerCache = {};
  final Map<String, Marker> _managerMarkerCache = {};
  final Map<String, bool> _siteProximityCache = {};

  // NEW: Label caches for performance
  final Map<String, Marker> _siteLabelCache = {};
  final Map<String, Marker> _managerLabelCache = {};

  // NEW: Manager name cache for performance
  final Map<String, String> _managerNameCache = {};
  // NEW: Track pending API calls to avoid duplicates
  final Set<String> _pendingNameFetches = {};

  // Preloaded widgets for performance
  late final Widget _greenManagerWidget;
  late final Widget _redManagerWidget;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _searchDebouncer;

  LatLngBounds? _viewBounds;
  double _zoom = 10.0;
  bool _isMoving = false;

  // Separate tracking for sites and managers for immediate updates
  List<dynamic> _sitesSnapshot = [];
  Map<String, ManagerLocation> _managersMap = {}; // Map for O(1) lookups
  List<ManagerLocation> _managersSnapshot = []; // For backward compatibility
  bool _sitesDataChanged = false;
  bool _managersDataChanged = false;

  // Built markers and circles
  List<Marker> _builtSiteMarkers = [];
  List<Marker> _builtManagerMarkers = [];
  List<CircleMarker> _builtCircles = [];

  // NEW: Built labels
  List<Marker> _builtSiteLabels = [];
  List<Marker> _builtManagerLabels = [];

  SiteProvider? _siteProviderRef;
  ManagerLocationProvider? _managerProviderRef;
  final MapController _mapController = MapController();

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  late final int _maxMarkersForMobile;
  late final Duration _debounceDelayForMobile;

  LatLng? _userLocation;
  bool _isGettingLocation = false;
  String? _locationError;
  LatLng? _searchMarkerPosition;

  // Timer for batched updates (non-critical)
  Timer? _updateTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMobileOptimizations();
    _preloadWidgets();
    _setupDataListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusSite != null) {
        _goToSite(widget.focusSite);
      }
      _rebuildAllMarkers();
    });
  }

  void _initializeMobileOptimizations() {
    _maxMarkersForMobile = _isMobile ? 25 : 60;
    _debounceDelayForMobile =
    _isMobile ? const Duration(milliseconds: 300) : const Duration(milliseconds: 100);
  }

  @override
  void dispose() {
    _siteProviderRef?.removeListener(_onSitesDataChanged);
    _managerProviderRef?.removeListener(_onManagersDataChanged);
    _searchDebouncer?.cancel();
    _updateTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _preloadWidgets() {
    _greenManagerWidget = _buildManagerWidget(Colors.green);
    _redManagerWidget = _buildManagerWidget(Colors.red);
  }

  Widget _buildManagerWidget(Color color) {
    return RepaintBoundary(
      child: Container(
        width: _isMobile ? 24 : 28,
        height: _isMobile ? 24 : 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: _isMobile ? 1.5 : 2),
        ),
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: _isMobile ? 12 : 14,
        ),
      ),
    );
  }

  void _setupDataListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _siteProviderRef = Provider.of<SiteProvider>(context, listen: false);
      _managerProviderRef = Provider.of<ManagerLocationProvider>(context, listen: false);

      // Initial data load - ONLY ACTIVE SITES
      _sitesSnapshot = List.from(_siteProviderRef!.sites.where((site) => site.isActive == true));
      _updateManagersFromProvider(_managerProviderRef!.managers);

      _sitesDataChanged = true;
      _managersDataChanged = true;

      // Separate listeners for optimal performance
      _siteProviderRef!.addListener(_onSitesDataChanged);
      _managerProviderRef!.addListener(_onManagersDataChanged);

      _rebuildAllMarkers();

      // FIXED: Start fetching manager names immediately
      _preloadManagerNames();
    });
  }

  // NEW: Preload all manager names immediately
  void _preloadManagerNames() {
    for (final manager in _managersMap.values) {
      _fetchManagerNameIfNeeded(manager.managerId);
    }
  }

  // NEW: Fetch manager name if not already cached or pending
  void _fetchManagerNameIfNeeded(String managerId) {
    if (_managerNameCache.containsKey(managerId) || _pendingNameFetches.contains(managerId)) {
      return; // Already have name or fetching
    }

    _pendingNameFetches.add(managerId);
    _getManagerDisplayNameFromAPI(managerId).then((name) {
      if (mounted) {
        _pendingNameFetches.remove(managerId);
        final oldName = _managerNameCache[managerId];
        _managerNameCache[managerId] = name;

        // FORCE label rebuild if name changed
        if (oldName != name) {
          if (kDebugMode) {
            print('🎯 Updated manager name: $managerId -> $name');
          }

          // Update the specific label immediately
          _updateManagerLabel(managerId);
        }
      }
    }).catchError((e) {
      if (mounted) {
        _pendingNameFetches.remove(managerId);
        if (kDebugMode) {
          print('❌ Failed to fetch name for $managerId: $e');
        }
      }
    });
  }

  // NEW: Force label update for specific manager
  void _updateManagerLabel(String managerId) {
    if (!_shouldShowLabels()) return;

    final manager = _managersMap[managerId];
    if (manager == null) return;

    final markerKey = 'manager_$managerId';

    // Force rebuild label with new name
    _managerLabelCache[markerKey] = _buildManagerLabel(manager);

    // Update the built labels list immediately
    setState(() {
      // Remove old label for this manager
      _builtManagerLabels.removeWhere((label) =>
      label.point == LatLng(manager.latitude, manager.longitude));

      // Add new label with updated name
      _builtManagerLabels.add(_managerLabelCache[markerKey]!);
    });

    if (kDebugMode) {
      print('✅ Updated label for manager $managerId');
    }
  }

  // UPDATED: Get manager display name from API (same as manager home screen)
  Future<String> _getManagerDisplayNameFromAPI(String managerId) async {
    try {
      // Use the same API endpoint as manager home screen
      final url = Uri.parse('${ApiConstants.baseUrl}users/$managerId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract name fields from API response
        final firstName = data['firstName']?.toString();
        final lastName = data['lastName']?.toString();
        final email = data['email']?.toString();

        if (firstName != null && lastName != null) {
          return '$firstName $lastName';
        } else if (firstName != null) {
          return firstName;
        } else if (lastName != null) {
          return lastName;
        } else if (email != null) {
          return _formatEmailToName(email);
        } else {
          return _formatManagerId(managerId);
        }
      } else {
        if (kDebugMode) {
          print('❌ API Error ${response.statusCode} for manager $managerId');
        }
        return _formatManagerId(managerId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception getting manager name for $managerId: $e');
      }
      return _formatManagerId(managerId);
    }
  }

  // UPDATED: Get manager display name - only show names, not IDs
  String _getManagerDisplayName(String managerId) {
    // Return cached name if available
    if (_managerNameCache.containsKey(managerId)) {
      return _managerNameCache[managerId]!;
    }

    // Start immediate fetch if not pending
    _fetchManagerNameIfNeeded(managerId);

    // Return empty string if no name yet - don't show ID
    return '';
  }

  // NEW: Helper method to format email as name
  String _formatEmailToName(String email) {
    if (email.contains('@')) {
      final username = email.split('@')[0];
      return _formatUsername(username);
    }
    return _formatUsername(email);
  }

  // NEW: Helper method to format username
  String _formatUsername(String username) {
    String formatted = username.replaceAll(RegExp(r'[._-]'), ' ');
    return formatted.split(' ')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : word)
        .join(' ');
  }

  // NEW: Helper method to format manager ID
  String _formatManagerId(String managerId) {
    if (managerId.contains('@')) {
      return _formatEmailToName(managerId);
    } else if (managerId.contains('_') || managerId.contains('-') || managerId.contains('.')) {
      return _formatUsername(managerId);
    } else if (managerId.length > 15) {
      return '${managerId.substring(0, 8)}...'; // SHORTER for labels
    }
    return managerId;
  }

  // Helper to truncate text for labels
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // FIXED: Simple text label without container styling
  Marker _buildSiteLabel(dynamic site) {
    final siteName = _truncateText(site.name, _isMobile ? 12 : 15);

    return Marker(
      point: LatLng(site.latitude, site.longitude),
      width: _isMobile ? 80 : 100,
      height: _isMobile ? 16 : 18,
      child: Transform.translate(
        offset: Offset(0, _isMobile ? 12 : 14), // Position below the marker
        child: Text(
          siteName,
          style: TextStyle(
            fontSize: _isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
            shadows: [
              // Add text shadow for better readability on map
              Shadow(
                color: Colors.white,
                blurRadius: 2,
                offset: Offset(0, 0),
              ),
              Shadow(
                color: Colors.white,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // UPDATED: Manager label with real names from API - only show if name exists
  Marker _buildManagerLabel(ManagerLocation manager) {
    final isNearSite = _sitesSnapshot.any((site) => _isManagerNearSite(manager, site));
    final managerName = _getManagerDisplayName(manager.managerId);

    // Don't show label if no name yet
    if (managerName.isEmpty) {
      return Marker(
        point: LatLng(manager.latitude, manager.longitude),
        width: 0,
        height: 0,
        child: const SizedBox.shrink(), // Invisible marker
      );
    }

    final displayName = _truncateText(managerName, _isMobile ? 10 : 12);

    if (kDebugMode) {
      print('🏷️ Building label for ${manager.managerId}: "$displayName"');
    }

    return Marker(
      point: LatLng(manager.latitude, manager.longitude),
      width: _isMobile ? 80 : 90, // WIDER for names
      height: _isMobile ? 20 : 22,
      child: Transform.translate(
        offset: Offset(0, _isMobile ? -20 : -22), // Position above the marker
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isNearSite ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: _isMobile ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: isNearSite ? Colors.green[700] : Colors.red[700],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // OPTIMIZED: Update managers with immediate socket response
  void _updateManagersFromProvider(List<ManagerLocation> managers) {
    final newManagersMap = <String, ManagerLocation>{};
    for (final manager in managers) {
      newManagersMap[manager.managerId] = manager;
    }

    // Check for changes and update immediately
    bool hasChanges = false;

    // Check for new or updated managers (SOCKET UPDATES)
    for (final entry in newManagersMap.entries) {
      final existing = _managersMap[entry.key];
      if (existing == null ||
          existing.latitude != entry.value.latitude ||
          existing.longitude != entry.value.longitude) {
        hasChanges = true;
        if (kDebugMode) {
          print('🔄 Socket Update: Manager ${entry.key} location: ${entry.value.latitude}, ${entry.value.longitude}');
        }
        // IMMEDIATE UPDATE - No waiting!
        _updateSingleManagerMarkerImmediately(entry.value);

        // Start fetching name for new managers
        _fetchManagerNameIfNeeded(entry.key);
      }
    }

    // Check for removed managers
    for (final managerId in _managersMap.keys) {
      if (!newManagersMap.containsKey(managerId)) {
        hasChanges = true;
        _removeSingleManagerMarker(managerId);
      }
    }

    _managersMap = newManagersMap;
    _managersSnapshot = managers; // Keep for backward compatibility

    if (hasChanges) {
      _managersDataChanged = true;
      // INSTANT update - no delays for socket data!
      _triggerImmediateManagerDisplay();
    }
  }

  // IMMEDIATE marker update for socket data
  void _updateSingleManagerMarkerImmediately(ManagerLocation manager) {
    // FIXED: Remove strict visibility check - always update if data changes
    final isNearSite = _sitesSnapshot.any((site) => _isManagerNearSite(manager, site));
    final markerKey = 'manager_${manager.managerId}';

    final marker = Marker(
      point: LatLng(manager.latitude, manager.longitude),
      width: _isMobile ? 24 : 28,
      height: _isMobile ? 24 : 28,
      child: GestureDetector(
        onTap: () => _handleManagerTap(manager),
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: isNearSite ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: _isMobile ? 1.5 : 2),
              boxShadow: [
                BoxShadow(
                  color: (isNearSite ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person, // Manager icon
              color: Colors.white,
              size: _isMobile ? 12 : 14,
            ),
          ),
        ),
      ),
    );

    _managerMarkerCache[markerKey] = marker;

    // NEW: Also update label cache
    if (_shouldShowLabels()) {
      _managerLabelCache[markerKey] = _buildManagerLabel(manager);
    }

    if (kDebugMode) {
      print('✅ INSTANT: Updated marker for manager ${manager.managerId} (${isNearSite ? "near site" : "away from site"})');
    }
  }

  void _removeSingleManagerMarker(String managerId) {
    final markerKey = 'manager_$managerId';
    _managerMarkerCache.remove(markerKey);
    _managerLabelCache.remove(markerKey); // NEW: Also remove label
    _managerNameCache.remove(managerId); // NEW: Clear name cache
    _pendingNameFetches.remove(managerId); // NEW: Stop pending fetches
    if (kDebugMode) {
      print('🗑️ Removed marker for manager $managerId');
    }
  }

  // INSTANT display update for socket data
  void _triggerImmediateManagerDisplay() {
    if (!mounted || _isMoving) return;

    // Cancel any pending batch update
    _updateTimer?.cancel();

    // IMMEDIATE setState for manager markers AND labels
    setState(() {
      _builtManagerMarkers = _managerMarkerCache.values.toList();
      _builtManagerLabels = _managerLabelCache.values.toList();
    });

    if (kDebugMode) {
      print('🚀 INSTANT: Displayed ${_builtManagerMarkers.length} manager markers with labels');
    }

    // Schedule full rebuild for optimizations (non-blocking)
    _updateTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted && !_isMoving) {
        _rebuildAllMarkers();
      }
    });
  }

  void _onSitesDataChanged() {
    if (!mounted || _siteProviderRef == null) return;

    _sitesDataChanged = true;
    // ONLY ACTIVE SITES
    _sitesSnapshot = List.from(_siteProviderRef!.sites.where((site) => site.isActive == true));
    _siteMarkerCache.clear();
    _siteLabelCache.clear(); // NEW: Clear label cache
    _siteProximityCache.clear();

    // Batch update for sites (less critical than real-time manager tracking)
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_isMoving) {
        _rebuildAllMarkers();
      }
    });
  }

  void _onManagersDataChanged() {
    if (!mounted || _managerProviderRef == null) return;

    // IMMEDIATE processing for socket updates
    _updateManagersFromProvider(_managerProviderRef!.managers);
  }

  // FIXED: Show labels at much lower zoom level - starting from zoom 8
  bool _shouldShowLabels() {
    return _zoom >= 8.0; // FIXED: Much lower threshold - was 11.0
  }

  // PERFECT: 1-second search delay - shows suggestions when you stop typing for 1 second
  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();

    // Search by coordinates (e.g. "36.834771, 10.177767" or "36.834771 10.177767")
    final coordMatch = RegExp(r'^\s*(-?\d+(\.\d+)?)[,\s]+(-?\d+(\.\d+)?)\s*$').firstMatch(query);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lng = double.tryParse(coordMatch.group(3)!);
      if (lat != null && lng != null) {
        setState(() {
          _searchResults.clear();
          _showSearchResults = false;
          _isSearching = false;
          _searchMarkerPosition = LatLng(lat, lng);
        });
        _mapController.move(_searchMarkerPosition!, _isMobile ? 15.0 : 16.0);
        return;
      }
    }

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
        _isSearching = false;
        _searchMarkerPosition = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = false; // Hide previous results while searching
    });

    // FIXED: Exactly 1 second delay for suggestions
    _searchDebouncer = Timer(const Duration(milliseconds: 1000), () {
      _performSearch(query.trim());
    });
  }

  // FIXED: Remove overly restrictive visibility check
  bool _isPointVisible(double lat, double lng) {
    if (_viewBounds == null) return true;
    // FIXED: Larger buffer to prevent markers from disappearing
    final buffer = _isMobile ? 0.05 : 0.03; // Increased from 0.01/0.005
    return lat >= _viewBounds!.south - buffer &&
        lat <= _viewBounds!.north + buffer &&
        lng >= _viewBounds!.west - buffer &&
        lng <= _viewBounds!.east + buffer;
  }

  bool _isManagerNearSite(ManagerLocation manager, dynamic site) {
    final cacheKey = '${manager.managerId}_${site.id}';
    if (_siteProximityCache.containsKey(cacheKey)) {
      return _siteProximityCache[cacheKey]!;
    }

    const double meterPerDegree = 111000;
    final latDiff = (manager.latitude - site.latitude).abs() * meterPerDegree;
    final lngDiff = (manager.longitude - site.longitude).abs() * meterPerDegree;

    final radius = site.geofenceRadius ?? 100.0;
    final isNear = latDiff < radius && lngDiff < radius;

    _siteProximityCache[cacheKey] = isNear;
    return isNear;
  }

  // FIXED: Better geofence visibility logic for optimal UX
  bool _shouldShowGeofences(double zoomValue) {
    // Only show geofences when zoomed in close enough for detailed view
    // This prevents cluttered map at medium zoom levels
    return zoomValue >= 16.0 && zoomValue <= 20.0;
  }

  void _rebuildAllMarkers() {
    if (!mounted) return;

    _buildSiteMarkersIfNeeded();
    _buildManagerMarkersIfNeeded();
    _buildCirclesIfNeeded();

    if (mounted && !_isMoving) {
      setState(() {}); // Single setState for all updates
    }
  }

  void _buildSiteMarkersIfNeeded() {
    if (!_sitesDataChanged) return;

    final markers = <Marker>[];
    final labels = <Marker>[];

    // FIXED: Remove marker limits based on zoom - show ALL visible sites
    final showLabels = _shouldShowLabels();

    for (final site in _sitesSnapshot) {
      // FIXED: Still check visibility but with larger buffer
      if (!_isPointVisible(site.latitude, site.longitude)) continue;

      final markerKey = 'site_${site.id}';

      if (!_siteMarkerCache.containsKey(markerKey)) {
        _siteMarkerCache[markerKey] = Marker(
          point: LatLng(site.latitude, site.longitude),
          width: _isMobile ? 20 : 24,
          height: _isMobile ? 20 : 24,
          child: GestureDetector(
            onTap: () => _handleSiteTap(site),
            child: RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: _isMobile ? 1.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: _isMobile ? 10 : 12,
                ),
              ),
            ),
          ),
        );
      }

      // FIXED: Always build labels when needed
      if (showLabels) {
        if (!_siteLabelCache.containsKey(markerKey)) {
          _siteLabelCache[markerKey] = _buildSiteLabel(site);
        }
      }

      markers.add(_siteMarkerCache[markerKey]!);

      // NEW: Add label if showing labels
      if (showLabels && _siteLabelCache.containsKey(markerKey)) {
        labels.add(_siteLabelCache[markerKey]!);
      }
    }

    _builtSiteMarkers = markers;
    _builtSiteLabels = showLabels ? labels : [];
    _sitesDataChanged = false;

    if (kDebugMode) {
      print('🏗️ Built ${markers.length} site markers, ${labels.length} labels (zoom: ${_zoom.toStringAsFixed(1)})');
    }
  }

  void _buildManagerMarkersIfNeeded() {
    if (!_managersDataChanged) return;

    final markers = <Marker>[];
    final labels = <Marker>[];
    final showLabels = _shouldShowLabels();

    for (final manager in _managersMap.values) {
      // FIXED: Still check visibility but with larger buffer
      if (!_isPointVisible(manager.latitude, manager.longitude)) continue;

      final markerKey = 'manager_${manager.managerId}';

      if (!_managerMarkerCache.containsKey(markerKey)) {
        _updateSingleManagerMarkerImmediately(manager);
      }

      if (_managerMarkerCache.containsKey(markerKey)) {
        markers.add(_managerMarkerCache[markerKey]!);

        // NEW: Add manager label if showing labels - ALWAYS rebuild, never cache
        if (showLabels) {
          // ALWAYS rebuild label to get latest name
          _managerLabelCache[markerKey] = _buildManagerLabel(manager);
          if (_managerLabelCache.containsKey(markerKey)) {
            labels.add(_managerLabelCache[markerKey]!);
          }
        }
      }
    }

    _builtManagerMarkers = markers;
    _builtManagerLabels = showLabels ? labels : [];
    _managersDataChanged = false;

    if (kDebugMode) {
      print('👤 Built ${markers.length} manager markers, ${labels.length} labels');
    }
  }

  void _buildCirclesIfNeeded() {
    final circles = <CircleMarker>[];

    // FIXED: Better geofence visibility - only show when really zoomed in
    if (!_shouldShowGeofences(_zoom)) {
      _builtCircles = circles; // Empty list when zoom is not detailed enough
      if (kDebugMode) {
        print('🔵 Hiding geofence circles at zoom ${_zoom.toStringAsFixed(1)} (need 16.0+)');
      }
      return;
    }

    if (kDebugMode) {
      print('🔵 Building geofence circles at zoom ${_zoom.toStringAsFixed(1)}');
    }

    for (final site in _sitesSnapshot) {
      if (site.geofenceRadius == null || site.geofenceRadius! <= 0) continue;
      if (!_isPointVisible(site.latitude, site.longitude)) continue;

      final baseOpacity = _isMobile ? 0.15 : (_zoom > 17 ? 0.3 : 0.2);
      final borderOpacity = _isMobile ? 0.4 : (_zoom > 17 ? 0.6 : 0.5);
      final borderWidth = _isMobile ? 1.5 : (_zoom > 17 ? 2.5 : 2.0);

      circles.add(CircleMarker(
        point: LatLng(site.latitude, site.longitude),
        color: AppColors.primary.withOpacity(baseOpacity),
        borderStrokeWidth: borderWidth,
        borderColor: AppColors.primary.withOpacity(borderOpacity),
        radius: site.geofenceRadius!.toDouble(),
      ));
    }

    _builtCircles = circles;

    if (kDebugMode) {
      print('✅ Built ${circles.length} geofence circles');
    }
  }

  Future<void> _handleSiteTap(dynamic site) async {
    if (_isMobile) {
      HapticFeedback.lightImpact();
    }
    _goToSite(site);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SiteDetailsScreen(site: site)),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  // UPDATED: Manager tap with real names from API
  void _handleManagerTap(ManagerLocation manager) {
    if (_isMobile) {
      HapticFeedback.lightImpact();
    }

    final nearestSite = _sitesSnapshot
        .where((site) => _isManagerNearSite(manager, site))
        .isNotEmpty;

    final isNearSitesList = _sitesSnapshot
        .where((site) => _isManagerNearSite(manager, site))
        .toList();

    final managerName = _getManagerDisplayName(manager.managerId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: nearestSite ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Manager: $managerName', // Shows actual manager name from API
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '📍 ${manager.latitude.toStringAsFixed(6)}, ${manager.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    nearestSite
                        ? '✅ Inside geofence (${isNearSitesList.length} site${isNearSitesList.length > 1 ? 's' : ''})'
                        : '❌ Outside all geofences',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: nearestSite ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _goToSite(dynamic site) {
    if (site.latitude != null && site.longitude != null) {
      _mapController.move(LatLng(site.latitude, site.longitude), 17.0);
    }
  }

  void _fitToMarkers() {
    final allPoints = <LatLng>[];
    allPoints.addAll(_sitesSnapshot.map((s) => LatLng(s.latitude, s.longitude)));
    allPoints.addAll(_managersSnapshot.map((m) => LatLng(m.latitude, m.longitude)));
    if (_userLocation != null) {
      allPoints.add(_userLocation!);
    }
    if (_searchMarkerPosition != null) {
      allPoints.add(_searchMarkerPosition!);
    }

    if (allPoints.isNotEmpty) {
      try {
        final bounds = LatLngBounds.fromPoints(allPoints);
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.all(_isMobile ? 30 : 50),
        ));
      } catch (e) {
        debugPrint('Fit bounds error: $e');
      }
    }
  }

  // PERFECT: Search with 1-second delay for suggestions
  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    try {
      final center = _mapController.camera.center;

      final results = await NominatimSearchService.search(
        query,
        viewbox: center,
        limit: _isMobile ? 5 : 8,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          // Show suggestions when search completes after 1-second delay
          _showSearchResults = results.isNotEmpty;

          // Only automatically move to first result if it's a very specific search
          if (results.isNotEmpty && results.length == 1) {
            _searchMarkerPosition = results.first.position;
            _mapController.move(_searchMarkerPosition!, _isMobile ? 15.0 : 16.0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showSearchResults = false;
          _searchMarkerPosition = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectSearchResult(SearchResult result) {
    setState(() {
      _searchMarkerPosition = result.position;
      _showSearchResults = false;
      _searchController.text = result.displayName.split(',').first; // Set selected location name
    });
    _mapController.move(result.position, _isMobile ? 15.0 : 16.0);
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showSearchResults = false;
      _isSearching = false;
      _searchMarkerPosition = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled.';
          _isGettingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permissions are denied';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permissions are permanently denied';
          _isGettingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isGettingLocation = false;
        _locationError = null;
      });

      _mapController.move(_userLocation!, _isMobile ? 16.0 : 15.0);
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _isGettingLocation = false;
      });
    }
  }

  // UPDATED: User location marker with tap to create site
  Marker? _buildUserLocationMarker() {
    if (_userLocation == null) return null;
    return Marker(
      point: _userLocation!,
      width: _isMobile ? 27 : 32,
      height: _isMobile ? 27 : 32,
      child: GestureDetector(
        onTap: () {
          if (_isMobile) HapticFeedback.lightImpact();
          // Create site at current location
          widget.onAddSite(context, _userLocation!);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: _isMobile ? 2 : 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.my_location, color: Colors.white, size: _isMobile ? 14 : 16),
        ),
      ),
    );
  }

  Marker? _buildSearchMarker() {
    if (_searchMarkerPosition == null) return null;
    return Marker(
      point: _searchMarkerPosition!,
      width: _isMobile ? 28 : 32,
      height: _isMobile ? 28 : 32,
      child: GestureDetector(
        onTap: () {
          widget.onAddSite(context, _searchMarkerPosition!);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: _isMobile ? 2 : 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.place,
            color: Colors.white,
            size: _isMobile ? 16 : 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Get all markers INCLUDING LABELS
    final allMarkers = <Marker>[];
    allMarkers.addAll(_builtSiteMarkers);
    allMarkers.addAll(_builtManagerMarkers);

    // NEW: Add labels if zoom level is appropriate
    if (_shouldShowLabels()) {
      allMarkers.addAll(_builtSiteLabels);
      allMarkers.addAll(_builtManagerLabels);
    }

    final userMarker = _buildUserLocationMarker();
    if (userMarker != null) allMarkers.add(userMarker);

    final searchMarker = _buildSearchMarker();
    if (searchMarker != null) allMarkers.add(searchMarker);

    LatLng center = widget.initialCenter ?? const LatLng(36.8065, 10.1815);
    double zoom = widget.initialZoom ?? 10;
    if (_sitesSnapshot.isNotEmpty) {
      final first = _sitesSnapshot.first;
      center = LatLng(first.latitude, first.longitude);
      zoom = 12;
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              minZoom: 5,
              maxZoom: 19,
              onMapEvent: (event) {
                double newZoom = event.camera.zoom;
                bool wasVisible = _shouldShowGeofences(_zoom);
                bool nowVisible = _shouldShowGeofences(newZoom);

                // NEW: Check if label visibility changed
                bool wasShowingLabels = _shouldShowLabels();
                _zoom = newZoom;
                bool nowShowingLabels = _shouldShowLabels();

                _viewBounds = event.camera.visibleBounds;

                // Rebuild circles when geofence visibility changes
                if (wasVisible != nowVisible) {
                  _buildCirclesIfNeeded();
                  if (mounted) {
                    setState(() {}); // Update immediately when visibility changes
                  }
                }

                // FIXED: Force marker rebuild when zoom changes significantly
                if (wasShowingLabels != nowShowingLabels || (_zoom - newZoom).abs() > 1.0) {
                  _sitesDataChanged = true;
                  _managersDataChanged = true;
                  // Clear caches to force rebuild
                  _siteMarkerCache.clear();
                  _siteLabelCache.clear();
                  _managerLabelCache.clear(); // NEW: Clear manager label cache
                  _rebuildAllMarkers();
                }

                if (event is MapEventMoveStart) {
                  setState(() => _isMoving = true);
                } else if (event is MapEventMoveEnd) {
                  setState(() => _isMoving = false);
                  // FIXED: Always rebuild markers after movement stops
                  _sitesDataChanged = true;
                  _managersDataChanged = true;
                  _rebuildAllMarkers();
                }
              },
              onTap: (_, point) {
                if (_isMobile) HapticFeedback.selectionClick();
                if (_showSearchResults) {
                  setState(() {
                    _showSearchResults = false;
                  });
                  _searchFocusNode.unfocus();
                }
                widget.onAddSite(context, point);
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                maxZoom: 19,
                keepBuffer: _isMobile ? 1 : 2,
                panBuffer: _isMobile ? 0 : 1,
                userAgentPackageName: 'com.constructionproject.app',
                tileProvider: NetworkTileProvider(),
              ),
              // Only show circles when properly zoomed in
              if (_shouldShowGeofences(_zoom))
                CircleLayer(circles: _builtCircles),
              MarkerLayer(
                markers: _isMoving
                    ? allMarkers.take(_isMobile ? 8 : 15).toList()
                    : allMarkers,
              ),
            ],
          ),
          Positioned(
            top: _isMobile ? 40 : 50,
            left: _isMobile ? 15 : 20,
            right: _isMobile ? 70 : 80,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search places...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearSearch,
                    )
                        : _isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _isMobile ? 15 : 20,
                      vertical: _isMobile ? 12 : 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // PERFECT: Search suggestions appear after 1-second delay
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: _isMobile ? 90 : 105,
              left: _isMobile ? 15 : 20,
              right: _isMobile ? 70 : 80,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(maxHeight: _isMobile ? 250 : 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        leading: Icon(
                          _getIconForType(result.type),
                          color: AppColors.primary,
                          size: _isMobile ? 18 : 20,
                        ),
                        title: Text(
                          result.displayName.split(',').first,
                          style: TextStyle(
                            fontSize: _isMobile ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          result.displayName,
                          style: TextStyle(
                            fontSize: _isMobile ? 11 : 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSearchResult(result),
                        dense: true,
                      );
                    },
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            child: RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution(
                  '© CartoDB, © OpenStreetMap',
                  onTap: () => launchUrl(
                    Uri.parse('https://carto.com/attributions'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          if (_isMoving)
            Positioned(
              top: _isMobile ? 100 : 120,
              right: _isMobile ? 15 : 20,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isMobile ? 6 : 8,
                    vertical: _isMobile ? 3 : 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _isMobile ? 10 : 12,
                        height: _isMobile ? 10 : 12,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: _isMobile ? 4 : 6),
                      Text(
                        'Updating...',
                        style: TextStyle(fontSize: _isMobile ? 10 : 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: _isMobile ? 40 : 50,
            right: _isMobile ? 15 : 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "site_map_fit_bounds_fab",
                  onPressed: _fitToMarkers,
                  tooltip: 'Fit bounds',
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.center_focus_strong,
                    color: Colors.white,
                    size: _isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "site_map_refresh_fab",
                  onPressed: () {
                    if (_isMobile) HapticFeedback.lightImpact();
                    _sitesDataChanged = true;
                    _managersDataChanged = true;
                    _siteMarkerCache.clear();
                    _managerMarkerCache.clear();
                    _siteLabelCache.clear(); // Clear label caches
                    _managerLabelCache.clear(); // Clear labels to force name reload
                    _managerNameCache.clear(); // Clear name cache
                    _pendingNameFetches.clear(); // Clear pending fetches
                    _siteProximityCache.clear();
                    _rebuildAllMarkers();

                    // Restart name fetching
                    _preloadManagerNames();
                  },
                  tooltip: 'Refresh all markers',
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: _isMobile ? 18 : 20,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: _isMobile ? 100 : 120,
            right: _isMobile ? 15 : 20,
            child: FloatingActionButton.small(
              heroTag: "site_map_get_location_fab",
              onPressed: _getCurrentLocation,
              tooltip: 'Get my location',
              backgroundColor: Colors.teal,
              child: _isGettingLocation
                  ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          if (_locationError != null)
            Positioned(
              bottom: _isMobile ? 140 : 160,
              right: _isMobile ? 15 : 20,
              child: Card(
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _locationError!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: _isMobile ? 30 : 40,
            right: _isMobile ? 15 : 20,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isMobile ? 6 : 8,
                vertical: _isMobile ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _shouldShowGeofences(_zoom)
                    ? 'Tap to add • Zoom: ${_zoom.toStringAsFixed(1)} • Managers: ${_managersMap.length} • Geofences visible'
                    : _shouldShowLabels()
                    ? 'Tap to add • Zoom: ${_zoom.toStringAsFixed(1)} • Managers: ${_managersMap.length} • Labels visible (${_builtSiteLabels.length} sites)'
                    : 'Tap to add • Zoom: ${_zoom.toStringAsFixed(1)} • Managers: ${_managersMap.length} • Zoom 8+ for labels',
                style: TextStyle(fontSize: _isMobile ? 10 : 11),
              ),
            ),
          ),
          if (kDebugMode && !_isMobile)
            Positioned(
              bottom: 70,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Sites: ${_builtSiteMarkers.length}\n'
                      'Managers: ${_builtManagerMarkers.length}\n'
                      'Site Labels: ${_builtSiteLabels.length}\n'
                      'Manager Labels: ${_builtManagerLabels.length}\n'
                      'Circles: ${_builtCircles.length}\n'
                      'Zoom: ${_zoom.toStringAsFixed(1)}\n'
                      'Moving: $_isMoving\n'
                      'Show labels: ${_shouldShowLabels()}\n'
                      'Socket Managers: ${_managersMap.length}\n'
                      'Cached Names: ${_managerNameCache.length}\n'
                      'Pending Fetches: ${_pendingNameFetches.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, height: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'road':
      case 'street':
        return Icons.route;
      case 'building':
      case 'house':
        return Icons.business;
      case 'amenity':
        return Icons.place;
      default:
        return Icons.location_on;
    }
  }
}