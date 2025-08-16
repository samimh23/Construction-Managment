import 'package:flutter/material.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../service/ConstructionSiteService.dart';

class SiteProvider extends ChangeNotifier {
  final SiteService _service;
  List<ConstructionSite> _sites = [];
  bool _loading = false;

  double _currentZoom = 12;
  String? _hoveredSiteId;
  bool _showTooltip = false;

  SiteProvider(this._service);

  List<ConstructionSite> get sites => _sites;
  bool get loading => _loading;
  double get currentZoom => _currentZoom;
  String? get hoveredSiteId => _hoveredSiteId;
  bool get showTooltip => _showTooltip;

  /// Get all sites (not owner-filtered)
  Future<void> fetchSites() async {
    _loading = true;
    notifyListeners();
    try {
      _sites = await _service.fetchSites();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get sites by owner
  Future<void> fetchSitesByOwner(String ownerId) async {
    _loading = true;
    notifyListeners();
    try {

      _sites = await _service.fetchSitesByOwner(ownerId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Add a site, then refresh by owner
  Future<void> addSite(ConstructionSite site, String ownerId) async {
    await _service.addSite(site);
    await fetchSitesByOwner(ownerId);
  }

  /// Update a site, then refresh by owner
  Future<void> updateSite(ConstructionSite site, String ownerId) async {
    await _service.updateSite(site);
    await fetchSitesByOwner(ownerId);
  }

  /// Delete a site, then refresh by owner
  Future<void> deleteSite(String id, String ownerId) async {
    await _service.deleteSite(id);
    await fetchSitesByOwner(ownerId);
  }

  void setZoom(double zoom) {
    _currentZoom = zoom;
    notifyListeners();
  }

  void setHoveredSite(String? siteId, bool show) {
    _hoveredSiteId = siteId;
    _showTooltip = show;
    notifyListeners();
  }
}
