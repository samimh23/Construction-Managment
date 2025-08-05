import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Core/Constants/app_colors.dart';

class SiteDetailsProjectInfoCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController budgetController;

  const SiteDetailsProjectInfoCard({
    super.key,
    required this.isEditing,
    required this.budgetController,
  });

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
        const Text(
          "Total Budget",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
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
      child: TextFormField(
        controller: budgetController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: "Enter budget amount",
          prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF10B981), size: 20),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDisplayBudgetField() {
    final hasBudget = budgetController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasBudget
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFF6B7280).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_money_rounded,
                  color: hasBudget ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatCurrency(budgetController.text),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: hasBudget ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                      ),
                    ),
                    if (hasBudget)
                      const Text(
                        "Allocated for this project",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}