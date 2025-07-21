import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsDatesCard extends StatelessWidget {
  final bool isEditing;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime?) onStartDateChanged;
  final void Function(DateTime?) onEndDateChanged;

  const SiteDetailsDatesCard({
    super.key,
    required this.isEditing,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat("MMM dd, yyyy").format(date) : "Not set";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDateFields(context),
            if (!isEditing) ...[
              const SizedBox(height: 16),
              _buildProjectDuration(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.event_rounded, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          "Project Timeline",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDateFields(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            context,
            "Start Date",
            startDate,
            Icons.play_circle_outline_rounded,
            AppColors.success,
            onStartDateChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateField(
            context,
            "End Date",
            endDate,
            Icons.stop_circle_outlined,
            AppColors.error,
            onEndDateChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      BuildContext context,
      String label,
      DateTime? date,
      IconData icon,
      Color color,
      Function(DateTime?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          _buildEditableDateField(context, date, icon, color, onChanged)
        else
          _buildDisplayDateField(date, icon, color),
      ],
    );
  }

  Widget _buildEditableDateField(
      BuildContext context,
      DateTime? date,
      IconData icon,
      Color color,
      Function(DateTime?) onChanged,
      ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: date != null ? AppColors.primaryDark : AppColors.secondary,
                ),
              ),
            ),
            Icon(Icons.calendar_today_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayDateField(DateTime? date, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: date != null ? AppColors.primaryDark : AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDuration() {
    if (startDate != null && endDate != null) {
      final duration = endDate!.difference(startDate!).inDays;
      final isOverdue = endDate!.isBefore(DateTime.now());

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOverdue ? AppColors.error.withOpacity(0.05) : AppColors.info.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue ? AppColors.error.withOpacity(0.2) : AppColors.info.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOverdue ? Icons.warning_rounded : Icons.access_time_rounded,
              color: isOverdue ? AppColors.error : AppColors.info,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOverdue
                    ? "Project overdue by ${DateTime.now().difference(endDate!).inDays} days"
                    : "Duration: $duration days",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isOverdue ? AppColors.error : AppColors.info,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}