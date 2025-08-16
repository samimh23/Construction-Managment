import 'package:constructionproject/Dashboard/pages/Dashboard_Page.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../Core/Constants/app_colors.dart';

import 'package:constructionproject/profile/screens/Profile_page.dart';
import 'package:constructionproject/Worker/Screens/worker_list_page.dart';
import 'package:constructionproject/Construction/screen/ConstructionSite/sitesScreen.dart';

class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}


class HomeScreen extends StatefulWidget {
  final LatLng? mapInitialCenter;
  final double? mapInitialZoom;
  const HomeScreen({super.key,this.mapInitialCenter,
    this.mapInitialZoom,});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    NavigationItem(icon: Icons.groups_outlined, label: 'Workforce'),
    NavigationItem(icon: Icons.map_outlined, label: 'Map'),
    NavigationItem(icon: Icons.business_outlined, label: 'Sites'),
    NavigationItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  void _onTabSelected(int index) {
    if (selectedTab != index) {
      setState(() => selectedTab = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 1200;
        final isMediumScreen = screenWidth > 800;

        if (isMediumScreen) {
          // Tablet/Desktop: Sidebar + page content
          return Scaffold(
            body: Row(
              children: [
                _DashboardSidebar(
                  selectedIndex: selectedTab,
                  onSelect: _onTabSelected,
                ),
                Expanded(
                  child: _HomeBody(selectedTab: selectedTab),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Bottom navigation
          return Scaffold(
            appBar: _HomeAppBar(
              selectedTab: selectedTab,
              navigationItems: _navigationItems,
            ),
            body: _HomeBody(selectedTab: selectedTab,
              mapInitialCenter: widget.mapInitialCenter,
              mapInitialZoom: widget.mapInitialZoom,),
            bottomNavigationBar: _HomeBottomNavigation(
              selectedTab: selectedTab,
              navigationItems: _navigationItems,
              onTabSelected: _onTabSelected,
            ),
          );
        }
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  final int selectedTab;
  final LatLng? mapInitialCenter;
  final double? mapInitialZoom;

  const _HomeBody({
    required this.selectedTab,
    this.mapInitialCenter,
    this.mapInitialZoom,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case 0:
        return DashboardPage();
      case 1:
        return WorkerListPage();
      case 2:
        return SitesScreen(selectedTab: 0,
          mapInitialCenter: mapInitialCenter,
          mapInitialZoom: mapInitialZoom,);
      case 3:
        return SitesScreen(selectedTab: 1);
      case 4:
        return ProfilePage();
      default:
        return DashboardPage();
    }
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedTab;
  final List<NavigationItem> navigationItems;

  const _HomeAppBar({
    required this.selectedTab,
    required this.navigationItems,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Text(
        navigationItems[selectedTab].label,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeBottomNavigation extends StatelessWidget {
  final int selectedTab;
  final List<NavigationItem> navigationItems;
  final ValueChanged<int> onTabSelected;

  const _HomeBottomNavigation({
    required this.selectedTab,
    required this.navigationItems,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedTab,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      items: navigationItems.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.label,
      )).toList(),
    );
  }
}

/// --- Sidebar copied and adapted from your DashboardPage ---
class _DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _DashboardSidebar({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.groups_outlined, 'label': 'Workforce'},
      {'icon': Icons.map_outlined, 'label': 'Map'},
      {'icon': Icons.business_outlined, 'label': 'Sites'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.engineering, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ConstructPro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Analytics Dashboard',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAVIGATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...navItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return _SidebarNavItem(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      isActive: selectedIndex == i,
                      onTap: () => onSelect(i),
                    );
                  }),
                  SizedBox(height: 32),
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  _SidebarActionButton('Export Report', Icons.download, () {}),
                  SizedBox(height: 8),
                  _SidebarActionButton('Add Worker', Icons.person_add, () {}),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Color(0xFFF1F5F9) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: Color(0xFFE2E8F0)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Color(0xFF3B82F6) : Color(0xFF64748B),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Color(0xFF1E293B) : Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SidebarActionButton(this.label, this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}