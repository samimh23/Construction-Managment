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
import 'package:geolocator/geolocator.dart';

import '../../Core/Constants/app_colors.dart';
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
  final Map<String, Marker> _markerCache = {};
  final Map<String, bool> _siteProximityCache = {};
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

  List<dynamic> _sitesSnapshot = [];
  List<ManagerLocation> _managersSnapshot = [];
  bool _dataChanged = false;

  List<Marker> _builtMarkers = [];
  List<CircleMarker> _builtCircles = [];

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
      setState(() {
        _dataChanged = true;
      });
    });
  }

  void _initializeMobileOptimizations() {
    _maxMarkersForMobile = _isMobile ? 25 : 60;
    _debounceDelayForMobile =
    _isMobile ? const Duration(milliseconds: 300) : const Duration(milliseconds: 100);
  }

  @override
  void dispose() {
    _siteProviderRef?.removeListener(_onDataChanged);
    _managerProviderRef?.removeListener(_onDataChanged);
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

      _sitesSnapshot = List.from(_siteProviderRef!.sites);
      _managersSnapshot = List.from(_managerProviderRef!.managers);
      _dataChanged = true;

      _siteProviderRef!.addListener(_onDataChanged);
      _managerProviderRef!.addListener(_onDataChanged);
      setState(() {
        _dataChanged = true;
      });
    });
  }

  void _onDataChanged() {
    if (!mounted || _siteProviderRef == null || _managerProviderRef == null) {
      return;
    }
    _dataChanged = true;
    // Only show active sites
    _sitesSnapshot = List.from(_siteProviderRef!.sites.where((site) => site.isActive == true));
    _managersSnapshot = List.from(_managerProviderRef!.managers);

    _markerCache.clear();
    _siteProximityCache.clear();

    if (mounted && !_isMoving) {
      setState(() {});
    }
  }

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
          _dataChanged = true;
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

    const double meterPerDegree = 111000;
    final latDiff = (manager.latitude - site.latitude).abs() * meterPerDegree;
    final lngDiff = (manager.longitude - site.longitude).abs() * meterPerDegree;

    final radius = site.geofenceRadius ?? 100.0;
    final isNear = latDiff < radius && lngDiff < radius;

    _siteProximityCache[cacheKey] = isNear;
    return isNear;
  }

  bool _shouldShowGeofences(double zoomValue) {
    return zoomValue >= 15.0 && zoomValue <= 20.0;
  }

  void _buildMarkersIfNeeded() {
    if (!_dataChanged) return;

    final markers = <Marker>[];
    final circles = <CircleMarker>[];

    final maxMarkers = _isMobile
        ? (_zoom < 10 ? 10 : _zoom < 14 ? 20 : _maxMarkersForMobile)
        : (_zoom < 10 ? 15 : _zoom < 14 ? 30 : 60);

    int markerCount = 0;

    final visibleSites = _sitesSnapshot;

    for (final site in visibleSites) {
      if (markerCount >= maxMarkers) break;
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

    // Add red marker for search result
    if (_searchMarkerPosition != null) {
      markers.add(Marker(
        point: _searchMarkerPosition!,
        width: _isMobile ? 28 : 32,
        height: _isMobile ? 28 : 32,
        child: GestureDetector(
          onTap: () {
            // When user taps the searched marker, call addSite with its coordinates
            widget.onAddSite(context, _searchMarkerPosition!);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: _isMobile ? 2 : 2.5),
            ),
            child: Icon(
              Icons.place,
              color: Colors.white,
              size: _isMobile ? 16 : 18,
            ),
          ),
        ),
      ));
    }

    if (_shouldShowGeofences(_zoom)) {
      final maxCircles = _isMobile ? 10 : 20;
      int circleCount = 0;
      for (final site in visibleSites) {
        if (circleCount >= maxCircles) break;
        if (site.geofenceRadius == null || site.geofenceRadius! <= 0) continue;
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

    _builtMarkers = markers;
    _builtCircles = circles;
    _dataChanged = false;
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
          _showSearchResults = results.isNotEmpty;
          if (results.isNotEmpty) {
            _searchMarkerPosition = results.first.position;
            _mapController.move(_searchMarkerPosition!, _isMobile ? 15.0 : 16.0);
          } else {
            _searchMarkerPosition = null;
          }
          _dataChanged = true;
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
      _searchController.clear();
      _dataChanged = true;
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
      _dataChanged = true;
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

    _buildMarkersIfNeeded();

    LatLng center = widget.initialCenter ?? const LatLng(36.8065, 10.1815);
    double zoom = widget.initialZoom ?? 10;
    if (_sitesSnapshot.isNotEmpty) {
      final first = _sitesSnapshot.first;
      center = LatLng(first.latitude, first.longitude);
      zoom = 12;
    }

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
              initialZoom: zoom,
              minZoom: 5,
              maxZoom: 19,
              onMapEvent: (event) {
                double newZoom = event.camera.zoom;
                bool wasVisible = _shouldShowGeofences(_zoom);
                bool nowVisible = _shouldShowGeofences(newZoom);

                _zoom = newZoom;
                _viewBounds = event.camera.visibleBounds;

                if (wasVisible != nowVisible) {
                  setState(() {
                    _builtCircles = [];
                    _dataChanged = true;
                  });
                }
                setState(() {
                  _dataChanged = true;
                });
                if (event is MapEventMoveStart) setState(() => _isMoving = true);
                if (event is MapEventMoveEnd) setState(() => _isMoving = false);
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
              if (_shouldShowGeofences(_zoom))
                CircleLayer(circles: _builtCircles),
              if (!_isMoving)
                MarkerLayer(markers: allMarkers)
              else
                MarkerLayer(markers: allMarkers.take(_isMobile ? 8 : 15).toList()),
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
                        'Moving...',
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
                    setState(() {
                      _dataChanged = true;
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
                    ? 'Tap to add • Zoom: ${_zoom.toStringAsFixed(1)} • Geofences visible'
                    : 'Tap to add • Zoom: ${_zoom.toStringAsFixed(1)} • Zoom 15+ for geofences',
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
                  'Markers: ${allMarkers.length}\n'
                      'Circles: ${_builtCircles.length}\n'
                      'Zoom: ${_zoom.toStringAsFixed(1)}\n'
                      'Sites w/ radius: ${_sitesSnapshot.where((s) => s.geofenceRadius != null && s.geofenceRadius! > 0).length}\n'
                      'Moving: $_isMoving\n'
                      'Show circles: ${_shouldShowGeofences(_zoom)}\n'
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