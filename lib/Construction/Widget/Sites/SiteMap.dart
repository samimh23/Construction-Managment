import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../Manger/Provider/ManagerLocationProvider.dart';
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
  ManagerLocation? selectedManager;

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
    // Find the assigned site
    final assignedSite = siteProvider.sites.firstWhere(
          (site) => site.id == manager.siteId,
    );
    if (assignedSite == null) return false;
    // Calculate distance between manager location and site's center
    final managerLatLng = LatLng(manager.latitude, manager.longitude);
    final siteCenter = LatLng(
      assignedSite.geofenceCenterLat ?? assignedSite.latitude,
      assignedSite.geofenceCenterLng ?? assignedSite.longitude,
    );
    final distance = Distance().as(
        LengthUnit.Meter, managerLatLng, siteCenter
    );
    // If within geofence radius, manager is on the site
    return assignedSite.geofenceRadius != null && distance <= assignedSite.geofenceRadius!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SiteProvider, ManagerLocationProvider>(
      builder: (context, siteProvider, managerProvider, child) {
        final siteLatLngs = siteProvider.sites.map((site) => LatLng(site.latitude, site.longitude)).toList();
        final managerLatLngs = managerProvider.managers.map((m) => LatLng(m.latitude, m.longitude)).toList();
        final allLatLngs = [...siteLatLngs, ...managerLatLngs];

        LatLngBounds? bounds;
        if (allLatLngs.isNotEmpty) {
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
              options: MapOptions(
                bounds: bounds,
                center: bounds == null
                    ? const LatLng(36.8065, 10.1815)
                    : null,
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
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
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