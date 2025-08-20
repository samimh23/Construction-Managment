import 'package:constructionproject/Worker/Models/worker.dart';
import 'package:constructionproject/Worker/Service/worker_service.dart';
import 'package:flutter/material.dart';

class WorkerProvider with ChangeNotifier {
  final WorkerService workerService;
  List<Worker> workers = [];
  bool isLoading = false;

  List<WorkSummary> dailySummary = [];
  bool isSummaryLoading = false;
  String? summaryError;

  MonthlySalary? monthlySalary;
  bool isMonthlySalaryLoading = false;
  String? monthlySalaryError;

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
    String? siteId,   // <-- make optional
    required double dailyWage,
  }) async {
    await workerService.createWorker(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      jobTitle: jobTitle,
      siteId: siteId,
      dailyWage: dailyWage,
    );
    await loadWorkersByOwner();
  }

  Future<void> editWorker({
    required String workerId,
    String? firstName,
    String? lastName,
    String? phone,
    String? jobTitle,
    double? dailyWage,
    bool? isActive,
  }) async {
    await workerService.editWorker(
      workerId: workerId,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      jobTitle: jobTitle,
      dailyWage: dailyWage,
      isActive: isActive,
    );
    await loadWorkersByOwner();
  }

  Future<void> deleteWorker(String workerId) async {
    await workerService.deleteWorker(workerId: workerId);
    await loadWorkersByOwner();
  }

  Future<void> assignWorkerToSite(String workerId, String siteId) async {
    await workerService.assignWorkerToSite(workerId: workerId, siteId: siteId);
    await loadWorkersByOwner();
  }

  Future<void> fetchDailySummary({
    required String workerId,
    String? from,
    String? to,
  }) async {
    isSummaryLoading = true;
    summaryError = null;
    notifyListeners();
    try {
      dailySummary = await workerService.fetchDailySummary(
        workerId: workerId,
        from: from,
        to: to,
      );
    } catch (e) {
      summaryError = e.toString();
      dailySummary = [];
    } finally {
      isSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> depromoteManagerToWorker(String managerId) async {
    await workerService.depromoteManagerToWorker(managerId: managerId);
    await loadWorkersByOwner();
  }

  Future<void> fetchMonthlySalary({
    required String workerId,
    required int year,
    required int month,
  }) async {
    isMonthlySalaryLoading = true;
    monthlySalaryError = null;
    notifyListeners();
    try {
      monthlySalary = await workerService.fetchMonthlySalary(
        workerId: workerId,
        year: year,
        month: month,
      );
    } catch (e) {
      monthlySalaryError = e.toString();
      monthlySalary = null;
    } finally {
      isMonthlySalaryLoading = false;
      notifyListeners();
    }
  }
}