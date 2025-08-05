import 'package:constructionproject/Worker/Models/worker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Worker/Provider/worker_provider.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsPeopleCard extends StatefulWidget {
  final bool isEditing;
  final TextEditingController managerController;
  final String siteId;
  final String? managerId;

  const SiteDetailsPeopleCard({
    super.key,
    required this.isEditing,
    required this.managerController,
    required this.siteId,
    this.managerId,
  });

  @override
  State<SiteDetailsPeopleCard> createState() => _SiteDetailsPeopleCardState();
}

class _SiteDetailsPeopleCardState extends State<SiteDetailsPeopleCard> {
  // Cache filtered results to avoid repeated calculations
  Worker? _cachedManager;
  List<Worker> _cachedSiteWorkers = [];
  List<Worker> _cachedAllSiteWorkers = [];
  List<Worker>? _lastWorkersList;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().loadWorkersByOwner();
    });
  }

  // Optimized: Single pass through workers list with caching
  void _updateCachedWorkers(List<Worker> workers) {
    // Only recalculate if workers list changed
    if (_lastWorkersList == workers) return;

    _lastWorkersList = workers;
    _cachedManager = null;
    _cachedSiteWorkers.clear();
    _cachedAllSiteWorkers.clear();

    // Single pass through the list for better performance
    for (final worker in workers) {
      if (worker.assignedSite == widget.siteId) {
        _cachedAllSiteWorkers.add(worker);

        if (worker.id == widget.managerId) {
          _cachedManager = worker;
        } else {
          _cachedSiteWorkers.add(worker);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<WorkerProvider, ({List<Worker> workers, bool isLoading})>(
      selector: (context, provider) => (
      workers: provider.workers,
      isLoading: provider.isLoading,
      ),
      builder: (context, data, child) {
        if (data.isLoading) {
          return _buildOptimizedLoadingState();
        }

        _updateCachedWorkers(data.workers);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManagerSection(_cachedManager),
            const SizedBox(height: 20),
            _buildWorkersSection(_cachedSiteWorkers, _cachedAllSiteWorkers.length),
          ],
        );
      },
    );
  }

  // Simplified and optimized loading state
  Widget _buildOptimizedLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSimpleLoadingSection("Project Manager"),
        const SizedBox(height: 20),
        _buildSimpleLoadingSection("Site Workers"),
      ],
    );
  }

  Widget _buildSimpleLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagerSection(Worker? manager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Project Manager",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
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
          _buildManagerDisplayField(manager),
      ],
    );
  }

  Widget _buildManagerDisplayField(Worker? manager) {
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
        ],
      ),
    );
  }

  Widget _buildWorkersSection(List<Worker> workers, int totalWorkers) {
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
          _buildOptimizedWorkersList(workers),
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

  // Optimized worker list with ListView.builder for large lists
  Widget _buildOptimizedWorkersList(List<Worker> workers) {
    if (workers.length > 10) {
      // Use ListView.builder for better performance with large lists
      return SizedBox(
        height: 300, // Fixed height for scrollable list
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: workers.length,
          itemBuilder: (context, index) => _buildWorkerItem(workers[index]),
        ),
      );
    }

    // Use Column for small lists (better performance for few items)
    return Column(
      children: workers.map(_buildWorkerItem).toList(),
    );
  }

  // Optimized worker item with simplified structure
  Widget _buildWorkerItem(Worker worker) {
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
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
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