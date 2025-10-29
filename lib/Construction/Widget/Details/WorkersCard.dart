import 'package:constructionproject/Worker/Models/worker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../Manger/manager_provider/atendence_provider.dart';
import '../../../Worker/Provider/worker_provider.dart';
import '../../../Worker/Screens/worker_list_page.dart';
import '../../../auth/services/auth/auth_service.dart';
import '../../Provider/ConstructionSite/Provider.dart';

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
  List<Worker> _cachedUnassignedWorkers = [];
  List<Worker> _cachedOtherSiteWorkers = [];
  List<Worker>? _lastWorkersList;

  // Loading states
  bool _isDataLoaded = false;

  // Dynamic date formatting
  String get _formattedCurrentDate {
    final now = DateTime.now();
    return DateFormat('MMM dd, yyyy').format(now);
  }

  String get _currentDateForAPI {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Get attendance status for a worker using the provider
  String _getAttendanceStatus(String workerId) {
    final attendanceProvider = context.read<AttendanceProvider>();
    final attendance = attendanceProvider.workerAttendanceCache[workerId];

    if (attendance == null) {
      // Load attendance data if not cached
      _loadWorkerAttendance(workerId);
      return 'Loading...';
    }

    final status = attendance['status'] as String?;
    print('📊 Worker $workerId status from backend: $status (Date: $_currentDateForAPI)');

    // Your backend returns: 'Absent', 'Present', or 'Checked Out'
    switch (status?.toLowerCase()) {
      case 'absent':
        return 'Absent';
      case 'present':
        return 'Present';
      case 'checked out':
        return 'Checked Out';
      default:
        return 'Unknown';
    }
  }

  // Load attendance data for a specific worker using the provider
  Future<void> _loadWorkerAttendance(String workerId) async {
    final attendanceProvider = context.read<AttendanceProvider>();
    print('🔍 Loading attendance for worker $workerId on $_currentDateForAPI');
    await attendanceProvider.getTodayAttendanceForWorker(workerId);
    if (mounted) setState(() {});
  }

  // Load all attendance data for site workers using the provider
  Future<void> _loadAllWorkersAttendance() async {
    print('🔄 Loading attendance for all workers on $_currentDateForAPI...');
    final allWorkers = [..._cachedSiteWorkers];
    if (_cachedManager != null) {
      allWorkers.add(_cachedManager!);
    }

    final workerIds = allWorkers
        .where((worker) => worker.id != null)
        .map((worker) => worker.id!)
        .toList();

    print('📊 Total workers to load attendance for: ${workerIds.length}');

    final attendanceProvider = context.read<AttendanceProvider>();
    await attendanceProvider.refreshAllWorkersAttendance(workerIds);

    if (mounted) setState(() {});
    print('✅ Finished loading attendance for all workers on $_currentDateForAPI');
  }

  // Get attendance color
  Color _getAttendanceColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF10B981); // Green
      case 'checked out':
        return const Color(0xFF3B82F6); // Blue
      case 'absent':
        return const Color(0xFFEF4444); // Red
      case 'loading...':
        return const Color(0xFF6B7280); // Gray for loading
      default:
        return const Color(0xFF6B7280); // Gray for unknown
    }
  }

  // Get attendance icon
  IconData _getAttendanceIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'checked out':
        return Icons.exit_to_app;
      case 'absent':
        return Icons.cancel;
      case 'loading...':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  // Manual attendance refresh using the provider
  Future<void> _refreshAttendanceOnly() async {
    print('🔄 Refreshing attendance data for $_currentDateForAPI...');

    final allWorkers = [..._cachedSiteWorkers];
    if (_cachedManager != null) {
      allWorkers.add(_cachedManager!);
    }

    final workerIds = allWorkers
        .where((worker) => worker.id != null)
        .map((worker) => worker.id!)
        .toList();

    final attendanceProvider = context.read<AttendanceProvider>();
    await attendanceProvider.refreshAllWorkersAttendance(workerIds);

    // Also refresh site-level attendance
    await attendanceProvider.fetchSiteDailyAttendance(widget.siteId);

    if (mounted) setState(() {});
    print('✅ Attendance data refreshed for $_currentDateForAPI');
  }

  // ENHANCED: Load both workers and sites data with proper auth
  Future<void> _loadData() async {
    try {
      print('🔄 Loading workers and site data for $_currentDateForAPI...');

      // Get current user
      AuthService authService = context.read<AuthService>();
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null) {
        print('❌ No current user found');
        _isDataLoaded = true;
        if (mounted) setState(() {});
        return;
      }

      String currentUserId = currentUser.id?.toString() ?? '';

      if (currentUserId.isEmpty) {
        print('❌ Could not extract user ID from current user');
        _isDataLoaded = true;
        if (mounted) setState(() {});
        return;
      }

      print('✅ Current User ID: $currentUserId (Login: ${currentUser.email ?? 'AyariAladine'})');

      // Load workers
      await context.read<WorkerProvider>().loadWorkersByOwner();
      print('✅ Workers loaded');

      // Load sites using your SiteProvider
      await context.read<SiteProvider>().fetchSitesByOwner(currentUserId);
      print('✅ Sites loaded by SiteProvider');

      _isDataLoaded = true;
      if (mounted) setState(() {});

      // Load attendance data for all workers after initial load
      await _loadAllWorkersAttendance();

      // Also load site-level attendance summary
      final attendanceProvider = context.read<AttendanceProvider>();
      await attendanceProvider.fetchSiteDailyAttendance(widget.siteId);

    } catch (e) {
      print('❌ Error loading data: $e');
      _isDataLoaded = true;
      if (mounted) setState(() {});
    }
  }

  // ENHANCED: Refresh all data after operations
  Future<void> _refreshData() async {
    try {
      print('🔄 Refreshing worker data for $_currentDateForAPI...');

      setState(() {
        _isDataLoaded = false;
      });

      // Clear worker caches
      _lastWorkersList = null;
      _cachedManager = null;
      _cachedSiteWorkers.clear();
      _cachedAllSiteWorkers.clear();
      _cachedUnassignedWorkers.clear();
      _cachedOtherSiteWorkers.clear();

      // Clear attendance cache
      final attendanceProvider = context.read<AttendanceProvider>();
      attendanceProvider.clearAttendanceCache();

      // Reload workers from server
      await context.read<WorkerProvider>().loadWorkersByOwner();

      // Force UI update
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }

      // Reload attendance data
      await _loadAllWorkersAttendance();
      await attendanceProvider.fetchSiteDailyAttendance(widget.siteId);

      print('✅ Data refreshed successfully for $_currentDateForAPI');
    } catch (e) {
      print('❌ Error refreshing data: $e');
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }
    }
  }

  // Get site name from ID using SiteProvider
  String _getSiteName(String? siteId) {
    if (siteId == null || siteId.isEmpty) return 'Unassigned';

    try {
      final siteProvider = context.read<SiteProvider>();
      final site = siteProvider.sites.firstWhere(
            (site) => site.id == siteId,
        orElse: () => throw Exception('Site not found'),
      );

      return site.name ?? 'Unnamed Site';
    } catch (e) {
      return 'Site ${siteId.length > 8 ? siteId.substring(0, 8) : siteId}...';
    }
  }

  // Worker categorization logic
  void _updateCachedWorkers(List<Worker> workers) {
    if (_lastWorkersList == workers && (_cachedManager != null || _cachedSiteWorkers.isNotEmpty)) {
      return;
    }

    print('🔍 === WORKER CATEGORIZATION DEBUG ($_currentDateForAPI) ===');
    print('🔍 Total workers: ${workers.length}');
    print('🔍 Site ID: ${widget.siteId}');

    _lastWorkersList = workers;
    _cachedManager = null;
    _cachedSiteWorkers.clear();
    _cachedAllSiteWorkers.clear();
    _cachedUnassignedWorkers.clear();
    _cachedOtherSiteWorkers.clear();

    for (final worker in workers) {
      print('🔍 Worker: ${worker.firstName} ${worker.lastName}');
      print('   - ID: ${worker.id}');
      print('   - Role: ${worker.role}');
      print('   - Assigned Site: ${worker.assignedSite}');

      if (worker.assignedSite == widget.siteId) {
        print('✅ Worker assigned to current site');
        _cachedAllSiteWorkers.add(worker);

        if (_isManager(worker)) {
          print('🎯 MANAGER FOUND: ${worker.firstName} (role: ${worker.role})');
          _cachedManager = worker;
        } else {
          print('➕ WORKER ADDED: ${worker.firstName}');
          _cachedSiteWorkers.add(worker);
        }
      } else if (worker.assignedSite == null || worker.assignedSite!.isEmpty) {
        _cachedUnassignedWorkers.add(worker);
      } else {
        _cachedOtherSiteWorkers.add(worker);
      }
    }

    print('🔍 Final results:');
    print('   - Manager: ${_cachedManager?.firstName ?? 'NONE'} (ID: ${_cachedManager?.id})');
    print('   - Site workers: ${_cachedSiteWorkers.length}');
    print('   - Unassigned: ${_cachedUnassignedWorkers.length}');
    print('   - Other sites: ${_cachedOtherSiteWorkers.length}');
    print('🔍 === END DEBUG ===');
  }

  // Check if worker is a manager
  bool _isManager(Worker worker) {
    final role = worker.role?.toLowerCase()?.trim() ?? '';

    if (role == 'manager' ||
        role == 'construction_manager' ||
        role == 'construction manager' ||
        role == 'site_manager' ||
        role == 'site manager' ||
        role == 'project_manager' ||
        role == 'project manager' ||
        role.contains('manager')) {
      return true;
    }

    if (worker.id == widget.managerId) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkerProvider, SiteProvider, AttendanceProvider>(
      builder: (context, workerProvider, siteProvider, attendanceProvider, child) {
        if (workerProvider.isLoading || siteProvider.loading || !_isDataLoaded) {
          return _buildOptimizedLoadingState();
        }

        _updateCachedWorkers(workerProvider.workers);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManagerSection(_cachedManager),
            const SizedBox(height: 20),
            _buildWorkersSection(_cachedSiteWorkers, _cachedAllSiteWorkers.length),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildAttendanceSummary(attendanceProvider),
          ],
        );
      },
    );
  }

  // Build attendance summary using data from the provider - UPDATED with dynamic date
  Widget _buildAttendanceSummary(AttendanceProvider attendanceProvider) {
    final allWorkers = [..._cachedSiteWorkers];
    if (_cachedManager != null) {
      allWorkers.add(_cachedManager!);
    }

    if (allWorkers.isEmpty) return const SizedBox.shrink();

    int presentCount = 0;
    int checkedOutCount = 0;
    int absentCount = 0;
    int loadingCount = 0;

    // Count attendance status from provider data
    for (final worker in allWorkers) {
      if (worker.id != null) {
        final attendance = attendanceProvider.workerAttendanceCache[worker.id];
        if (attendance == null) {
          loadingCount++;
        } else {
          final status = attendance['status'] as String?;
          switch (status?.toLowerCase()) {
            case 'present':
              presentCount++;
              break;
            case 'checked out':
              checkedOutCount++;
              break;
            case 'absent':
              absentCount++;
              break;
            default:
              loadingCount++;
              break;
          }
        }
      }
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                "Today's Attendance - $_formattedCurrentDate",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _refreshAttendanceOnly,
                child: const Icon(Icons.refresh, size: 18, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAttendanceGrid(presentCount, checkedOutCount, absentCount, loadingCount),
        ],
      ),
    );
  }

  Widget _buildAttendanceGrid(int presentCount, int checkedOutCount, int absentCount, int loadingCount) {
    List<Widget> cards = [];

    // Always show present and absent
    cards.add(
      Expanded(
        child: _buildAttendanceStatCard(
          'Present',
          presentCount,
          const Color(0xFF10B981),
          Icons.check_circle,
        ),
      ),
    );

    if (checkedOutCount > 0) {
      cards.add(const SizedBox(width: 8));
      cards.add(
        Expanded(
          child: _buildAttendanceStatCard(
            'Checked Out',
            checkedOutCount,
            const Color(0xFF3B82F6),
            Icons.exit_to_app,
          ),
        ),
      );
    }

    cards.add(const SizedBox(width: 8));
    cards.add(
      Expanded(
        child: _buildAttendanceStatCard(
          'Absent',
          absentCount,
          const Color(0xFFEF4444),
          Icons.cancel,
        ),
      ),
    );

    if (loadingCount > 0) {
      cards.add(const SizedBox(width: 8));
      cards.add(
        Expanded(
          child: _buildAttendanceStatCard(
            'Loading',
            loadingCount,
            const Color(0xFF6B7280),
            Icons.access_time,
          ),
        ),
      );
    }

    return Row(children: cards);
  }

  Widget _buildAttendanceStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManagerSection(Worker? manager) {
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
            if (manager != null && !widget.isEditing)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                onSelected: (value) {
                  if (value == 'demote') {
                    _showDemoteManagerDialog(manager);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'demote',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Demote to Worker'),
                      ],
                    ),
                  ),
                ],
              ),
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
                    "Promote a worker to manager",
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

    final attendanceStatus = manager.id != null ? _getAttendanceStatus(manager.id!) : 'Unknown';
    final attendanceColor = _getAttendanceColor(attendanceStatus);
    final attendanceIcon = _getAttendanceIcon(attendanceStatus);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'MANAGER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        manager.jobTitle ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Attendance status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: attendanceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: attendanceColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(attendanceIcon, size: 12, color: attendanceColor),
                const SizedBox(width: 4),
                Text(
                  attendanceStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: attendanceColor,
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

  Widget _buildOptimizedWorkersList(List<Worker> workers) {
    if (workers.length > 10) {
      return SizedBox(
        height: 300,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: workers.length,
          itemBuilder: (context, index) => _buildWorkerItem(workers[index]),
        ),
      );
    }

    return Column(
      children: workers.map(_buildWorkerItem).toList(),
    );
  }

  Widget _buildWorkerItem(Worker worker) {
    final attendanceStatus = worker.id != null ? _getAttendanceStatus(worker.id!) : 'Unknown';
    final attendanceColor = _getAttendanceColor(attendanceStatus);
    final attendanceIcon = _getAttendanceIcon(attendanceStatus);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'WORKER',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${worker.jobTitle ?? 'No Title'} • ${worker.dailyWage ?? 0} TND/day",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Attendance status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: attendanceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: attendanceColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(attendanceIcon, size: 10, color: attendanceColor),
                const SizedBox(width: 2),
                Text(
                  attendanceStatus == 'Checked Out' ? 'Out' : attendanceStatus,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: attendanceColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action menu for each worker
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280), size: 18),
            onSelected: (value) {
              if (value == 'promote') {
                _promoteWorker(worker);
              } else if (value == 'delete') {
                _showDeleteWorkerDialog(worker);
              }
            },
            itemBuilder: (BuildContext context) => [
              // Only show promote if worker has email (credentials)
              if (worker.email != null && worker.email!.isNotEmpty)
                const PopupMenuItem<String>(
                  value: 'promote',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Promote to Manager'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Delete Worker'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasAvailableWorkers = _cachedUnassignedWorkers.isNotEmpty || _cachedOtherSiteWorkers.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddWorkerDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasAvailableWorkers ? () => _showAssignWorkerDialog() : null,
            icon: const Icon(Icons.assignment_ind, size: 18),
            label: const Text('Assign Worker'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
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

  // ENHANCED: Add worker dialog with proper refresh
  void _showAddWorkerDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final jobTitleController = TextEditingController();
    final dailyWageController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Add New Worker',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      controller: firstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                      validator: (val) => val == null || val.trim().isEmpty ? 'First name required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                      controller: lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Last name required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Phone required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                      controller: jobTitleController,
                      label: 'Job Title',
                      icon: Icons.work,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Job title required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                      controller: dailyWageController,
                      label: 'Daily Wage (TND)',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Daily wage required';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Enter a valid wage';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                setState(() => isSubmitting = true);

                try {
                  print('🔄 Adding worker on $_currentDateForAPI');
                  await context.read<WorkerProvider>().createWorker(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phoneController.text.trim(),
                    jobTitle: jobTitleController.text.trim(),
                    siteId: widget.siteId,
                    dailyWage: double.parse(dailyWageController.text.trim()),
                  );

                  Navigator.of(ctx).pop();
                  _showSuccessSnackBar('Worker added successfully!');

                  // ADDED: Refresh data after adding worker
                  await _refreshData();

                } catch (e) {
                  _showErrorSnackBar('Failed to add worker: $e');
                } finally {
                  setState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: isSubmitting
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text('Add Worker'),
            ),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Assign worker dialog with mobile-responsive tabs
  void _showAssignWorkerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_ind,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Assign Worker to Site',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // FIXED: Mobile-responsive tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    tabs: [
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_outline, size: 14),
                            const SizedBox(height: 2),
                            Text('Unassigned (${_cachedUnassignedWorkers.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swap_horiz, size: 14),
                            const SizedBox(height: 2),
                            Text('Other Sites (${_cachedOtherSiteWorkers.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      // Unassigned workers tab
                      _buildWorkerAssignList(
                        workers: _cachedUnassignedWorkers,
                        emptyMessage: 'No unassigned workers available',
                        isTransfer: false,
                      ),
                      // Other sites workers tab
                      _buildWorkerAssignList(
                        workers: _cachedOtherSiteWorkers,
                        emptyMessage: 'No workers from other sites available',
                        isTransfer: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER: Build worker assignment list with mobile optimization and REAL site names
  Widget _buildWorkerAssignList({
    required List<Worker> workers,
    required String emptyMessage,
    required bool isTransfer,
  }) {
    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTransfer ? Icons.swap_horiz : Icons.person_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: workers.length,
      itemBuilder: (context, index) {
        final worker = workers[index];
        final siteName = _getSiteName(worker.assignedSite);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIXED: Worker header with mobile-friendly layout
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _isManager(worker)
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFF3B82F6).withOpacity(0.1),
                      child: Icon(
                        _isManager(worker) ? Icons.supervisor_account : Icons.person,
                        color: _isManager(worker)
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${worker.firstName} ${worker.lastName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // FIXED: Role and title row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isManager(worker)
                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                      : const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isManager(worker) ? 'MANAGER' : 'WORKER',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: _isManager(worker)
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  worker.jobTitle ?? 'No Title',
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // FIXED: Mobile-friendly action button
                    ElevatedButton(
                      onPressed: () => _assignWorkerToSite(worker, isTransfer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTransfer ? Colors.orange : const Color(0xFF10B981),
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        isTransfer ? 'Move' : 'Add',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ENHANCED: Real site name display for transfers
                if (isTransfer) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'From: $siteName',
                          style: const TextStyle(fontSize: 10, color: Colors.orange),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '${worker.dailyWage ?? 0} TND/day',
                      style: const TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // FIXED: Assign worker with proper data refresh
  void _assignWorkerToSite(Worker worker, bool isTransfer) async {
    try {
      print('🔄 Assigning worker ${worker.firstName} on $_currentDateForAPI');
      await context.read<WorkerProvider>().assignWorkerToSite(
        worker.id!,
        widget.siteId,
      );

      Navigator.of(context).pop();

      final action = isTransfer ? 'transferred' : 'assigned';
      final workerType = _isManager(worker) ? 'Manager' : 'Worker';
      _showSuccessSnackBar('$workerType $action successfully!');

      // ADDED: Refresh data after assignment
      await _refreshData();

    } catch (e) {
      String errorMessage = 'Failed to assign worker';

      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          errorMessage = e.response?.data?['message'] ?? 'Worker is already assigned to this site';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Worker or site not found';
        } else {
          errorMessage = 'Network error: ${e.response?.statusCode ?? 'Unknown'}';
        }
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // FIXED: Demote manager dialog with proper data refresh and immediate UI update
  void _showDemoteManagerDialog(Worker manager) {
    showDialog(
      context: context,
      builder: (context) {
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Demote Manager'),
            content: Text('Are you sure you want to demote ${manager.firstName} ${manager.lastName} to Worker?'),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: isProcessing ? null : () async {
                  setDialogState(() => isProcessing = true);

                  try {
                    print('🔄 Starting demotion process for manager: ${manager.id} on $_currentDateForAPI');

                    // Perform the demotion
                    await context.read<WorkerProvider>().depromoteManagerToWorker(manager.id!);

                    print('✅ Demotion API call completed');

                    Navigator.pop(context);
                    _showSuccessSnackBar('Manager demoted to worker successfully!');

                    // FORCE immediate refresh - clear all cache first
                    _lastWorkersList = null;
                    _cachedManager = null;
                    _cachedSiteWorkers.clear();
                    _cachedAllSiteWorkers.clear();
                    _cachedUnassignedWorkers.clear();
                    _cachedOtherSiteWorkers.clear();

                    // Clear attendance cache
                    final attendanceProvider = context.read<AttendanceProvider>();
                    attendanceProvider.clearAttendanceCache();

                    // Force immediate UI update
                    if (mounted) {
                      setState(() {
                        _isDataLoaded = false;
                      });
                    }

                    // Refresh data from server
                    await _refreshData();

                    print('✅ Refresh completed after demotion on $_currentDateForAPI');

                  } catch (e) {
                    print('❌ Error during demotion: $e');
                    setDialogState(() => isProcessing = false);
                    _showErrorSnackBar('Error: $e');
                  }
                },
                child: isProcessing
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Demote'),
              ),
            ],
          ),
        );
      },
    );
  }

  // FIXED: Promote worker with data refresh
  void _promoteWorker(Worker worker) async {
    // Check if this site already has a manager
    if (_cachedManager != null) {
      _showErrorSnackBar('This site already has a manager. Demote the current manager first.');
      return;
    }

    final siteId = widget.siteId;
    print('🔄 Promoting worker ${worker.id} to manager of site $siteId on $_currentDateForAPI');

    try {
      await context.read<WorkerProvider>().promoteWorkerToManager(worker.id!, siteId);

      _showSuccessSnackBar('${worker.firstName} ${worker.lastName} promoted to manager!');

      // ADDED: Refresh data after promotion
      await _refreshData();

    } catch (e) {
      print('❌ Promote error: $e');
      String errorMessage = e.toString();
      if (e is DioException && e.response?.statusCode == 409) {
        final backendMsg = e.response?.data['message']?.toString() ?? '';
        if (backendMsg.contains('already has a manager')) {
          errorMessage = 'This site already has a manager. Demote the current manager before promoting another.';
        }
      }
      _showErrorSnackBar('Error: $errorMessage');
    }
  }

  // FIXED: Delete worker dialog with data refresh
  void _showDeleteWorkerDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) {
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Delete Worker'),
            content: Text('Are you sure you want to delete ${worker.firstName} ${worker.lastName}?'),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isProcessing ? null : () async {
                  setDialogState(() => isProcessing = true);

                  try {
                    print('🔄 Deleting worker ${worker.firstName} on $_currentDateForAPI');
                    await context.read<WorkerProvider>().deleteWorker(worker.id!);

                    Navigator.pop(context);
                    _showSuccessSnackBar('Worker deleted successfully!');

                    // ADDED: Refresh data after deletion
                    await _refreshData();

                  } catch (e) {
                    setDialogState(() => isProcessing = false);
                    _showErrorSnackBar('Error: $e');
                  }
                },
                child: isProcessing
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
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