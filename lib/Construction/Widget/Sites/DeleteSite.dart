import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';

class DeleteSiteDialog extends StatelessWidget {
  final ConstructionSite site;
  const DeleteSiteDialog({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.delete_forever, color: AppColors.error, size: 24),
          const SizedBox(width: 8),
          Text('Delete Site', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        ],
      ),
      content: Text('Are you sure you want to delete "${site.name}"? This action cannot be undone.',
          style: TextStyle(color: AppColors.textPrimary)),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: AppColors.secondary)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.delete, color: Colors.white, size: 18),
          label: Text('Delete'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}