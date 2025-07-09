import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsProjectInfoCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController budgetController;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const SiteDetailsProjectInfoCard({
    super.key,
    required this.isEditing,
    required this.budgetController,
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
              Icon(Icons.info, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text("Project Info", style: labelStyle),
            ]),
            const SizedBox(height: 4),
            isEditing
                ? TextField(
              controller: budgetController,
              enabled: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Budget",
                prefixIcon: Icon(Icons.attach_money, color: AppColors.success),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            )
                : (budgetController.text.isNotEmpty
                ? Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text("Budget: ", style: labelStyle),
                Expanded(
                  child: Text(budgetController.text, style: valueStyle, overflow: TextOverflow.ellipsis),
                ),
              ],
            )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}