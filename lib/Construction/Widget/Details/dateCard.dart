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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateFields(context),
        if (!isEditing && (startDate != null || endDate != null)) ...[
          const SizedBox(height: 16),
          _buildProjectDuration(),
        ],
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
            const Color(0xFF10B981),
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
            const Color(0xFFEF4444),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
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
                  primary: const Color(0xFF3B82F6),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: date != null ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                ),
              ),
            ),
            Icon(Icons.calendar_today_rounded, color: Colors.grey.shade400, size: 16),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: date != null ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
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
      final now = DateTime.now();
      final daysElapsed = now.isAfter(startDate!) ? now.difference(startDate!).inDays : 0;
      final progress = duration > 0 ? (daysElapsed / duration * 100).clamp(0, 100) : 0;
      final isOverdue = endDate!.isBefore(now);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isOverdue ? Icons.warning_rounded : Icons.access_time_rounded,
                    color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOverdue
                        ? "Project overdue by ${now.difference(endDate!).inDays} days"
                        : "Duration: $duration days",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF1F2937),
                    ),
                  ),
                ),
                Text(
                  "${progress.toInt()}%",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            if (!isOverdue) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress < 50 ? const Color(0xFF10B981) :
                    progress < 80 ? const Color(0xFFEAB308) : const Color(0xFFEF4444),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}