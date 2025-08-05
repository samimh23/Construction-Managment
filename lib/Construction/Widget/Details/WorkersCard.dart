import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Worker/Models/worker.dart';
import '../../../Worker/Provider/worker_provider.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsPeopleCard extends StatefulWidget {
  final bool isEditing;
  final TextEditingController managerController;
  final String siteId;
  final String? managerId; // Add manager ID parameter

  const SiteDetailsPeopleCard({
    super.key,
    required this.isEditing,
    required this.managerController,
    required this.siteId,
    this.managerId, // Manager ID from the construction site
  });

  @override
  State<SiteDetailsPeopleCard> createState() => _SiteDetailsPeopleCardState();
}

class _SiteDetailsPeopleCardState extends State<SiteDetailsPeopleCard> {
  @override
  void initState() {
    super.initState();
    // Load workers when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().loadWorkersByOwner();
    });
  }

  // Helper method to get manager for this site
  Worker? _getManagerForSite(List<Worker> workers) {
    if (widget.managerId == null || widget.managerId!.isEmpty) {
      return null;
    }

    try {
      return workers.firstWhere(
            (worker) => worker.id == widget.managerId, // Match worker ID with manager ID
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to get regular workers for this site (excluding manager)
  List<Worker> _getWorkersForSite(List<Worker> workers) {
    return workers.where((worker) {
      // Include workers assigned to this site, but exclude the manager
      return worker.assignedSite == widget.siteId &&
          worker.id != widget.managerId;
    }).toList();
  }

  // Helper method to get all workers for this site (including manager)
  List<Worker> _getAllWorkersForSite(List<Worker> workers) {
    return workers.where((worker) => worker.assignedSite == widget.siteId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkerProvider>(
      builder: (context, workerProvider, child) {
        // Show loading state when data is being fetched
        if (workerProvider.isLoading) {
          return _buildLoadingState();
        }

        final manager = _getManagerForSite(workerProvider.workers);
        final siteWorkers = _getWorkersForSite(workerProvider.workers);
        final allSiteWorkers = _getAllWorkersForSite(workerProvider.workers);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManagerSection(manager, workerProvider),
            const SizedBox(height: 20),
            _buildWorkersSection(siteWorkers, workerProvider, allSiteWorkers.length),
          ],
        );
      },
    );
  }

  // Loading state widget
  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manager Section Loading
        _buildLoadingManagerSection(),
        const SizedBox(height: 20),
        // Workers Section Loading
        _buildLoadingWorkersSection(),
      ],
    );
  }

  // Loading skeleton for manager section
  Widget _buildLoadingManagerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Project Manager",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            // ✅ REMOVED: Loading indicator for manager action area
          ],
        ),
        const SizedBox(height: 8),
        // Loading skeleton for manager card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Loading skeleton for avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loading skeleton for name
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Loading skeleton for title
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ REMOVED: Loading skeleton for status indicator
            ],
          ),
        ),
      ],
    );
  }

  // Loading skeleton for workers section
  Widget _buildLoadingWorkersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Site Workers",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            // Loading skeleton for worker count
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Loading skeleton for workers list
        Column(
          children: List.generate(3, (index) => _buildLoadingWorkerItem()),
        ),
      ],
    );
  }

  // Loading skeleton for individual worker item
  Widget _buildLoadingWorkerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Loading skeleton for worker avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading skeleton for worker name
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Loading skeleton for worker details
                Container(
                  width: 100,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // ✅ REMOVED: Loading skeleton for status indicator
        ],
      ),
    );
  }

  Widget _buildManagerSection(Worker? manager, WorkerProvider workerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              "Project Manager",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            Spacer(),
            // ✅ REMOVED: Success indicator when loaded
          ],
        ),
        const SizedBox(height: 8),
        if (widget.isEditing)
          _buildEditablePersonField(
            widget.managerController,
            Icons.supervisor_account_rounded,
            const Color(0xFF10B981),
            "Enter manager name",
          )
        else
          _buildManagerDisplayField(manager, workerProvider),
      ],
    );
  }

  Widget _buildManagerDisplayField(Worker? manager, WorkerProvider workerProvider) {
    if (manager == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6B7280).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.supervisor_account_rounded,
                color: Color(0xFF6B7280),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "No manager assigned",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    "Manager will be assigned externally",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            // ✅ REMOVED: Status dot for no manager state
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.supervisor_account_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${manager.firstName} ${manager.lastName}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  "Project Manager • ${manager.jobTitle ?? 'No Title'}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // ✅ REMOVED: Green status dot for manager
        ],
      ),
    );
  }

  Widget _buildWorkersSection(List<Worker> workers, WorkerProvider workerProvider, int totalWorkers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Site Workers",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                "$totalWorkers total workers",
                key: ValueKey(totalWorkers),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (workers.isEmpty)
          _buildEmptyWorkersState(totalWorkers > 0)
        else
          _buildWorkersList(workers, workerProvider),
      ],
    );
  }

  Widget _buildEmptyWorkersState(bool hasManager) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 32,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(height: 8),
          Text(
            hasManager ? "Only manager assigned" : "No workers assigned",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            hasManager
                ? "Add workers to this construction site"
                : "Add workers to this construction site",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersList(List<Worker> workers, WorkerProvider workerProvider) {
    return Column(
      children: workers.map((worker) => _buildWorkerItem(worker, workerProvider)).toList(),
    );
  }

  Widget _buildWorkerItem(Worker worker, WorkerProvider workerProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF3B82F6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${worker.firstName} ${worker.lastName}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  "${worker.jobTitle ?? 'No Title'} • ${worker.dailyWage ?? 0} TND/day",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // ✅ REMOVED: Worker status dot (active/inactive indicator)
        ],
      ),
    );
  }

  Widget _buildEditablePersonField(
      TextEditingController controller,
      IconData icon,
      Color color,
      String hintText,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: color, size: 20),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}