import 'package:geolocator/geolocator.dart';

import '../../Model/Constructionsite/ConstructionSiteModel.dart';

extension ManagerGeofenceCheck on ConstructionSite {
  bool isManagerInsideGeofence(double lat, double lng) {
    final double centerLat = geofenceCenterLat ?? latitude;
    final double centerLng = geofenceCenterLng ?? longitude;
    final double radius = geofenceRadius ?? 0.0;
    if (radius == 0.0) return false;
    final double distance = Geolocator.distanceBetween(lat, lng, centerLat, centerLng);
    return distance <= radius;
  }
}