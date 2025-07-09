import 'package:flutter/material.dart';
import '../Core/Constants/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(32),
                bottomLeft: Radius.circular(32),
              ),
            ),
            child: Center(
              child: Text(
                "Construction Manager",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.map, color: selectedIndex == 0 ? AppColors.primary : AppColors.secondary),
            title: Text("Map", style: TextStyle(fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.normal)),
            selected: selectedIndex == 0,
            onTap: () {
              onSelect(0);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.format_list_bulleted, color: selectedIndex == 1 ? AppColors.primary : AppColors.secondary),
            title: Text("Sites", style: TextStyle(fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.normal)),
            selected: selectedIndex == 1,
            onTap: () {
              onSelect(1);
              Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "v1.0.0",
              style: TextStyle(color: AppColors.secondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}