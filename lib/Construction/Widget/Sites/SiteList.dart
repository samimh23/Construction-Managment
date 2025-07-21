import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../screen/ConstructionSite/Details.dart';

class SiteList extends StatelessWidget {
  final Future<void> Function(BuildContext, ConstructionSite) onDeleteSite;
  const SiteList({super.key, required this.onDeleteSite});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 800;

    return Consumer<SiteProvider>(
      builder: (context, provider, child) {
        if (provider.sites.isEmpty) {
          return _buildEmptyState();
        }

        if (isWeb) {
          return _buildWebGrid(context, provider);
        }

        return _buildMobileList(context, provider);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.domain_disabled_outlined,
              size: 48,
              color: AppColors.secondary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No construction sites",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first site to get started",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebGrid(BuildContext context, SiteProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 :
          MediaQuery.of(context).size.width > 1000 ? 3 : 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: provider.sites.length,
        itemBuilder: (ctx, i) {
          return _buildSiteCard(context, provider.sites[i], provider, isWeb: true);
        },
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, SiteProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: provider.sites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        return _buildSiteCard(context, provider.sites[i], provider, isWeb: false);
      },
    );
  }

  Widget _buildSiteCard(BuildContext context, ConstructionSite site, SiteProvider provider, {required bool isWeb}) {
    final statusColor = site.isActive == true ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SiteDetailsScreen(site: site),
            ));
            provider.fetchSites();
          },
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            child: isWeb
                ? _buildWebCardContent(context, site, statusColor, provider)
                : _buildMobileCardContent(context, site, statusColor, provider),
          ),
        ),
      ),
    );
  }

  Widget _buildWebCardContent(BuildContext context, ConstructionSite site, Color statusColor, SiteProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            _buildStatusIndicator(site.isActive == true, statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    site.isActive == true ? "Active" : "Inactive",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildActionMenu(context, site, provider),
          ],
        ),

        const SizedBox(height: 20),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                Icons.location_on_outlined,
                site.adresse,
                AppColors.secondary,
              ),
              const Spacer(),

              // Bottom info
              Row(
                children: [
                  if (site.budget != null) ...[
                    Expanded(
                      child: _buildMetricChip(
                        Icons.attach_money,
                        "${site.budget}",
                        AppColors.success,
                      ),
                    ),
                  ],
                  if (site.budget != null && site.endDate != null)
                    const SizedBox(width: 8),
                  if (site.endDate != null)
                    Expanded(
                      child: _buildMetricChip(
                        Icons.schedule_outlined,
                        _formatDate(site.endDate!),
                        AppColors.accent,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCardContent(BuildContext context, ConstructionSite site, Color statusColor, SiteProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            _buildStatusIndicator(site.isActive == true, statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    site.isActive == true ? "Active" : "Inactive",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildActionMenu(context, site, provider),
          ],
        ),

        const SizedBox(height: 16),

        // Details
        _buildInfoRow(
          Icons.location_on_outlined,
          site.adresse,
          AppColors.secondary,
        ),

        if (site.budget != null || site.endDate != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (site.budget != null) ...[
                Expanded(
                  child: _buildMetricChip(
                    Icons.attach_money,
                    "${site.budget}",
                    AppColors.success,
                  ),
                ),
              ],
              if (site.budget != null && site.endDate != null)
                const SizedBox(width: 8),
              if (site.endDate != null)
                Expanded(
                  child: _buildMetricChip(
                    Icons.schedule_outlined,
                    _formatDate(site.endDate!),
                    AppColors.accent,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(bool isActive, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isActive ? Icons.construction : Icons.pause_circle_outline,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, ConstructionSite site, SiteProvider provider) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.secondary.withOpacity(0.6),
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SiteDetailsScreen(site: site),
            ));
            provider.fetchSites();
            break;
          case 'delete':
            onDeleteSite(context, site);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              const SizedBox(width: 12),
              const Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}