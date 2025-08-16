import 'dart:async';
import 'dart:io';

import 'package:constructionproject/Construction/service/nominatim_search_service.dart';
import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
// --- Add geolocator import for location ---
import 'package:geolocator/geolocator.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../screen/ConstructionSite/Details.dart';

class SiteMap extends StatefulWidget {
  final Function(BuildContext, LatLng) onAddSite;
  const SiteMap({super.key, required this.onAddSite});

  @override
  State<SiteMap> createState() => _SiteMapState();
}

class _SiteMapState extends State<SiteMap> with AutomaticKeepAliveClientMixin {
  // Cache only what we need
  final Map<String, Marker> _markerCache = {};
  final Map<String, bool> _siteProximityCache = {};

  // Pre-built widgets (created once, reused)
  late final Widget _greenManagerWidget;
  late final Widget _redManagerWidget;

  // Search-related variables
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _searchDebouncer;

  // Current state - NO provider calls in these
  LatLngBounds? _viewBounds;
  double _zoom = 10.0;
  bool _isMoving = false;

  // Timers
  Timer? _moveTimer;

  // Snapshot data - updated ONLY when providers actually change
  List<dynamic> _sitesSnapshot = [];
  List<ManagerLocation> _managersSnapshot = [];
  bool _dataChanged = false;

  // Built markers - reused until data actually changes
  List<Marker> _builtMarkers = [];
  List<CircleMarker> _builtCircles = [];

  // Provider references to avoid context access after unmount
  SiteProvider? _siteProviderRef;
  ManagerLocationProvider? _managerProviderRef;

  final MapController _mapController = MapController();

  // Mobile performance optimizations
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  late final int _maxMarkersForMobile;
  late final Duration _debounceDelayForMobile;

