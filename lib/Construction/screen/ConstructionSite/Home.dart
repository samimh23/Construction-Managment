import 'package:constructionproject/Construction/screen/ConstructionSite/sitesScreen.dart';
import 'package:constructionproject/Worker/Screens/worker_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../Core/Constants/app_colors.dart';
import '../../Widget/Home/HomeTitle.dart';
import '../../Widget/Home/homeTabSelector.dart';
import 'package:constructionproject/profile/screens/Profile_page.dart';

class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.map, label: 'Map'),
    NavigationItem(icon: Icons.manage_accounts, label: 'Manage'),
    NavigationItem(icon: Icons.person, label: 'Workers'),
    NavigationItem(icon: Icons.account_circle, label: 'Profile'),
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
        final isMobile = screenWidth < 768;

        return Scaffold(
          appBar: _HomeAppBar(
            selectedTab: selectedTab,
            navigationItems: _navigationItems,
            isMobile: isMobile,
          ),
          // Only show drawer on tablet/desktop, NOT on mobile
          drawer: !isMobile ? ImprovedAppDrawer(
            selectedIndex: selectedTab,
            onSelect: _onTabSelected,
          ) : null,
          body: _HomeBody(
            selectedTab: selectedTab,
            isMobile: isMobile,
          ),
          // Only show bottom navigation on mobile
          bottomNavigationBar: isMobile ? _HomeBottomNavigation(
            selectedTab: selectedTab,
            navigationItems: _navigationItems,
            onTabSelected: _onTabSelected,
          ) : null,
        );
      },
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedTab;
  final List<NavigationItem> navigationItems;
  final bool isMobile;

  const _HomeAppBar({
    required this.selectedTab,
    required this.navigationItems,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,
      // Don't show drawer button on mobile
      automaticallyImplyLeading: !isMobile,
      title: _buildAppBarContent(),
      actions: isMobile && selectedTab < 2 ? [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: HomeTabSelector(selectedTab: selectedTab),
        ),
      ] : null,
    );
  }

  Widget _buildAppBarContent() {
    if (selectedTab < 2) {
      return Row(
        children: [
          const HomeTitle(),
          const Spacer(),
          if (!isMobile) HomeTabSelector(selectedTab: selectedTab),
        ],
      );
    } else {
      return Row(
        children: [
          Text(
            navigationItems[selectedTab].label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeBody extends StatelessWidget {
  final int selectedTab;
  final bool isMobile;

  const _HomeBody({
    required this.selectedTab,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: _getCurrentScreen(),
    );
  }

  Widget _getCurrentScreen() {
    switch (selectedTab) {
      case 0:
        return const SitesScreen(selectedTab: 0);
      case 1:
        return const SitesScreen(selectedTab: 1);
      case 2:
        return const WorkerListPage();
      case 3:
        return const ProfilePage();
      default:
        return const SitesScreen(selectedTab: 0);
    }
  }
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

class ImprovedAppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const ImprovedAppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.9),
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedHeader(context),
              const SizedBox(height: 20),
              _buildNavigationItems(context),
              const Spacer(),
              _buildUserInfo(context),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.construction,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            "Construction",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            "Manager Pro",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context) {
    final items = [
      _NavigationItem(Icons.map_outlined, Icons.map, 'Map View', 0),
      _NavigationItem(Icons.manage_accounts_outlined, Icons.manage_accounts, 'Manage Sites', 1),
      _NavigationItem(Icons.person_outline, Icons.person, 'My Workers', 2),
      _NavigationItem(Icons.account_circle_outlined, Icons.account_circle, 'Profile', 3),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: items.map((item) => _EnhancedDrawerItem(
          iconOutlined: item.iconOutlined,
          iconFilled: item.iconFilled,
          label: item.label,
          selected: selectedIndex == item.index,
          onTap: () {
            Navigator.of(context).pop();
            onSelect(item.index);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              'SH', // User initials updated to match current user
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'samimh23', // Updated to current user login
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Project Manager',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.settings_outlined,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Version 1.0.0",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                "© 2025",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final int index;

  _NavigationItem(this.iconOutlined, this.iconFilled, this.label, this.index);
}

class _EnhancedDrawerItem extends StatelessWidget {
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EnhancedDrawerItem({
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selected ? Colors.white.withOpacity(0.2) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          selected ? iconFilled : iconOutlined,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: selected
            ? Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 12,
          ),
        )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}