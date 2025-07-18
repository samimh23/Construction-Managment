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

  Future<void> addSite(ConstructionSite site) async {
    await _service.addSite(site);
    await fetchSites();
  }

  Future<void> updateSite(ConstructionSite site) async {
    await _service.updateSite(site);
    await fetchSites();
  }

  Future<void> deleteSite(String id) async {
    await _service.deleteSite(id);
    await fetchSites();
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