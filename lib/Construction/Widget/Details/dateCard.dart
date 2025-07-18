import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsDatesCard extends StatelessWidget {
  final bool isEditing;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime?) onStartDateChanged;
  final void Function(DateTime?) onEndDateChanged;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const SiteDetailsDatesCard({
    super.key,
    required this.isEditing,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.labelStyle,
    required this.valueStyle,
  });

  String dateString(DateTime? date) =>
      date != null ? DateFormat("yyyy-MM-dd").format(date) : "-";

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
            Row(
              children: [
                Icon(Icons.event, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text("Dates", style: labelStyle),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text("Start: ", style: TextStyle(color: AppColors.textSecondary)),
                if (isEditing)
                  TextButton.icon(
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(dateString(startDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      onStartDateChanged(picked);
                    },
                  )
                else
                  Text(dateString(startDate), style: valueStyle),
              ],
            ),
            Row(
              children: [
                const Text("End: ", style: TextStyle(color: AppColors.textSecondary)),
                if (isEditing)
                  TextButton.icon(
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(dateString(endDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      onEndDateChanged(picked);
                    },
                  )
                else
                  Text(dateString(endDate), style: valueStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}