import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../Manger/manager_provider/ManagerLocationProvider.dart';
import '../../Core/Constants/app_colors.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../screen/ConstructionSite/Details.dart';
import '../SiteMarker.dart';

class SiteMap extends StatefulWidget {
  final Function(BuildContext, LatLng) onAddSite;
  const SiteMap({super.key, required this.onAddSite});

  @override
  State<SiteMap> createState() => _SiteMapState();
}

class _SiteMapState extends State<SiteMap> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  LatLng? _searchedLatLng;
  Timer? _debounce;
  bool _isLoading = false;

  void _showManagerInfo(ManagerLocation manager) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Manager Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${manager.managerId}'),
            Text('Site: ${manager.siteId ?? "Unknown"}'),
            Text('Latitude: ${manager.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${manager.longitude.toStringAsFixed(6)}'),
            if (manager.timestamp != null)
              Text('Time: ${manager.timestamp}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isManagerOnAssignedSite(ManagerLocation manager, SiteProvider siteProvider) {
    final assignedSite = siteProvider.sites.firstWhere(
          (site) => site.id == manager.siteId,
    
    );
    if (assignedSite == null) return false;
    final managerLatLng = LatLng(manager.latitude, manager.longitude);
    final siteCenter = LatLng(
      assignedSite.geofenceCenterLat ?? assignedSite.latitude,
      assignedSite.geofenceCenterLng ?? assignedSite.longitude,
    );
    final distance = Distance().as(
        LengthUnit.Meter, managerLatLng, siteCenter
    );
    return assignedSite.geofenceRadius != null && distance <= assignedSite.geofenceRadius!;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlace(query);
    });
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5');
    final response = await http.get(url, headers: {
      'User-Agent': 'YourApp (your@email.com)'
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SiteProvider, ManagerLocationProvider>(
      builder: (context, siteProvider, managerProvider, child) {
        final siteLatLngs = siteProvider.sites.map((site) => LatLng(site.latitude, site.longitude)).toList();
        final managerLatLngs = managerProvider.managers.map((m) => LatLng(m.latitude, m.longitude)).toList();
        final allLatLngs = [...siteLatLngs, ...managerLatLngs];

        LatLngBounds? bounds;
        if (_searchedLatLng != null) {
          bounds = LatLngBounds.fromPoints([_searchedLatLng!]);
        } else if (allLatLngs.isNotEmpty) {
          bounds = LatLngBounds.fromPoints(allLatLngs);
        }

        final managerMarkers = managerProvider.managers.map((loc) {
          final isOnSite = _isManagerOnAssignedSite(loc, siteProvider);
          final markerColor = isOnSite ? Colors.green : Colors.red;

          return Marker(
            point: LatLng(loc.latitude, loc.longitude),
            width: 44,
            height: 62,
            child: GestureDetector(
              onTap: () => _showManagerInfo(loc),
              child: SizedBox(
                width: 44,
                height: 62,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: markerColor, width: 3),
                        boxShadow: [BoxShadow(blurRadius: 4, color: markerColor.withOpacity(0.3))],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.manage_accounts, color: markerColor, size: 28),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manager',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: markerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList();

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                bounds: bounds,
                center: _searchedLatLng ?? (bounds == null
                    ? const LatLng(36.8065, 10.1815)
                    : null),
                zoom: siteProvider.currentZoom,
                minZoom: 5,
                maxZoom: 19,
                onPositionChanged: (MapPosition pos, bool hasGesture) {
                  siteProvider.setZoom(pos.zoom ?? siteProvider.currentZoom);
                },
                onTap: (tapPosition, point) {
                  widget.onAddSite(context, point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.constructionproject',
                ),
                if (siteProvider.currentZoom >= 15)
                  CircleLayer(
                    circles: siteProvider.sites
                        .where((site) => site.geofenceRadius != null)
                        .map((site) => CircleMarker(
                      point: LatLng(
                        site.geofenceCenterLat ?? site.latitude,
                        site.geofenceCenterLng ?? site.longitude,
                      ),
                      color: AppColors.primary.withOpacity(0.2),
                      borderStrokeWidth: 2,
                      borderColor: AppColors.primary,
                      radius: site.geofenceRadius!,
                    ))
                        .toList(),
                  ),
                MarkerLayer(
                  markers: [
                    if (_searchedLatLng != null)
                      Marker(
                        point: _searchedLatLng!,
                        width: 30,
                        height: 30,
                        child: Icon(Icons.location_on, color: Colors.purple, size: 30),
                      ),
                    ...siteProvider.sites.map((site) {
                      final isZoomedIn = siteProvider.currentZoom >= 15;
                      return Marker(
                        point: LatLng(site.latitude, site.longitude),
                        width: 40,
                        height: 40,
                        child: SiteMarker(
                          site: site,
                          isZoomedIn: isZoomedIn,
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => SiteDetailsScreen(site: site),
                            ));
                            siteProvider.fetchSites();
                          },
                        ),
                      );
                    }),
                    ...managerMarkers,
                  ],
                ),
              ],
            ),
            Positioned(
              top: 32,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search for a place...",
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchResults.clear();
                              _searchedLatLng = null;
                            });
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: (v) => _searchPlace(v),
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(),
                    ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: 180),
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(blurRadius: 4, color: Colors.black12),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, idx) {
                          final item = _searchResults[idx];
                          final displayName = item['display_name'] ?? '';
                          return ListTile(
                            title: Text(displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              final lat = double.parse(item['lat']);
                              final lon = double.parse(item['lon']);
                              setState(() {
                                _searchedLatLng = LatLng(lat, lon);
                                _searchController.text = displayName;
                                _searchResults.clear();
                              });
                              _mapController.move(LatLng(lat, lon), 16.0);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black12)],
                ),
                child: Text(
                  'Tap map to add site',
                  style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}