  // --- Add these variables for user location marker ---
  LatLng? _userLocation;
  bool _isGettingLocation = false;
  String? _locationError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMobileOptimizations();
    _preloadWidgets();
    _setupDataListeners();
    // --- Get current location on init ---
    _getCurrentLocation();
  }

  void _initializeMobileOptimizations() {
    // Reduce marker counts and increase debounce on mobile
    _maxMarkersForMobile = _isMobile ? 25 : 60;
    _debounceDelayForMobile = _isMobile
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 100);
  }

  @override
  void dispose() {
    // Clean up listeners properly
    _siteProviderRef?.removeListener(_onDataChanged);
    _managerProviderRef?.removeListener(_onDataChanged);
    _moveTimer?.cancel();
    _searchDebouncer?.cancel();
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
        width: _isMobile ? 24 : 28, // Smaller on mobile
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
      if (!mounted) return; // Check if still mounted

      // Store provider references
      _siteProviderRef = Provider.of<SiteProvider>(context, listen: false);
      _managerProviderRef = Provider.of<ManagerLocationProvider>(context, listen: false);

      // Take initial snapshot
      _sitesSnapshot = List.from(_siteProviderRef!.sites);
      _managersSnapshot = List.from(_managerProviderRef!.managers);
      _dataChanged = true;

      // Listen for ACTUAL data changes only
      _siteProviderRef!.addListener(_onDataChanged);
      _managerProviderRef!.addListener(_onDataChanged);
    });
  }

  void _onDataChanged() {
    // Check if widget is still mounted before accessing context
    if (!mounted || _siteProviderRef == null || _managerProviderRef == null) {
      return; // Exit early if unmounted
    }

    // Mark data as changed but don't rebuild immediately
    _dataChanged = true;

    // Update snapshots using stored references instead of context
    _sitesSnapshot = List.from(_siteProviderRef!.sites);
    _managersSnapshot = List.from(_managerProviderRef!.managers);

    // Clear caches since data changed
    _markerCache.clear();
    _siteProximityCache.clear();

    // Rebuild only if currently visible and still mounted
    if (mounted && !_isMoving) {
      setState(() {});
    }
  }

  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebouncer = Timer(const Duration(milliseconds: 800), () {
      _performSearch(query.trim());
    });
  }

  bool _isPointVisible(double lat, double lng) {
    if (_viewBounds == null) return true;

    // Slightly larger buffer on mobile for smoother experience
    final buffer = _isMobile ? 0.01 : 0.005;
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

    // Fast approximation
    const double meterPerDegree = 111000;
    final latDiff = (manager.latitude - site.latitude).abs() * meterPerDegree;
    final lngDiff = (manager.longitude - site.longitude).abs() * meterPerDegree;

    final radius = site.geofenceRadius ?? 100.0;
    final isNear = latDiff < radius && lngDiff < radius;

    _siteProximityCache[cacheKey] = isNear;
    return isNear;
  }

  // Helper method to determine if geofences should be shown at current zoom
  bool _shouldShowGeofences() {
    // Show geofences only when zoomed in close (15-20)
    // This is for detailed view when you need to see precise boundaries
    return _zoom >= 15.0 && _zoom <= 20.0;
  }

  void _buildMarkersIfNeeded() {
    // Only rebuild if data changed OR viewport changed significantly
    if (!_dataChanged && _builtMarkers.isNotEmpty) {
      return; // Reuse existing markers
    }

    final markers = <Marker>[];
    final circles = <CircleMarker>[];

    // Mobile-optimized adaptive limits
    final maxMarkers = _isMobile
        ? (_zoom < 10 ? 10 : _zoom < 14 ? 20 : _maxMarkersForMobile)
        : (_zoom < 10 ? 15 : _zoom < 14 ? 30 : 60);

    int markerCount = 0;

    // Build site markers first with distance-based filtering on mobile
    final visibleSites = _isMobile ? _getVisibleSitesSorted() : _sitesSnapshot;

    for (final site in visibleSites) {
      if (markerCount >= maxMarkers) break;
      if (!_isPointVisible(site.latitude, site.longitude)) continue;

      // Site marker with mobile-optimized size
      markers.add(Marker(
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
              ),
              child: Icon(
                Icons.location_city,
                color: Colors.white,
                size: _isMobile ? 10 : 12,
              ),
            ),
          ),
        ),
      ));

      markerCount++;
    }

    // Build geofence circles only when zoomed in close (15-20)
    // Reduce circle complexity on mobile
    if (_shouldShowGeofences() && (!_isMobile || _zoom >= 16)) {
      final maxCircles = _isMobile ? 10 : 20;
      int circleCount = 0;

      for (final site in visibleSites) {
        if (circleCount >= maxCircles) break;
        if (!_isPointVisible(site.latitude, site.longitude)) continue;
        if (site.geofenceRadius == null || site.geofenceRadius! <= 0) continue;

        // Mobile-optimized opacity and border
        final baseOpacity = _isMobile ? 0.2 : (_zoom > 17 ? 0.4 : 0.3);
        final borderOpacity = _isMobile ? 0.5 : (_zoom > 17 ? 0.8 : 0.7);
        final borderWidth = _isMobile ? 1.5 : (_zoom > 17 ? 3.0 : 2.5);

        circles.add(CircleMarker(
          point: LatLng(site.latitude, site.longitude),
          color: AppColors.primary.withOpacity(baseOpacity),
          borderStrokeWidth: borderWidth,
          borderColor: AppColors.primary.withOpacity(borderOpacity),
          radius: site.geofenceRadius!.toDouble(),
        ));

        circleCount++;
      }
    }

    // Build manager markers with mobile optimization
    final visibleManagers = _isMobile ? _getVisibleManagersSorted() : _managersSnapshot;

    for (final manager in visibleManagers) {
      if (markerCount >= maxMarkers) break;
      if (!_isPointVisible(manager.latitude, manager.longitude)) continue;

      // Find assigned site
      dynamic assignedSite;
      try {
        assignedSite = _sitesSnapshot.firstWhere((s) => s.id == manager.siteId);
      } catch (e) {
        assignedSite = null;
      }

      final isOnSite = assignedSite != null && _isManagerNearSite(manager, assignedSite);
      final widget = isOnSite ? _greenManagerWidget : _redManagerWidget;

      markers.add(Marker(
        point: LatLng(manager.latitude, manager.longitude),
        width: _isMobile ? 24 : 28,
        height: _isMobile ? 24 : 28,
        child: GestureDetector(
          onTap: () => _showManagerInfo(manager),
          child: widget,
        ),
      ));
      markerCount++;
    }

    _builtMarkers = markers;
    _builtCircles = circles;
    _dataChanged = false;

    // Haptic feedback on mobile when markers update
    if (_isMobile && markerCount > 0) {
      HapticFeedback.selectionClick();
    }
  }

  // Mobile optimization: Sort sites by distance from center
  List<dynamic> _getVisibleSitesSorted() {
    if (_viewBounds == null) return _sitesSnapshot;

    final center = LatLng(
      (_viewBounds!.north + _viewBounds!.south) / 2,
      (_viewBounds!.east + _viewBounds!.west) / 2,
    );

    final visibleSites = _sitesSnapshot.where((site) =>
        _isPointVisible(site.latitude, site.longitude)
    ).toList();

    // Sort by distance from center (closest first)
    visibleSites.sort((a, b) {
      final distA = _calculateDistance(center, LatLng(a.latitude, a.longitude));
      final distB = _calculateDistance(center, LatLng(b.latitude, b.longitude));
      return distA.compareTo(distB);
    });

    return visibleSites;
  }

  // Mobile optimization: Sort managers by distance from center
  List<ManagerLocation> _getVisibleManagersSorted() {
    if (_viewBounds == null) return _managersSnapshot;

    final center = LatLng(
      (_viewBounds!.north + _viewBounds!.south) / 2,
      (_viewBounds!.east + _viewBounds!.west) / 2,
    );

    final visibleManagers = _managersSnapshot.where((manager) =>
        _isPointVisible(manager.latitude, manager.longitude)
    ).toList();

    // Sort by distance from center (closest first)
    visibleManagers.sort((a, b) {
      final distA = _calculateDistance(center, LatLng(a.latitude, a.longitude));
      final distB = _calculateDistance(center, LatLng(b.latitude, b.longitude));
      return distA.compareTo(distB);
    });

    return visibleManagers;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    final lat1Rad = point1.latitude * (3.14159 / 180);
    final lat2Rad = point2.latitude * (3.14159 / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (3.14159 / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (3.14159 / 180);

    final a = (deltaLat / 2).abs() * (deltaLat / 2).abs() +
        (lat1Rad).abs() * (lat2Rad).abs() *
            (deltaLng / 2).abs() * (deltaLng / 2).abs();

    return 2 * (a.abs());
  }

  Future<void> _handleSiteTap(dynamic site) async {
    // Haptic feedback on mobile
    if (_isMobile) {
      HapticFeedback.lightImpact();
    }

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SiteDetailsScreen(site: site)),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  void _showManagerInfo(ManagerLocation manager) {
    // Haptic feedback on mobile
    if (_isMobile) {
      HapticFeedback.lightImpact();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Manager ${manager.managerId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Site: ${manager.siteId ?? "Unassigned"}'),
            Text('Location: ${manager.latitude.toStringAsFixed(4)}, ${manager.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 8),
            // Show if manager is near their assigned site
            if (manager.siteId != null) ...[
              Builder(
                builder: (context) {
                  try {
                    final assignedSite = _sitesSnapshot.firstWhere((s) => s.id == manager.siteId);
                    final isNear = _isManagerNearSite(manager, assignedSite);
                    return Row(
                      children: [
                        Icon(
                          isNear ? Icons.check_circle : Icons.error,
                          color: isNear ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(isNear ? 'On Site' : 'Off Site'),
                      ],
                    );
                  } catch (e) {
                    return const Text('Site not found');
                  }
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _fitToMarkers() {
    final allPoints = <LatLng>[];
    allPoints.addAll(_sitesSnapshot.map((s) => LatLng(s.latitude, s.longitude)));
    allPoints.addAll(_managersSnapshot.map((m) => LatLng(m.latitude, m.longitude)));
    if (_userLocation != null) {
      allPoints.add(_userLocation!);
    }

    if (allPoints.isNotEmpty) {
      try {
        final bounds = LatLngBounds.fromPoints(allPoints);
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.all(_isMobile ? 30 : 50), // Smaller padding on mobile
        ));
      } catch (e) {
        debugPrint('Fit bounds error: $e');
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    try {
      // Get current map center for better results
      final center = _mapController.camera.center;

      final results = await NominatimSearchService.search(
        query,
        viewbox: center,
        limit: _isMobile ? 5 : 8, // Fewer results on mobile
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _showSearchResults = results.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showSearchResults = false;
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
    _mapController.move(result.position, _isMobile ? 15.0 : 16.0);
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showSearchResults = false;
      _isSearching = false;
    });
  }

  // --- Location fetching method ---
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

      // Optionally move map to user location
      _mapController.move(_userLocation!, _isMobile ? 16.0 : 15.0);
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _isGettingLocation = false;
      });
    }
  }

  // --- Add a user marker builder ---
  Marker? _buildUserLocationMarker() {
    if (_userLocation == null) return null;
    return Marker(
      point: _userLocation!,
      width: _isMobile ? 27 : 32,
      height: _isMobile ? 27 : 32,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: _isMobile ? 2 : 2.5),
        ),
        child: Icon(Icons.my_location, color: Colors.white, size: _isMobile ? 14 : 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Build markers only when needed
    _buildMarkersIfNeeded();

    // Use cached data - NO provider calls in build
    LatLng center = const LatLng(36.8065, 10.1815);
    if (_sitesSnapshot.isNotEmpty) {
      final first = _sitesSnapshot.first;
      center = LatLng(first.latitude, first.longitude);
    }

    // --- Add user location marker to the map ---
    final userMarker = _buildUserLocationMarker();
    final allMarkers = List<Marker>.from(_builtMarkers);
    if (userMarker != null) {
      allMarkers.add(userMarker);
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 10,
              minZoom: 5,
              maxZoom: 19,

              // Mobile-optimized map event handling
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  if (mounted) {
                    setState(() {
                      _isMoving = true;
                    });
                  }
                } else if (event is MapEventMoveEnd) {
                  _moveTimer?.cancel();
                  _moveTimer = Timer(_debounceDelayForMobile, () {
                    if (mounted) {
                      setState(() {
                        _isMoving = false;
                        _viewBounds = event.camera.visibleBounds;
                        final newZoom = event.camera.zoom;
                        final oldZoom = _zoom;

                        // Check if we crossed the geofence visibility threshold (15-20)
                        final wasShowingGeofences = oldZoom >= 15.0 && oldZoom <= 20.0;
                        final nowShowingGeofences = newZoom >= 15.0 && newZoom <= 20.0;

                        // More sensitive threshold on mobile
                        final zoomThreshold = _isMobile ? 0.3 : 0.5;

                        // Force rebuild when crossing the geofence threshold or significant zoom change
                        if (wasShowingGeofences != nowShowingGeofences ||
                            (newZoom - oldZoom).abs() > zoomThreshold) {
                          _dataChanged = true;
                        }

                        _zoom = newZoom;
                      });
                    }
                  });
                } else if (event is MapEventMove) {
                  // Update bounds and zoom immediately during movement
                  _viewBounds = event.camera.visibleBounds;
                  final newZoom = event.camera.zoom;

                  // Check for geofence threshold crossing during movement (15-20)
                  final wasShowingGeofences = _zoom >= 15.0 && _zoom <= 20.0;
                  final nowShowingGeofences = newZoom >= 15.0 && newZoom <= 20.0;

                  if (wasShowingGeofences != nowShowingGeofences) {
                    _dataChanged = true;
                  }

                  _zoom = newZoom;
                }
              },

              onTap: (_, point) {
                // Haptic feedback on mobile
                if (_isMobile) {
                  HapticFeedback.selectionClick();
                }

                // Hide search results when tapping map
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
              // Mobile-optimized tile layer
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                maxZoom: 19,
                keepBuffer: _isMobile ? 1 : 2, // Smaller buffer on mobile
                panBuffer: _isMobile ? 0 : 1,
                userAgentPackageName: 'com.constructionproject.app',
                tileProvider: NetworkTileProvider(),
              ),

              // Show circles only when zoomed in close (15-20)
              if (_shouldShowGeofences())
                CircleLayer(circles: _builtCircles),

              // Mobile-optimized marker rendering
              if (!_isMoving)
                MarkerLayer(markers: allMarkers)
              else
                MarkerLayer(markers: allMarkers.take(_isMobile ? 8 : 15).toList()),
            ],
          ),

          // Mobile-optimized search bar
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

          // Mobile-optimized search results
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

          // Attribution
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

          // Mobile-optimized loading indicator
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
                        'Moving...',
                        style: TextStyle(fontSize: _isMobile ? 10 : 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Mobile-optimized controls
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
                    if (_isMobile) {
                      HapticFeedback.lightImpact();
                    }
                    setState(() {
                      _dataChanged = true; // Force rebuild to refresh circles
                    });
                  },
                  tooltip: 'Refresh geofences',
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

          // --- Add button to get current location ---
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

          // --- Show error if location failed ---
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

          // Mobile-optimized help text
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
                _shouldShowGeofences()
                    ? 'Tap to add • Zoom: ${_zoom.toStringAsFixed(1)} • Geofences visible'
                    : 'Tap to add • Zoom: ${_zoom.toStringAsFixed(1)} • Zoom 15+ for geofences',
                style: TextStyle(fontSize: _isMobile ? 10 : 11),
              ),
            ),
          ),

          // Enhanced debug info (only show on non-mobile in debug mode)
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
                  'Markers: ${allMarkers.length}\n'
                      'Circles: ${_builtCircles.length}\n'
                      'Zoom: ${_zoom.toStringAsFixed(1)}\n'
                      'Sites w/ radius: ${_sitesSnapshot.where((s) => s.geofenceRadius != null && s.geofenceRadius! > 0).length}\n'
                      'Moving: $_isMoving\n'
                      'Show circles: ${_shouldShowGeofences()}\n'
                      'Mobile: $_isMobile',
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