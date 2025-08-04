import 'dart:async';

import 'package:constructionproject/Construction/service/nominatim_search_service.dart';
import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _preloadWidgets();
    _setupDataListeners();
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 14),
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
    return lat >= _viewBounds!.south - 0.005 &&
        lat <= _viewBounds!.north + 0.005 &&
        lng >= _viewBounds!.west - 0.005 &&
        lng <= _viewBounds!.east + 0.005;
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

  void _buildMarkersIfNeeded() {
    // Only rebuild if data changed OR viewport changed significantly
    if (!_dataChanged && _builtMarkers.isNotEmpty) {
      return; // Reuse existing markers
    }

    final markers = <Marker>[];
    final circles = <CircleMarker>[];

    // Adaptive limits based on zoom
    final maxMarkers = _zoom < 10 ? 15 : _zoom < 14 ? 30 : 60;
    int markerCount = 0;

    // Build site markers first
    for (final site in _sitesSnapshot) {
      if (markerCount >= maxMarkers) break;
      if (!_isPointVisible(site.latitude, site.longitude)) continue;

      // Site marker
      markers.add(Marker(
        point: LatLng(site.latitude, site.longitude),
        width: 24,
        height: 24,
        child: GestureDetector(
          onTap: () => _handleSiteTap(site),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.location_city, color: Colors.white, size: 12),
          ),
        ),
      ));

      markerCount++;
    }

    // Build geofence circles ONLY at zoom 8 and above
    if (_zoom >= 8) {
      for (final site in _sitesSnapshot) {
        if (!_isPointVisible(site.latitude, site.longitude)) continue;
        if (site.geofenceRadius == null || site.geofenceRadius! <= 0) continue;

        // Higher opacity since we only show at high zoom
        final baseOpacity = 0.3;
        final borderOpacity = 0.7;
        final borderWidth = 2.5;

        circles.add(CircleMarker(
          point: LatLng(site.latitude, site.longitude),
          color: AppColors.primary.withOpacity(baseOpacity),
          borderStrokeWidth: borderWidth,
          borderColor: AppColors.primary.withOpacity(borderOpacity),
          radius: site.geofenceRadius!.toDouble(),
        ));

        // Debug print for geofence circles
        if (kDebugMode) {
          print('Added geofence circle for site ${site.id}: radius=${site.geofenceRadius}, zoom=$_zoom');
        }
      }
    }

    // Build manager markers
    for (final manager in _managersSnapshot) {
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
        width: 28,
        height: 28,
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

    // Debug output
    if (kDebugMode) {
      final sitesWithRadius = _sitesSnapshot.where((s) => s.geofenceRadius != null && s.geofenceRadius! > 0).length;
      print('Built ${circles.length} circles from $sitesWithRadius sites with radius at zoom $_zoom (showing circles: ${_zoom >= 8})');
    }
  }

  Future<void> _handleSiteTap(dynamic site) async {
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

    if (allPoints.isNotEmpty) {
      try {
        final bounds = LatLngBounds.fromPoints(allPoints);
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
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
        limit: 8,
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
    _mapController.move(result.position, 16.0);
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

              // Fixed map event handling
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  if (mounted) {
                    setState(() {
                      _isMoving = true;
                    });
                  }
                } else if (event is MapEventMoveEnd) {
                  _moveTimer?.cancel();
                  _moveTimer = Timer(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        _isMoving = false;
                        _viewBounds = event.camera.visibleBounds;
                        final newZoom = event.camera.zoom;

                        // More sensitive around the 13.4 threshold
                        if ((_zoom - newZoom).abs() > 0.1 ||
                            (_zoom < 13.4 && newZoom >= 13.4) ||
                            (_zoom >= 13.4 && newZoom < 13.4)) {
                          _zoom = newZoom;
                          _dataChanged = true; // Force rebuild when crossing the threshold
                        } else {
                          _zoom = newZoom;
                        }
                      });
                    }
                  });
                } else if (event is MapEventMove) {
                  // Update bounds and zoom immediately during movement
                  _viewBounds = event.camera.visibleBounds;
                  _zoom = event.camera.zoom;
                }
              },

              onTap: (_, point) {
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
              // Use CartoDB for better performance than OSM
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                maxZoom: 19,
                keepBuffer: 2,
                panBuffer: 1,
                userAgentPackageName: 'com.constructionproject.app',
              ),

              // Show circles only when zoom >= 8
              if (_zoom >= 8)
                CircleLayer(circles: _builtCircles),

              // Use pre-built markers
              if (!_isMoving)
                MarkerLayer(markers: _builtMarkers)
              else
              // Show simplified markers during movement for performance
                MarkerLayer(markers: _builtMarkers.take(15).toList()),
            ],
          ),

          // Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 80,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // Search Results
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: 105,
              left: 20,
              right: 80,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
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
                          size: 20,
                        ),
                        title: Text(
                          result.displayName.split(',').first,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          result.displayName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

          // Loading indicator
          if (_isMoving)
            Positioned(
              top: 120,
              right: 20,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 6),
                      Text('Moving...', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),

          // Controls
          Positioned(
            top: 50,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "site_map_fit_bounds_fab",
                  onPressed: _fitToMarkers,
                  tooltip: 'Fit bounds',
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.center_focus_strong, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "site_map_refresh_fab",
                  onPressed: () {
                    setState(() {
                      _dataChanged = true; // Force rebuild to refresh circles
                    });
                  },
                  tooltip: 'Refresh geofences',
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),

          // Help text with geofence visibility info
          Positioned(
            bottom: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _zoom >= 8
                    ? 'Tap to add site • Zoom: ${_zoom.toStringAsFixed(1)} • Geofences visible'
                    : 'Tap to add site • Zoom: ${_zoom.toStringAsFixed(1)} • Zoom to 8+ for geofences',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),

          // Enhanced debug info
          if (kDebugMode)
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
                  'Markers: ${_builtMarkers.length}\n'
                      'Circles: ${_builtCircles.length}\n'
                      'Zoom: ${_zoom.toStringAsFixed(1)}\n'
                      'Sites w/ radius: ${_sitesSnapshot.where((s) => s.geofenceRadius != null && s.geofenceRadius! > 0).length}\n'
                      'Moving: $_isMoving\n'
                      'Show circles: ${_zoom >= 8}',
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