import 'package:constructionproject/Worker/Models/worker.dart';
import 'package:constructionproject/Worker/Service/worker_service.dart';
import 'package:flutter/material.dart';

class WorkerProvider with ChangeNotifier {
  final WorkerService workerService;
  List<Worker> workers = [];
  bool isLoading = false;

  WorkerProvider(this.workerService);

  Future<void> loadWorkersByOwner() async {
    isLoading = true;
    notifyListeners();
    try {
      workers = await workerService.fetchWorkersByOwner();
    } catch (e, st) {
      print("Error in loadWorkersByOwner: $e\n$st");
      workers = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> promoteWorkerToManager(String workerId, String siteId) async {
    await workerService.promoteWorkerToManager(workerId: workerId, siteId: siteId);
    await loadWorkersByOwner();
  }

  Future<void> addCredentialsToWorker(String workerId, String email, String password) async {
    await workerService.addCredentialsToWorker(workerId: workerId, email: email, password: password);
    await loadWorkersByOwner();
  }

  Future<void> createWorker({
    required String firstName,
    required String lastName,
    required String phone,
    required String jobTitle,
    required String siteId,
  }) async {
    await workerService.createWorker(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      jobTitle: jobTitle,
      siteId: siteId,
    );
    await loadWorkersByOwner();
  }

  Future<void> assignWorkerToSite(String workerId, String siteId) async {
    await workerService.assignWorkerToSite(workerId: workerId, siteId: siteId);
    await loadWorkersByOwner(); // Optionally refresh the list
  }

}
