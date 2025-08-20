import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SiteDetailsProjectInfoCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController budgetController;

  const SiteDetailsProjectInfoCard({
    super.key,
    required this.isEditing,
    required this.budgetController,
  });

  // Dashboard colors
  static const Color _primaryBlue = Color(0xFF4285F4);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _borderGray = Color(0xFFE8EAED);
  static const Color _textGray = Color(0xFF5F6368);
  static const Color _darkText = Color(0xFF202124);

  String _formatCurrency(String value) {
    if (value.isEmpty) return "No budget set";
    final number = double.tryParse(value);
    if (number == null) return value;
    return NumberFormat.currency(symbol: 'TND ', decimalDigits: 0).format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total Budget",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textGray,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          _buildEditableBudgetField()
        else
          _buildDisplayBudgetField(),
      ],
    );
  }

  Widget _buildEditableBudgetField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderGray),
      ),
      child: TextFormField(
        controller: budgetController,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: 'Budget Amount (TND)',
          labelStyle: TextStyle(color: _textGray, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: _primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayBudgetField() {
    final hasBudget = budgetController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatCurrency(budgetController.text),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _darkText,
            ),
          ),
          if (hasBudget) ...[
            const SizedBox(height: 4),
            Text(
              "Allocated for this project",
              style: TextStyle(
                fontSize: 12,
                color: _textGray,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}