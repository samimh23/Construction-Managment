import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../Core/Constants/app_colors.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../screen/ConstructionSite/Details.dart';
import '../SiteMarker.dart';


class SiteMap extends StatelessWidget {
  final Function(BuildContext, LatLng) onAddSite;
  const SiteMap({super.key, required this.onAddSite});

  @override
  Widget build(BuildContext context) {
    return Consumer<SiteProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: provider.sites.isNotEmpty
                    ? LatLng(provider.sites[0].latitude, provider.sites[0].longitude)
                    : const LatLng(36.8065, 10.1815),
                zoom: provider.currentZoom,
                minZoom: 5,
                maxZoom: 19,
                onPositionChanged: (MapPosition pos, bool hasGesture) {
                  provider.setZoom(pos.zoom ?? provider.currentZoom);
                },
                onTap: (tapPosition, point) {
                  onAddSite(context, point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                if (provider.currentZoom >= 15)
                  CircleLayer(
                    circles: provider.sites
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
                  markers: provider.sites.map((site) {
                    final isZoomedIn = provider.currentZoom >= 15;
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
                          provider.fetchSites();
                        },
                      ),
                    );
                  }).toList(),
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