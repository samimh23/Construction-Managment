import 'package:constructionproject/Construction/Model/Constructionsite/ConstructionSiteModel.dart';
import 'package:constructionproject/Construction/Provider/ConstructionSite/Provider.dart';
import 'package:constructionproject/Worker/Provider/worker_provider.dart';
import 'package:constructionproject/Worker/Models/attendence.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Assuming WorkSummary is defined somewhere globally
class WorkSummary {
  final String date;
  final double totalHours;

  WorkSummary({required this.date, required this.totalHours});
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 1;

    const double spacing = 30.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WorkerListPage extends StatefulWidget {
  const WorkerListPage({super.key});

  @override
  State<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends State<WorkerListPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  String _selectedRole = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false; // Toggle between list and grid view

  // Role colors and icons mapping
  final Map<String, Color> _roleColors = {
    'worker': const Color(0xFF10B981),
    'manager': const Color(0xFF3B82F6),
  };

  final Map<String, IconData> _roleIcons = {
    'worker': Icons.construction_rounded,
    'manager': Icons.supervisor_account_rounded,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().loadWorkersByOwner();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    return _roleColors[role.toLowerCase()] ?? const Color(0xFF6B7280);
  }

  IconData _getRoleIcon(String role) {
    return _roleIcons[role.toLowerCase()] ?? Icons.person_rounded;
  }

  List<String> _getUniqueRoles(List<dynamic> workers) {
    final roles = workers.map((worker) => worker.role).toSet().toList();
    roles.sort();
    return ['All', ...roles];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isMobile = screenWidth <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header
            _buildEnhancedHeader(context, isDesktop, isTablet, isMobile),
            // Main Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : (isTablet ? 20 : 16),
                ),
                child: Column(
                  children: [
                    // Enhanced Search and Controls
                    _buildEnhancedSearchAndControls(
                      context,
                      isDesktop,
                      isTablet,
                      isMobile,
                    ),
                    const SizedBox(height: 20),
                    // Workers Content
                    Expanded(
                      child: Consumer<WorkerProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return _buildLoadingState();
                          }

                          if (provider.workers.isEmpty) {
                            return _buildEmptyState();
                          }

                          // Filter workers
                          final filteredWorkers =
                              provider.workers.where((worker) {
                                final matchesSearch =
                                    '${worker.firstName} ${worker.lastName}'
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase()) ||
                                    worker.role.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    (worker.email?.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ??
                                        false);

                                final matchesRole =
                                    _selectedRole == 'All' ||
                                    worker.role == _selectedRole;

                                return matchesSearch && matchesRole;
                              }).toList();

                          if (filteredWorkers.isEmpty) {
                            return _buildNoResultsState();
                          }

                          if (_isGridView || isDesktop) {
                            return _buildEnhancedGridView(
                              filteredWorkers,
                              isDesktop,
                              isTablet,
                              isMobile,
                            );
                          } else {
                            return _buildEnhancedListView(
                              filteredWorkers,
                              isMobile,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button for mobile
      floatingActionButton:
          MediaQuery.of(context).size.width <= 768
              ? FloatingActionButton.extended(
                onPressed: () => _showCreateWorkerDialog(context),
                backgroundColor: const Color(0xFF10B981),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Add Worker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading team members...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No workers match your search',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedRole = 'All';
              });
            },
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Clear Filters'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatus(String workerId) {
    final provider = Provider.of<WorkerProvider>(context);
    final attendance = provider.todayAttendance[workerId];
    final isLoading = provider.isTodayAttendanceLoading[workerId] ?? false;
    final error = provider.todayAttendanceError[workerId];

    if (attendance == null && !isLoading && error == null) {
      provider.fetchTodayAttendance(workerId);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 6),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 6),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 12),
            const SizedBox(width: 4),
            const Flexible(
              child: Text(
                "Error",
                style: TextStyle(color: Colors.red, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (attendance == null) {
      return const SizedBox();
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (attendance.status) {
      case 'Present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Present';
        break;
      case 'Checked Out':
        statusColor = Colors.blue;
        statusIcon = Icons.logout;
        statusText = 'Checked Out';
        break;
      case 'Absent':
      default:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Absent';
        break;
    }

    // If multiple sessions, show expandable view
    if (attendance.hasMultipleSessions) {
      return InkWell(
        onTap:
            () => _showSessionsDialog(
              context,
              attendance,
              statusColor,
              statusIcon,
              statusText,
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$statusText (${attendance.sessions.length} sessions)',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, color: statusColor, size: 12),
            ],
          ),
        ),
      );
    }

    // Single session - show inline
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (attendance.checkIn != null) ...[
            const SizedBox(width: 6),
            Text(
              'IN: ${attendance.checkIn!.hour.toString().padLeft(2, '0')}:${attendance.checkIn!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 9,
                color: statusColor.withOpacity(0.8),
              ),
            ),
          ],
          if (attendance.checkOut != null) ...[
            const SizedBox(width: 4),
            Text(
              'OUT: ${attendance.checkOut!.hour.toString().padLeft(2, '0')}:${attendance.checkOut!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 9,
                color: statusColor.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSessionsDialog(
    BuildContext context,
    Attendance attendance,
    Color statusColor,
    IconData statusIcon,
    String statusText,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text('Today\'s Sessions'),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: $statusText',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...attendance.sessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session ${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (session.checkIn != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.login,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Check In: ${_formatTime(session.checkIn!)}',
                                ),
                              ],
                            ),
                          if (session.checkOut != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Check Out: ${_formatTime(session.checkOut!)}',
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.timelapse,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Still checked in',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEnhancedHeader(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF06B6D4)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: GridPatternPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : (isTablet ? 20 : 16),
                vertical: isMobile ? 16 : 20,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Team Members',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      isMobile ? 24 : (isTablet ? 28 : 32),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Manage your construction workforce',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons for desktop/tablet
                      if (!isMobile) ...[
                        ElevatedButton.icon(
                          onPressed: () => _showCreateWorkerDialog(context),
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 18,
                          ),
                          label: const Text('Add Worker'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              final provider = context.read<WorkerProvider>();
                              await provider.loadWorkersByOwner();
                              provider
                                  .clearTodayAttendance(); // <--- Add this method to WorkerProvider!
                              for (var worker in provider.workers) {
                                provider.fetchTodayAttendance(worker.id);
                              }
                            },
                            tooltip: 'Refresh',
                          ),
                        ),
                      ],
                      // Mobile refresh button
                      if (isMobile) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              context
                                  .read<WorkerProvider>()
                                  .loadWorkersByOwner();
                            },
                            tooltip: 'Refresh',
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Statistics Cards
                  if (!isMobile) ...[
                    const SizedBox(height: 20),
                    _buildHorizontalStats(isTablet),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStats(bool isTablet) {
    return Consumer<WorkerProvider>(
      builder: (context, provider, child) {
        if (provider.workers.isEmpty) return const SizedBox();

        final totalWorkers = provider.workers.length;
        final activeWorkers = provider.workers.where((w) => w.isActive).length;
        final managers =
            provider.workers
                .where((w) => w.role.toLowerCase() == 'manager')
                .length;
        final workers =
            provider.workers
                .where((w) => w.role.toLowerCase() == 'worker')
                .length;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  'Total',
                  totalWorkers.toString(),
                  Icons.people_rounded,
                  isTablet,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Active',
                  activeWorkers.toString(),
                  Icons.check_circle_rounded,
                  isTablet,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Managers',
                  managers.toString(),
                  Icons.supervisor_account_rounded,
                  isTablet,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Workers',
                  workers.toString(),
                  Icons.construction_rounded,
                  isTablet,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 20,
        vertical: isTablet ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 18 : 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isTablet ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSearchAndControls(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Main search and filter row
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: isMobile ? 1 : 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search workers...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: Colors.grey[400],
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Role Filter
              if (!isMobile) ...[
                Consumer<WorkerProvider>(
                  builder: (context, provider, child) {
                    if (provider.workers.isEmpty) return const SizedBox();

                    final roles = _getUniqueRoles(provider.workers);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        underline: const SizedBox(),
                        items:
                            roles.map((role) {
                              final roleColor =
                                  role == 'All'
                                      ? Colors.grey[600]!
                                      : _getRoleColor(role);
                              return DropdownMenuItem(
                                value: role,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (role != 'All') ...[
                                      Icon(
                                        _getRoleIcon(role),
                                        size: 16,
                                        color: roleColor,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      role == 'All'
                                          ? 'All Roles'
                                          : role.toUpperCase(),
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
              ],
              // View Toggle for desktop
              if (isDesktop) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildViewToggleButton(
                        Icons.view_list_rounded,
                        'List View',
                        !_isGridView,
                        () => setState(() => _isGridView = false),
                      ),
                      _buildViewToggleButton(
                        Icons.view_module_rounded,
                        'Grid View',
                        _isGridView,
                        () => setState(() => _isGridView = true),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Mobile filters row
          if (isMobile) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Consumer<WorkerProvider>(
                    builder: (context, provider, child) {
                      if (provider.workers.isEmpty) return const SizedBox();

                      final roles = _getUniqueRoles(provider.workers);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          underline: const SizedBox(),
                          isExpanded: true,
                          items:
                              roles.map((role) {
                                final roleColor =
                                    role == 'All'
                                        ? Colors.grey[600]!
                                        : _getRoleColor(role);
                                return DropdownMenuItem(
                                  value: role,
                                  child: Row(
                                    children: [
                                      if (role != 'All') ...[
                                        Icon(
                                          _getRoleIcon(role),
                                          size: 16,
                                          color: roleColor,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          role == 'All'
                                              ? 'All Roles'
                                              : role.toUpperCase(),
                                          style: TextStyle(
                                            color: roleColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewToggleButton(
                        Icons.view_list_rounded,
                        'List',
                        !_isGridView,
                        () => setState(() => _isGridView = false),
                      ),
                      _buildViewToggleButton(
                        Icons.view_module_rounded,
                        'Grid',
                        _isGridView,
                        () => setState(() => _isGridView = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(
    IconData icon,
    String tooltip,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF3B82F6) : Colors.grey[400],
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No workers found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first team member to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateWorkerDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
            label: const Text('Add First Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGridView(
    List<dynamic> workers,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    int crossAxisCount;
    double childAspectRatio;

    if (isDesktop) {
      crossAxisCount = 3;
      childAspectRatio = 0.85;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 0.9;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.2;
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: workers.length,
      itemBuilder: (context, index) {
        return _buildEnhancedWorkerGridCard(context, workers[index], isMobile);
      },
    );
  }

  Widget _buildEnhancedListView(List<dynamic> workers, bool isMobile) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: workers.length,
      itemBuilder: (context, index) {
        return _buildEnhancedWorkerListCard(context, workers[index], isMobile);
      },
    );
  }

  Widget _buildEnhancedWorkerGridCard(
    BuildContext context,
    dynamic worker,
    bool isMobile,
  ) {
    final roleColor = _getRoleColor(worker.role);
    final roleIcon = _getRoleIcon(worker.role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showWorkerSummaryDialog(
              context,
              worker.id,
              '${worker.firstName} ${worker.lastName}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar and status
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [roleColor.withOpacity(0.8), roleColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: roleColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(roleIcon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${worker.firstName} ${worker.lastName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      worker.isActive
                                          ? Colors.green
                                          : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  worker.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color:
                                        worker.isActive
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Worker Code Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Code: ${worker.workerCode ?? 'No Code'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Assignment Status
                _buildAssignmentStatus(worker),

                const SizedBox(height: 8),

                // Attendance Status
                _buildAttendanceStatus(worker.id),

                const SizedBox(height: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (worker.email != null && worker.email!.isNotEmpty)
                        _buildDetailRow(Icons.email_outlined, worker.email!),
                      if (worker.phone != null && worker.phone!.isNotEmpty)
                        _buildDetailRow(Icons.phone_outlined, worker.phone!),
                      if (worker.dailyWage != null)
                        _buildDetailRow(
                          Icons.attach_money_rounded,
                          'TND ${worker.dailyWage.toStringAsFixed(2)}',
                        ),
                    ],
                  ),
                ),

                // Action buttons
                _buildEnhancedActionButtons(worker, context, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedWorkerListCard(
    BuildContext context,
    dynamic worker,
    bool isMobile,
  ) {
    final roleColor = _getRoleColor(worker.role);
    final roleIcon = _getRoleIcon(worker.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showWorkerSummaryDialog(
              context,
              worker.id,
              '${worker.firstName} ${worker.lastName}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main worker info row
                Row(
                  children: [
                    // Enhanced Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [roleColor.withOpacity(0.8), roleColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: roleColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(roleIcon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${worker.firstName} ${worker.lastName}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      roleColor.withOpacity(0.8),
                                      roleColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  worker.role.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Worker Code
                          Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Code: ${worker.workerCode ?? 'No Code'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color:
                                      worker.isActive
                                          ? Colors.green
                                          : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                worker.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color:
                                      worker.isActive
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (worker.email != null &&
                                  worker.email!.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    worker.email!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (worker.dailyWage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Daily Wage: TND ${worker.dailyWage.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status indicators row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAssignmentStatus(worker),
                    _buildAttendanceStatus(worker.id),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                _buildEnhancedActionButtons(worker, context, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButtons(
    dynamic worker,
    BuildContext context,
    bool isCompact,
  ) {
    if (isCompact) {
      return Column(
        children: [
          // Role-specific button
          if (worker.role.toLowerCase() == 'worker') ...[
            if (worker.email == null || worker.email!.isEmpty)
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  child: const Text(
                    "Add Credentials",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _addCredentials(context, worker),
                ),
              ),
            if (worker.email != null && worker.email!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  child: const Text(
                    "Promote",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _promoteWorker(context, worker),
                ),
              ),
            const SizedBox(height: 8),
          ],
          if (worker.role.toLowerCase() == 'manager') ...[
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                child: const Text(
                  "Depromote",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () => _showDepromoteManagerDialog(context, worker),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Common actions in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactActionButton(
                Icons.edit_outlined,
                'Edit',
                () => _showEditWorkerDialog(context, worker),
              ),
              _buildCompactActionButton(
                Icons.link_outlined,
                'Assign',
                () => _showAssignWorkerDialog(context, worker.id),
              ),
              _buildCompactActionButton(
                Icons.bar_chart_outlined,
                'Stats',
                () => _showWorkerSummaryDialog(
                  context,
                  worker.id,
                  '${worker.firstName} ${worker.lastName}',
                ),
              ),
              _buildCompactActionButton(
                Icons.delete_outline,
                'Delete',
                () => _showDeleteWorkerDialog(context, worker),
              ),
            ],
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Role-specific buttons
            if (worker.role.toLowerCase() == 'worker') ...[
              if (worker.email == null || worker.email!.isEmpty)
                _buildActionButton(
                  icon: Icons.mail_outline,
                  label: "Add Credentials",
                  onPressed: () => _addCredentials(context, worker),
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              if (worker.email != null && worker.email!.isNotEmpty) ...[
                _buildActionButton(
                  icon: Icons.upgrade_rounded,
                  label: "Promote",
                  onPressed: () => _promoteWorker(context, worker),
                  backgroundColor: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
              ],
            ],
            if (worker.role.toLowerCase() == 'manager') ...[
              _buildActionButton(
                icon: Icons.arrow_downward_rounded,
                label: "Depromote",
                onPressed: () => _showDepromoteManagerDialog(context, worker),
                backgroundColor: Colors.orange,
              ),
              const SizedBox(width: 8),
            ],

            // Common action buttons
            _buildIconActionButton(
              Icons.link,
              "Assign",
              () => _showAssignWorkerDialog(context, worker.id),
            ),
            const SizedBox(width: 8),
            _buildIconActionButton(
              Icons.edit,
              "Edit",
              () => _showEditWorkerDialog(context, worker),
            ),
            const SizedBox(width: 8),
            _buildIconActionButton(
              Icons.delete_outline,
              "Delete",
              () => _showDeleteWorkerDialog(context, worker),
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            _buildIconActionButton(
              Icons.bar_chart_rounded,
              "Stats",
              () => _showWorkerSummaryDialog(
                context,
                worker.id,
                '${worker.firstName} ${worker.lastName}',
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildIconActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1) ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color?.withOpacity(0.3) ?? Colors.grey[300]!,
          ),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildCompactActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Assignment Status Widget
  Widget _buildAssignmentStatus(dynamic worker) {
    if (worker.assignedSite != null && worker.assignedSite.isNotEmpty) {
      return Consumer<SiteProvider>(
        builder: (context, siteProvider, child) {
          ConstructionSite? site;
          try {
            site = siteProvider.sites.firstWhere(
              (s) => s.id == worker.assignedSite,
            );
          } catch (e) {
            site = null;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.green[700]),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Assigned: ${site?.name ?? 'Site ${worker.assignedSite.substring(0, 8)}...'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 14, color: Colors.orange[700]),
            const SizedBox(width: 6),
            Text(
              'Not assigned',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      );
    }
  }

  // Keep all your existing dialog methods exactly as they are
  // (_showCreateWorkerDialog, _showAssignWorkerDialog, _showWorkerSummaryDialog, etc.)
  // I'm keeping them unchanged to maintain functionality

  void _showCreateWorkerDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final jobTitleController = TextEditingController();
    final dailyWageController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    dynamic selectedSite;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create New Worker',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          labelText: 'First Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'First name required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          labelText: 'Last Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Last name required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_rounded),
                          labelText: 'Phone',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Phone required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jobTitleController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.work_outline_rounded),
                          labelText: 'Job Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dailyWageController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          labelText: 'Daily Wage (TND)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Required';
                          final num = double.tryParse(val);
                          if (num == null || num <= 0)
                            return 'Enter a valid wage';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Site Dropdown with Search
                      Consumer<SiteProvider>(
                        builder: (context, siteProvider, _) {
                          if (siteProvider.loading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (siteProvider.sites.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No sites available.',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            );
                          }
                          return DropdownSearch<dynamic>(
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText: "Search site...",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              itemBuilder: (context, site, isSelected) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.blue,
                                  ),
                                  title: Text(site.name),
                                );
                              },
                              fit: FlexFit.loose,
                            ),
                            items: siteProvider.sites,
                            itemAsString: (site) => site.name,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Select Site (optional)',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            selectedItem: selectedSite,
                            validator: (_) => null,
                            onChanged:
                                (site) => setState(() => selectedSite = site),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 148,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon:
                        isSubmitting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                            : const Icon(Icons.save_rounded),
                    label: Text(isSubmitting ? 'Saving...' : 'Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                        isSubmitting
                            ? null
                            : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => isSubmitting = true);
                              print(
                                "selectedSite: $selectedSite, selectedSite?.id: ${selectedSite?.id}",
                              );

                              try {
                                await Provider.of<WorkerProvider>(
                                  context,
                                  listen: false,
                                ).createWorker(
                                  firstName: firstNameController.text.trim(),
                                  lastName: lastNameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  jobTitle: jobTitleController.text.trim(),
                                  siteId: selectedSite?.id,
                                  dailyWage: double.parse(
                                    dailyWageController.text.trim(),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Worker created successfully!',
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                setState(() => isSubmitting = false);
                              }
                            },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAssignWorkerDialog(BuildContext context, String workerId) {
    dynamic selectedSite;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              const Text('Assign Worker to Site'),
            ],
          ),
          content: Consumer<SiteProvider>(
            builder: (context, siteProvider, _) {
              if (siteProvider.loading) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (siteProvider.sites.isEmpty) {
                return const Text("No sites available");
              }
              return DropdownSearch<dynamic>(
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search site...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  itemBuilder: (context, site, isSelected) {
                    return ListTile(
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: Colors.blue,
                      ),
                      title: Text(site.name),
                    );
                  },
                  fit: FlexFit.loose,
                ),
                items: siteProvider.sites,
                itemAsString: (site) => site.name,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Select Site',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                selectedItem: selectedSite,
                validator: (site) => site == null ? 'Site required' : null,
                onChanged: (site) {
                  selectedSite = site;
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (selectedSite == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a site')),
                  );
                  return;
                }
                try {
                  await Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).assignWorkerToSite(workerId, selectedSite.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Worker assigned to site!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  final errorMessage =
                      (e is DioException && e.response?.statusCode == 409)
                          ? (e.response?.data?['message'] ??
                              'Worker is already assigned to this site')
                          : e.toString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $errorMessage')),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkerSummaryDialog(
    BuildContext context,
    String workerId,
    String workerName,
  ) async {
    final provider = Provider.of<WorkerProvider>(context, listen: false);
    final now = DateTime.now();
    await provider.fetchDailySummary(workerId: workerId);
    await provider.fetchMonthlySalary(
      workerId: workerId,
      year: now.year,
      month: now.month,
    );

    showDialog(
      context: context,
      builder: (context) {
        final themeColor = const Color(0xFF3B82F6);
        final accentColor = const Color(0xFF10B981);
        final background = const Color(0xFFF8FAFC);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: background,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Attendance Summary',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child:
                        provider.isSummaryLoading
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : provider.summaryError != null
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Error: ${provider.summaryError}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Summary Cards
                                if (provider.monthlySalary != null)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: _statCard(
                                          'Days',
                                          '${provider.monthlySalary!.fullDays.toStringAsFixed(0)}',
                                          Icons.calendar_today_rounded,
                                          Colors.amber,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _statCard(
                                          'Hours',
                                          '${provider.monthlySalary!.totalHours.toStringAsFixed(1)} h',
                                          Icons.schedule_rounded,
                                          themeColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _statCard(
                                          'Salary',
                                          'TND ${provider.monthlySalary!.salary.toStringAsFixed(2)}',
                                          Icons.monetization_on_rounded,
                                          accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 20),
                                // Attendance List
                                if (provider.dailySummary.isEmpty)
                                  Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.event_busy_rounded,
                                            color: Colors.grey[400],
                                            size: 38,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No attendance records found.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  Text(
                                    'Recent Attendance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: provider.dailySummary.length,
                                      separatorBuilder:
                                          (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, idx) {
                                        final summary =
                                            provider.dailySummary[idx];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 18,
                                                color: themeColor.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  summary.date,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: accentColor
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${summary.totalHours.toStringAsFixed(2)} h',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: accentColor,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                // Monthly Salary Section
                                if (provider.isMonthlySalaryLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (provider.monthlySalaryError != null)
                                  Center(
                                    child: Text(
                                      'Monthly Salary Error: ${provider.monthlySalaryError}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else if (provider.monthlySalary != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor.withOpacity(0.1),
                                          accentColor.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.monetization_on_rounded,
                                              color: Color(0xFF10B981),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Monthly Salary',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${provider.monthlySalary!.year}-${provider.monthlySalary!.month.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Salary',
                                              style: TextStyle(
                                                color: themeColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              'TND ${provider.monthlySalary!.salary.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                  ),
                ),
                // Close Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDepromoteManagerDialog(BuildContext context, dynamic worker) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Depromote Manager'),
            ],
          ),
          content: Text(
            'Are you sure you want to depromote ${worker.firstName} ${worker.lastName} to Worker?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                try {
                  await Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).depromoteManagerToWorker(worker.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Manager depromoted to worker successfully!',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Depromote'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteWorkerDialog(BuildContext context, dynamic worker) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text('Delete Worker'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${worker.firstName} ${worker.lastName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                try {
                  await Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).deleteWorker(worker.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Worker deleted successfully!'),
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showEditWorkerDialog(BuildContext context, dynamic worker) {
    final firstNameController = TextEditingController(text: worker.firstName);
    final lastNameController = TextEditingController(text: worker.lastName);
    final phoneController = TextEditingController(text: worker.phone ?? '');
    final jobTitleController = TextEditingController(
      text: worker.jobTitle ?? '',
    );
    final dailyWageController = TextEditingController(
      text: worker.dailyWage?.toString() ?? '',
    );
    bool isActive = worker.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Worker'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: jobTitleController,
                      decoration: InputDecoration(
                        labelText: 'Job Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dailyWageController,
                      decoration: InputDecoration(
                        labelText: 'Daily Wage (TND)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await Provider.of<WorkerProvider>(
                        context,
                        listen: false,
                      ).editWorker(
                        workerId: worker.id,
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        phone: phoneController.text,
                        jobTitle: jobTitleController.text,
                        dailyWage:
                            double.tryParse(dailyWageController.text) ??
                            worker.dailyWage ??
                            0,
                        isActive: isActive,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Worker updated successfully!'),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _promoteWorker(BuildContext context, dynamic worker) async {
    final siteId = worker.assignedSite;
    try {
      await Provider.of<WorkerProvider>(
        context,
        listen: false,
      ).promoteWorkerToManager(worker.id, siteId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Promoted to manager!')));
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.statusCode == 409) {
        final backendMsg = e.response?.data['message']?.toString() ?? '';
        if (backendMsg.contains('already has a manager')) {
          errorMessage =
              'This site already has a manager. Depromote the current manager before promoting another.';
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  void _addCredentials(BuildContext context, dynamic worker) async {
    final cred = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mail_outline, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              const Text("Add Credentials"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'email': emailController.text,
                  'password': passwordController.text,
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    if (cred != null &&
        cred['email']!.isNotEmpty &&
        cred['password']!.isNotEmpty) {
      try {
        await Provider.of<WorkerProvider>(
          context,
          listen: false,
        ).addCredentialsToWorker(worker.id, cred['email']!, cred['password']!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
