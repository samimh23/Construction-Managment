import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsPeopleCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController ownerController;
  final TextEditingController managerController;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const SiteDetailsPeopleCard({
    super.key,
    required this.isEditing,
    required this.ownerController,
    required this.managerController,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.people, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text("People", style: labelStyle),
            ]),
            const SizedBox(height: 4),
            isEditing
                ? TextField(
              controller: ownerController,
              enabled: true,
              decoration: InputDecoration(
                labelText: "Owner",
                prefixIcon: Icon(Icons.person, color: AppColors.primaryDark),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            )
                : Row(
              children: [
                Icon(Icons.person, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 4),
                Text("Owner: ", style: labelStyle),
                Expanded(
                  child: Text(ownerController.text, style: valueStyle, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            if (isEditing)
              TextField(
                controller: managerController,
                enabled: true,
                decoration: InputDecoration(
                  labelText: "Manager",
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.secondary),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )
            else if (managerController.text.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text("Manager: ", style: labelStyle),
                  Expanded(
                    child: Text(managerController.text, style: valueStyle, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}