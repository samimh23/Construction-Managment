import 'package:flutter/material.dart';

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
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Center(
                child: Text(
                  "Construction Manager",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.map,
              label: 'Map',
              selected: selectedIndex == 0,
              onTap: () {
                Navigator.of(context).pop();
                onSelect(0);
              },
            ),
            _DrawerItem(
              icon: Icons.manage_accounts,
              label: 'Manage',
              selected: selectedIndex == 1,
              onTap: () {
                Navigator.of(context).pop();
                onSelect(1);
              },
            ),
            _DrawerItem(
              icon: Icons.person,
              label: 'My Workers',
              selected: selectedIndex == 2,
              onTap: () {
                Navigator.of(context).pop();
                onSelect(2);
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.blue : null),
      title: Text(label, style: TextStyle(color: selected ? Colors.blue : null)),
      selected: selected,
      onTap: onTap,
    );
  }
}