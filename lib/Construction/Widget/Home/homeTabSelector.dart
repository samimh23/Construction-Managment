import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class HomeTabSelector extends StatelessWidget {
  final int selectedTab;
  const HomeTabSelector({super.key, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.accent, size: 18),
          const SizedBox(width: 4),
          Text(
            selectedTab == 0 ? "Map" : "Sites",
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}