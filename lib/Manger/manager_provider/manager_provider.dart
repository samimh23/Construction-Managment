import 'package:flutter/material.dart';
import '../../Construction/Model/Constructionsite/ConstructionSiteModel.dart';
import '../Service/manager_service.dart';

class ManagerDataProvider extends ChangeNotifier {
  final ManagerService managerService;
  ConstructionSite? site;
  List<Map<String, dynamic>> workers = [];
  bool isLoading = false;
  String? error;

  ManagerDataProvider(this.managerService);

  Future<void> loadSiteAndWorkers() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await managerService.fetchSiteAndWorkers();
      if (data['site'] != null) {
        site = ConstructionSite.fromJson(data['site']);
      }
      if (data['workers'] != null) {
        workers = List<Map<String, dynamic>>.from(data['workers']);
      }
    } catch (e) {
      error = 'Failed to load data';
    }

    isLoading = false;
    notifyListeners();
  }
}