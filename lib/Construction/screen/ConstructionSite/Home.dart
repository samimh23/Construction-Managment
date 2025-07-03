import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../Widget/Drawer.dart';
import '../../Widget/SiteMarker.dart';
import 'Details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SiteProvider>().fetchSites());
  }

  void _showAddSiteDialog(BuildContext context, LatLng tappedPoint) {
    final nameController = TextEditingController();
    final adresseController = TextEditingController();
    final geofenceController = TextEditingController();
    final geofenceLatController = TextEditingController(text: tappedPoint.latitude.toString());
    final geofenceLngController = TextEditingController(text: tappedPoint.longitude.toString());
    final ownerController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Construction Site'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Site Name'),
                ),
                TextField(
                  controller: adresseController,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                ),
                TextField(
                  controller: geofenceController,
                  decoration: const InputDecoration(labelText: 'Geofence Radius (meters)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: geofenceLatController,
                  decoration: const InputDecoration(labelText: 'Geofence Center Latitude'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: geofenceLngController,
                  decoration: const InputDecoration(labelText: 'Geofence Center Longitude'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(labelText: 'Owner Mongo ID'),
                ),
                const SizedBox(height: 10),
                Text('Location: ${tappedPoint.latitude.toStringAsFixed(5)}, ${tappedPoint.longitude.toStringAsFixed(5)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final geofenceLat = double.tryParse(geofenceLatController.text) ?? tappedPoint.latitude;
                final geofenceLng = double.tryParse(geofenceLngController.text) ?? tappedPoint.longitude;

                final newSite = ConstructionSite(
                  id: "", // No id for creation, will not be sent in toJson
                  name: nameController.text,
                  adresse: adresseController.text,
                  latitude: tappedPoint.latitude,
                  longitude: tappedPoint.longitude,
                  geofenceRadius: double.tryParse(geofenceController.text),
                  geofenceCenterLat: geofenceLat,
                  geofenceCenterLng: geofenceLng,
                  startDate: null,
                  endDate: null,
                  budget: null,
                  isActive: true,
                  owner: ownerController.text.trim(),
                  manager: null,
                );
                await context.read<SiteProvider>().addSite(newSite);
                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _mapPage(BuildContext context) {
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
                  _showAddSiteDialog(context, point);
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
                      color: Colors.blue.withOpacity(0.2),
                      borderStrokeWidth: 2,
                      borderColor: Colors.blue,
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
            const Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap on the map to add a construction site',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sitesListPage(BuildContext context) {
    return Consumer<SiteProvider>(
      builder: (context, provider, child) {
        return ListView.separated(
          itemCount: provider.sites.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final site = provider.sites[i];
            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: Text(site.name),
              subtitle: Text(site.adresse),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SiteDetailsScreen(site: site),
                  ));
                  provider.fetchSites();
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: selectedTab,
        onSelect: (i) => setState(() => selectedTab = i),
      ),
      appBar: AppBar(title: const Text("Construction Sites")),
      body: selectedTab == 0 ? _mapPage(context) : _sitesListPage(context),
    );
  }
}