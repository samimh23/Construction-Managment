import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class HomeTabSelector extends StatelessWidget {
  final int selectedTab;

  const HomeTabSelector({super.key, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return RepaintBoundary(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.15),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.accent,
                  size: isMobile ? 16 : 18,
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Text(
                  selectedTab == 0 ? "Map View" : "Sites List",
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}