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
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(number);
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
            _buildBudgetSection(),
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
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          "Project Budget",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Total Budget",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
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
    return TextFormField(
      controller: budgetController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "Enter budget amount",
        prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.success),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.success, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDisplayBudgetField() {
    final hasBudget = budgetController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasBudget
              ? [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.05)]
              : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasBudget
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: hasBudget ? AppColors.success : AppColors.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatCurrency(budgetController.text),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: hasBudget ? AppColors.success : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 8),
            Text(
              "Allocated for this project",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}