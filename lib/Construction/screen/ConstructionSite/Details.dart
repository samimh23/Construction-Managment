import 'package:flutter/material.dart';

import '../../Model/Constructionsite/ConstructionSiteModel.dart';

class SiteDetailsScreen extends StatelessWidget {
  final ConstructionSite site;
  const SiteDetailsScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(site.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.business, color: Colors.blue),
                title: Text(site.name),
                subtitle: Text(site.adresse),
              ),
            ),
            const Divider(height: 32),
            Text("Location: ${site.latitude}, ${site.longitude}"),
            if (site.geofenceRadius != null)
              Text("Geofence radius: ${site.geofenceRadius}"),
            if (site.geofenceCenterLat != null && site.geofenceCenterLng != null)
              Text("Geofence center: ${site.geofenceCenterLat}, ${site.geofenceCenterLng}"),
            if (site.startDate != null)
              Text("Start Date: ${site.startDate}"),
            if (site.endDate != null)
              Text("End Date: ${site.endDate}"),
            if (site.budget != null)
              Text("Budget: ${site.budget}"),
            Text("Active: ${site.isActive}"),
            Text("Owner: ${site.owner}"),
            if (site.manager != null)
              Text("Manager: ${site.manager}"),
          ],
        ),
      ),
    );
  }
}