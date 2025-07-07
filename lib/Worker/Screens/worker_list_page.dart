import 'package:constructionproject/Construction/Provider/ConstructionSite/Provider.dart';
import 'package:constructionproject/Worker/Provider/worker_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // Controllers for create worker form are now local to the dialog
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
      // Also trigger fetching sites for dropdown if not loaded
      context.read<SiteProvider>().fetchSites();
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

  void _showCreateWorkerDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final jobTitleController = TextEditingController();
    String? selectedSiteId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Worker'),
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
                Consumer<SiteProvider>(
                  builder: (context, siteProvider, _) {
                    if (siteProvider.loading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (siteProvider.sites.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No sites available.'),
                      );
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
                if (selectedSiteId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a site')),
                  );
                  return;
                }
                try {
                  await Provider.of<WorkerProvider>(context, listen: false).createWorker(
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    phone: phoneController.text,
                    jobTitle: jobTitleController.text,
                    siteId: selectedSiteId!,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Worker created successfully!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Statistics
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60"><g fill-rule="evenodd"><g fill="%23ffffff" fill-opacity="0.1"><polygon points="36,34 6,34 6,4 36,4"/></g></g></svg>'),
                              repeat: ImageRepeat.repeat,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: const Text(
                              'Team Members',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: const Text(
                              'Manage your construction workforce',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Statistics
                          Consumer<WorkerProvider>(
                            builder: (context, provider, child) {
                              if (provider.workers.isEmpty) return const SizedBox();

                              final totalWorkers = provider.workers.length;
                              final activeWorkers = provider.workers.where((w) => w.isActive).length;

                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Row(
                                  children: [
                                    _buildStatCard('Total', totalWorkers.toString(), Icons.people_rounded),
                                    const SizedBox(width: 12),
                                    _buildStatCard('Active', activeWorkers.toString(), Icons.check_circle_rounded),
                                    const SizedBox(width: 12),
                                    _buildStatCard('Managers', provider.workers.where((w) => w.role.toLowerCase() == 'manager').length.toString(), Icons.supervisor_account_rounded),
                                    const SizedBox(width: 12),
                                    _buildStatCard('Workers', provider.workers.where((w) => w.role.toLowerCase() == 'worker').length.toString(), Icons.construction_rounded),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    context.read<WorkerProvider>().loadWorkersByOwner();
                    context.read<SiteProvider>().fetchSites();
                  },
                ),
              ),
            ],
          ),

          // Search Bar and Role Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 16),

                  // Role Filter
                  Consumer<WorkerProvider>(
                    builder: (context, provider, child) {
                      if (provider.workers.isEmpty) return const SizedBox();

                      final roles = _getUniqueRoles(provider.workers);

                      return Container(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: roles.length,
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            final isSelected = _selectedRole == role;
                            final roleColor = role == 'All' ? Colors.grey[600]! : _getRoleColor(role);

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (role != 'All') ...[
                                      Icon(
                                        _getRoleIcon(role),
                                        size: 16,
                                        color: isSelected ? Colors.white : roleColor,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      role == 'All' ? 'All Team' : role.toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : roleColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedRole = role);
                                },
                                backgroundColor: Colors.white,
                                selectedColor: roleColor,
                                elevation: isSelected ? 4 : 1,
                                shadowColor: roleColor.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? roleColor : roleColor.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Worker List
          Consumer<WorkerProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading team members...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.workers.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
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
                      ],
                    ),
                  ),
                );
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

              // Group by role
              final groupedWorkers = <String, List<dynamic>>{};
              for (final worker in filteredWorkers) {
                if (!groupedWorkers.containsKey(worker.role)) {
                  groupedWorkers[worker.role] = [];
                }
                groupedWorkers[worker.role]!.add(worker);
              }

              final sortedRoles = groupedWorkers.keys.toList()..sort();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      // Calculate which role section and worker we're showing
                      int currentIndex = 0;
                      for (final role in sortedRoles) {
                        if (index == currentIndex) {
                          // Role header
                          return _buildRoleHeader(role, groupedWorkers[role]!.length);
                        }
                        currentIndex++;

                        for (int i = 0; i < groupedWorkers[role]!.length; i++) {
                          if (index == currentIndex) {
                            // Worker card
                            return _buildWorkerCard(context, groupedWorkers[role]![i]);
                          }
                          currentIndex++;
                        }
                      }
                      return null;
                    },
                    childCount: sortedRoles.fold(0, (sum, role) => sum! + 1 + groupedWorkers[role]!.length),
                  ),
                ),
              );
            },
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _showCreateWorkerDialog(context),
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text(
              'Create Worker',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              context.read<WorkerProvider>().loadWorkersByOwner();
              context.read<SiteProvider>().fetchSites();
            },
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Refresh',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleHeader(String role, int count) {
    final roleColor = _getRoleColor(role);
    final roleIcon = _getRoleIcon(role);

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(roleIcon, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: roleColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(left: 12),
              color: roleColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, dynamic worker) {
    final roleColor = _getRoleColor(worker.role);
    final roleIcon = _getRoleIcon(worker.role);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
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
                // TODO: Navigate to worker detail
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Existing Row
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: roleColor.withOpacity(0.2), width: 1.5),
                          ),
                          child: Icon(
                            roleIcon,
                            color: roleColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${worker.firstName} ${worker.lastName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
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
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              if (worker.workerCode != null && worker.workerCode!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    'ID: ${worker.workerCode}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (worker.email != null && worker.email!.isNotEmpty) ...[
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
                                  if (worker.phone != null && worker.phone!.isNotEmpty) ...[
                                    if (worker.email != null && worker.email!.isNotEmpty)
                                      const SizedBox(width: 12),
                                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      worker.phone!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                    // Promote Button
                    if (worker.role.toLowerCase() == 'worker')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            if (worker.email == null || worker.email!.isEmpty)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.mail_outline),
                                label: const Text("Add Credentials"),
                                onPressed: () async {
                                  // Show dialog to enter email/password
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
                                },
                              ),
                            if (worker.email != null && worker.email!.isNotEmpty)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upgrade_rounded),
                                label: const Text("Promote to Manager"),
                                onPressed: () async {
                                  final siteId = worker.assignedSite;
                                  try {
                                    await Provider.of<WorkerProvider>(context, listen: false)
                                        .promoteWorkerToManager(worker.id, siteId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Promoted to manager!')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.link),
                              tooltip: "Assign to Site",
                              onPressed: () => _showAssignWorkerDialog(context, worker.id),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}