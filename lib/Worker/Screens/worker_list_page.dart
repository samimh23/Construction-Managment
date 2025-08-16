import 'package:constructionproject/Construction/Provider/ConstructionSite/Provider.dart';
import 'package:constructionproject/Worker/Provider/worker_provider.dart';
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
    final paint = Paint()
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

class _WorkerListPageState extends State<WorkerListPage> with TickerProviderStateMixin {
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

    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            // Compact Header for Web
            _buildWebHeader(context, isDesktop, isTablet),
            // Main Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? 24 : 16),
                ),
                child: Column(
                  children: [
                    // Search and Controls Row
                    _buildSearchAndControls(context, isDesktop),
                    const SizedBox(height: 24),
                    // Workers Content
                    Expanded(
                      child: Consumer<WorkerProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading team members...',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (provider.workers.isEmpty) {
                            return _buildEmptyState();
                          }

                          // Filter workers
                          final filteredWorkers = provider.workers.where((worker) {
                            final matchesSearch = '${worker.firstName} ${worker.lastName}'
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                                worker.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                (worker.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

                            final matchesRole = _selectedRole == 'All' || worker.role == _selectedRole;

                            return matchesSearch && matchesRole;
                          }).toList();

                          if (_isGridView || isDesktop) {
                            return _buildGridView(filteredWorkers, isDesktop, isTablet);
                          } else {
                            return _buildListView(filteredWorkers);
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
    );
  }

  Widget _buildWebHeader(BuildContext context, bool isDesktop, bool isTablet) {
    return Container(
      height: isDesktop ? 120 : 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF06B6D4),
          ],
        ),
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
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : (isTablet ? 24 : 16),
              vertical: 16,
            ),
            child: Row(
              children: [
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Team Members',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Manage your construction workforce',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Statistics Cards (Horizontal on web)
                if (isDesktop || isTablet) _buildHorizontalStats(),
                // Action buttons
                Row(
                  children: [
                    if (isDesktop || isTablet) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateWorkerDialog(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Add Worker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        onPressed: () {
                          context.read<WorkerProvider>().loadWorkersByOwner();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStats() {
    return Consumer<WorkerProvider>(
      builder: (context, provider, child) {
        if (provider.workers.isEmpty) return const SizedBox();

        final totalWorkers = provider.workers.length;
        final activeWorkers = provider.workers.where((w) => w.isActive).length;
        final managers = provider.workers.where((w) => w.role.toLowerCase() == 'manager').length;
        final workers = provider.workers.where((w) => w.role.toLowerCase() == 'worker').length;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              _buildStatCard('Total', totalWorkers.toString(), Icons.people_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Active', activeWorkers.toString(), Icons.check_circle_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Managers', managers.toString(), Icons.supervisor_account_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Workers', workers.toString(), Icons.construction_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndControls(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: isDesktop ? 2 : 3,
          child: Container(
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
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search workers...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Role Filter
        Consumer<WorkerProvider>(
          builder: (context, provider, child) {
            if (provider.workers.isEmpty) return const SizedBox();

            final roles = _getUniqueRoles(provider.workers);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                items: roles.map((role) {
                  final roleColor = role == 'All' ? Colors.grey[600]! : _getRoleColor(role);
                  return DropdownMenuItem(
                    value: role,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (role != 'All') ...[
                          Icon(_getRoleIcon(role), size: 16, color: roleColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          role == 'All' ? 'All Roles' : role.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
        if (isDesktop) ...[
          const SizedBox(width: 16),
          // View Toggle
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
              children: [
                IconButton(
                  icon: Icon(
                    Icons.view_list_rounded,
                    color: !_isGridView ? const Color(0xFF3B82F6) : Colors.grey[400],
                  ),
                  onPressed: () => setState(() => _isGridView = false),
                  tooltip: 'List View',
                ),
                IconButton(
                  icon: Icon(
                    Icons.view_module_rounded,
                    color: _isGridView ? const Color(0xFF3B82F6) : Colors.grey[400],
                  ),
                  onPressed: () => setState(() => _isGridView = true),
                  tooltip: 'Grid View',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No workers found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first team member to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateWorkerDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add First Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<dynamic> workers, bool isDesktop, bool isTablet) {
    int crossAxisCount;
    if (isDesktop) {
      crossAxisCount = 3;
    } else if (isTablet) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.4 : 1.2,
      ),
      itemCount: workers.length,
      itemBuilder: (context, index) {
        return _buildWorkerGridCard(context, workers[index]);
      },
    );
  }

  Widget _buildListView(List<dynamic> workers) {
    return ListView.builder(
      itemCount: workers.length,
      itemBuilder: (context, index) {
        return _buildWorkerListCard(context, workers[index]);
      },
    );
  }

  Widget _buildWorkerGridCard(BuildContext context, dynamic worker) {
    final roleColor = _getRoleColor(worker.role);
    final roleIcon = _getRoleIcon(worker.role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: roleColor.withOpacity(0.2), width: 1.5),
                      ),
                      child: Icon(roleIcon, color: roleColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${worker.firstName} ${worker.lastName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: worker.isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                worker.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: worker.isActive ? Colors.green[700] : Colors.red[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
                // Details
                if (worker.email != null && worker.email!.isNotEmpty)
                  _buildDetailRow(Icons.email_outlined, worker.email!),
                if (worker.phone != null && worker.phone!.isNotEmpty)
                  _buildDetailRow(Icons.phone_outlined, worker.phone!),
                if (worker.dailyWage != null)
                  _buildDetailRow(Icons.attach_money_rounded, 'TND ${worker.dailyWage.toStringAsFixed(2)}'),
                const Spacer(),
                // Quick actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(
                      Icons.edit_outlined,
                      'Edit',
                          () => _showEditWorkerDialog(context, worker),
                    ),
                    _buildQuickActionButton(
                      Icons.link_outlined,
                      'Assign',
                          () => _showAssignWorkerDialog(context, worker.id),
                    ),
                    _buildQuickActionButton(
                      Icons.bar_chart_outlined,
                      'Stats',
                          () => _showWorkerSummaryDialog(
                        context,
                        worker.id,
                        '${worker.firstName} ${worker.lastName}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerListCard(BuildContext context, dynamic worker) {
    final roleColor = _getRoleColor(worker.role);
    final roleIcon = _getRoleIcon(worker.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showWorkerSummaryDialog(
              context,
              worker.id,
              '${worker.firstName} ${worker.lastName}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: roleColor.withOpacity(0.2), width: 1.5),
                  ),
                  child: Icon(roleIcon, color: roleColor, size: 24),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              worker.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: worker.isActive ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            worker.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: worker.isActive ? Colors.green[700] : Colors.red[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (worker.email != null && worker.email!.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                worker.email!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (worker.dailyWage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Daily Wage: TND ${worker.dailyWage.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditWorkerDialog(context, worker);
                        break;
                      case 'assign':
                        _showAssignWorkerDialog(context, worker.id);
                        break;
                      case 'summary':
                        _showWorkerSummaryDialog(
                          context,
                          worker.id,
                          '${worker.firstName} ${worker.lastName}',
                        );
                        break;
                      case 'delete':
                        _showDeleteWorkerDialog(context, worker);
                        break;
                      case 'promote':
                        _promoteWorker(context, worker);
                        break;
                      case 'depromote':
                        _showDepromoteManagerDialog(context, worker);
                        break;
                      case 'credentials':
                        _addCredentials(context, worker);
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> items = [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'assign', child: Row(children: [Icon(Icons.link), SizedBox(width: 8), Text('Assign to Site')])),
                      const PopupMenuItem(value: 'summary', child: Row(children: [Icon(Icons.bar_chart), SizedBox(width: 8), Text('View Summary')])),
                    ];

                    if (worker.role.toLowerCase() == 'worker') {
                      if (worker.email == null || worker.email!.isEmpty) {
                        items.add(const PopupMenuItem(value: 'credentials', child: Row(children: [Icon(Icons.mail_outline), SizedBox(width: 8), Text('Add Credentials')])));
                      } else {
                        items.add(const PopupMenuItem(value: 'promote', child: Row(children: [Icon(Icons.upgrade), SizedBox(width: 8), Text('Promote to Manager')])));
                      }
                    } else if (worker.role.toLowerCase() == 'manager') {
                      items.add(const PopupMenuItem(value: 'depromote', child: Row(children: [Icon(Icons.arrow_downward), SizedBox(width: 8), Text('Depromote to Worker')])));
                    }

                    items.add(const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])));

                    return items;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add the missing methods from your original code
  void _showCreateWorkerDialog(BuildContext context) {
    // Your existing implementation
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create New Worker',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                      // First Name
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          labelText: 'First Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'First name required' : null,
                      ),
                      const SizedBox(height: 12),
                      // Last Name
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          labelText: 'Last Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Last name required' : null,
                      ),
                      const SizedBox(height: 12),
                      // Phone
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_rounded),
                          labelText: 'Phone',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Phone required' : null,
                      ),
                      const SizedBox(height: 12),
                      // Job Title
                      TextFormField(
                        controller: jobTitleController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.work_outline_rounded),
                          labelText: 'Job Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Daily Wage
                      TextFormField(
                        controller: dailyWageController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          labelText: 'Daily Wage (TND)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final num = double.tryParse(val);
                          if (num == null || num <= 0) return 'Enter a valid wage';
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
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
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
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              itemBuilder: (context, site, isSelected) {
                                return ListTile(
                                  leading: Icon(Icons.location_on_outlined, color: Colors.blue),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            selectedItem: selectedSite,
                            validator: (site) => site == null ? 'Site required' : null,
                            onChanged: (site) => setState(() => selectedSite = site),
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
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 148,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: isSubmitting
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => isSubmitting = true);
                      try {
                        await Provider.of<WorkerProvider>(context, listen: false).createWorker(
                          firstName: firstNameController.text.trim(),
                          lastName: lastNameController.text.trim(),
                          phone: phoneController.text.trim(),
                          jobTitle: jobTitleController.text.trim(),
                          siteId: selectedSite.id,
                          dailyWage: double.parse(dailyWageController.text.trim()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Worker created successfully!')),
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
    String? selectedSiteId;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Worker to Site'),
          content: Consumer<SiteProvider>(
            builder: (context, siteProvider, _) {
              if (siteProvider.loading) {
                return const CircularProgressIndicator();
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Site'),
                value: selectedSiteId,
                items: siteProvider.sites.map((site) {
                  return DropdownMenuItem(
                    value: site.id,
                    child: Text(site.name ?? 'No name'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSiteId = value;
                  });
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
              onPressed: () async {
                if (selectedSiteId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a site')),
                  );
                  return;
                }
                try {
                  await Provider.of<WorkerProvider>(context, listen: false)
                      .assignWorkerToSite(workerId, selectedSiteId!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Worker assigned to site!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  final errorMessage = (e is DioException && e.response?.statusCode == 409)
                      ? (e.response?.data?['message'] ?? 'Worker is already assigned to this site')
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

  void _showWorkerSummaryDialog(BuildContext context, String workerId, String workerName) async {
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
        return Consumer<WorkerProvider>(
          builder: (context, provider, _) {
            return AlertDialog(
              title: Text('Attendance Summary: $workerName'),
              content: provider.isSummaryLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.summaryError != null
                  ? Text('Error: ${provider.summaryError}')
                  : provider.dailySummary.isEmpty
                  ? const Text('No attendance records found.')
                  : SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Date         |   Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...provider.dailySummary.map((summary) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(summary.date),
                        Text('${summary.totalHours.toStringAsFixed(2)} h'),
                      ],
                    )),
                    const SizedBox(height: 16),
                    if (provider.isMonthlySalaryLoading)
                      const CircularProgressIndicator()
                    else if (provider.monthlySalaryError != null)
                      Text('Monthly Salary Error: ${provider.monthlySalaryError}', style: TextStyle(color: Colors.red))
                    else if (provider.monthlySalary != null)
                        Column(
                          children: [
                            const Divider(),
                            Text(
                              'Monthly Salary (${provider.monthlySalary!.year}-${provider.monthlySalary!.month.toString().padLeft(2, '0')}):',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Total Hours: ${provider.monthlySalary!.totalHours.toStringAsFixed(2)}'),
                            Text('Full Days: ${provider.monthlySalary!.fullDays.toStringAsFixed(2)}'),
                            Text('Daily Wage: \$${provider.monthlySalary!.dailyWage.toStringAsFixed(2)}'),
                            Text(
                              'Salary: \$${provider.monthlySalary!.salary.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDepromoteManagerDialog(BuildContext context, dynamic worker) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Depromote Manager'),
          content: Text('Are you sure you want to depromote ${worker.firstName} ${worker.lastName} to Worker?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                try {
                  await Provider.of<WorkerProvider>(context, listen: false).depromoteManagerToWorker(worker.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manager depromoted to worker successfully!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
          title: const Text('Delete Worker'),
          content: Text('Are you sure you want to delete ${worker.firstName} ${worker.lastName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await Provider.of<WorkerProvider>(context, listen: false).deleteWorker(worker.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Worker deleted successfully!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
    final jobTitleController = TextEditingController(text: worker.jobTitle ?? '');
    final dailyWageController = TextEditingController(text: worker.dailyWage?.toString() ?? '');
    bool isActive = worker.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Worker'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: jobTitleController,
                      decoration: const InputDecoration(labelText: 'Job Title'),
                    ),
                    TextField(
                      controller: dailyWageController,
                      decoration: const InputDecoration(labelText: 'Daily Wage (TND)'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
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
                  onPressed: () async {
                    try {
                      await Provider.of<WorkerProvider>(context, listen: false).editWorker(
                        workerId: worker.id,
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        phone: phoneController.text,
                        jobTitle: jobTitleController.text,
                        dailyWage: double.tryParse(dailyWageController.text) ?? worker.dailyWage ?? 0,
                        isActive: isActive,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Worker updated successfully!')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
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
      await Provider.of<WorkerProvider>(context, listen: false)
          .promoteWorkerToManager(worker.id, siteId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promoted to manager!')),
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.statusCode == 409) {
        final backendMsg = e.response?.data['message']?.toString() ?? '';
        if (backendMsg.contains('already has a manager')) {
          errorMessage = 'This site already has a manager. Depromote the current manager before promoting another.';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _addCredentials(BuildContext context, dynamic worker) async {
    final cred = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text("Add Credentials"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
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
    if (cred != null && cred['email']!.isNotEmpty && cred['password']!.isNotEmpty) {
      try {
        await Provider.of<WorkerProvider>(context, listen: false)
            .addCredentialsToWorker(worker.id, cred['email']!, cred['password']!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}