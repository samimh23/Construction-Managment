class ConstructionSite {
  final String id;
  final String name;
  final String adresse;
  final double latitude;
  final double longitude;
  final double? geofenceRadius;
  final double? geofenceCenterLat;
  final double? geofenceCenterLng;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? budget;
  final bool isActive;
  final String owner;
  final String? manager;

  ConstructionSite({
    required this.id,
    required this.name,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    this.geofenceRadius,
    this.geofenceCenterLat,
    this.geofenceCenterLng,
    this.startDate,
    this.endDate,
    this.budget,
    required this.isActive,
    required this.owner,
    this.manager,
  });

  factory ConstructionSite.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return ConstructionSite(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      adresse: json['adresse'] ?? '',
      latitude: parseDouble(json['GeoLocation']?['Latitude']) ?? 0.0,
      longitude: parseDouble(json['GeoLocation']?['longitude']) ?? 0.0,
      geofenceRadius: parseDouble(json['GeoFence']?['radius']),
      geofenceCenterLat: parseDouble(json['GeoFence']?['center']?['Latitude']),
      geofenceCenterLng: parseDouble(json['GeoFence']?['center']?['longitude']),
      startDate: json['StartDate'] != null ? DateTime.tryParse(json['StartDate']) : null,
      endDate: json['EndDate'] != null ? DateTime.tryParse(json['EndDate']) : null,
      budget: json['Budget']?.toString(),
      isActive: json['isActive'] == true,
      owner: json['owner']?.toString() ?? '',
      manager: json['manager']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "adresse": adresse,
    "GeoLocation": {
      "longitude": longitude.toString(),
      "Latitude": latitude.toString(),
    },
    "GeoFence": {
      "center": {
        "longitude": geofenceCenterLng?.toString() ?? longitude.toString(),
        "Latitude": geofenceCenterLat?.toString() ?? latitude.toString(),
      },
      "radius": geofenceRadius?.toString() ?? "",
    },
    "StartDate": startDate?.toIso8601String(),
    "EndDate": endDate?.toIso8601String(),
    "Budget": budget,
    "isActive": isActive,
    "owner": owner,
    "manager": manager,
  };

  ConstructionSite copyWith({
    String? id,
    String? name,
    String? adresse,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
    double? geofenceCenterLat,
    double? geofenceCenterLng,
    DateTime? startDate,
    DateTime? endDate,
    String? budget,
    bool? isActive,
    String? owner,
    String? manager,
  }) =>
      ConstructionSite(
        id: id ?? this.id,
        name: name ?? this.name,
        adresse: adresse ?? this.adresse,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        geofenceRadius: geofenceRadius ?? this.geofenceRadius,
        geofenceCenterLat: geofenceCenterLat ?? this.geofenceCenterLat,
        geofenceCenterLng: geofenceCenterLng ?? this.geofenceCenterLng,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        budget: budget ?? this.budget,
        isActive: isActive ?? this.isActive,
        owner: owner ?? this.owner,
        manager: manager ?? this.manager,
      );
}