import 'package:constructionproject/Construction/screen/ConstructionSite/sitesScreen.dart';
import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';
import '../../Widget/Drawer.dart';
import '../../Widget/Home/HomeTitle.dart';
import '../../Widget/Home/homeTabSelector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        // ✅ ALTERNATIVE: Use a more flexible layout
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                // ✅ FIXED: Constrain HomeTitle width
                Expanded(
                  flex: 2,
                  child: const HomeTitle(),
                ),
                // ✅ FIXED: Add some spacing
                const SizedBox(width: 8),
                // ✅ FIXED: Constrain HomeTabSelector width
                Expanded(
                  flex: 1,
                  child: HomeTabSelector(selectedTab: selectedTab),
                ),
              ],
            );
          },
        ),
      ),
      drawer: AppDrawer(
        selectedIndex: selectedTab,
        onSelect: (i) => setState(() => selectedTab = i),
      ),
      backgroundColor: AppColors.background,
      body: SitesScreen(selectedTab: selectedTab),
    );
  }
}