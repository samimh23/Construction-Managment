import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Dashboard colors
  static const Color _primaryBlue = Color(0xFF4285F4);
  static const Color _successGreen = Color(0xFF34A853);
  static const Color _warningRed = Color(0xFFEA4335);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _borderGray = Color(0xFFE8EAED);
  static const Color _textGray = Color(0xFF5F6368);
  static const Color _darkText = Color(0xFF202124);

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat("MMM d, yyyy").format(date) : "Not set";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateFields(context),
        if (!isEditing && (startDate != null && endDate != null)) ...[
          const SizedBox(height: 16),
          _buildProjectProgress(),
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
            onStartDateChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateField(
            context,
            "End Date",
            endDate,
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
      Function(DateTime?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textGray,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          _buildEditableDateField(context, date, onChanged)
        else
          _buildDisplayDateField(date),
      ],
    );
  }

  Widget _buildEditableDateField(
      BuildContext context,
      DateTime? date,
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
                  primary: _primaryBlue,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _borderGray),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: date != null ? _darkText : _textGray,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: _textGray,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayDateField(DateTime? date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderGray),
      ),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _darkText,
        ),
      ),
    );
  }

  Widget _buildProjectProgress() {
    if (startDate != null && endDate != null) {
      final duration = endDate!.difference(startDate!).inDays;
      final now = DateTime.now();
      final daysElapsed = now.isAfter(startDate!) ? now.difference(startDate!).inDays : 0;
      final progress = duration > 0 ? (daysElapsed / duration * 100).clamp(0, 100) : 0;
      final isOverdue = endDate!.isBefore(now);
      final statusColor = isOverdue ? _warningRed : _successGreen;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _lightGray,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isOverdue
                        ? "Overdue by ${now.difference(endDate!).inDays} days"
                        : "Duration: $duration days",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  "${progress.toInt()}%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (!isOverdue) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: _borderGray,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 4,
              ),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}