import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.domain_disabled_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No construction sites found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first construction site to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebGrid(BuildContext context, SiteProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 :
          MediaQuery.of(context).size.width > 1000 ? 3 : 2,
          childAspectRatio: 1.8, // Made cards wider and shorter
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.sites.length,
        itemBuilder: (ctx, i) {
          return _buildSiteCard(context, provider.sites[i], provider, isWeb: true);
        },
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, SiteProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: provider.sites.length,
      itemBuilder: (ctx, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSiteCard(context, provider.sites[i], provider, isWeb: false),
        );
      },
    );
  }

  Widget _buildSiteCard(BuildContext context, ConstructionSite site, SiteProvider provider, {required bool isWeb}) {
    final statusColor = site.isActive == true ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final authService = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 100, // Placeholder height
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        }
        final user = snapshot.data;
        final ownerId = user?.id ?? '';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SiteDetailsScreen(site: site),
                ));
                provider.fetchSitesByOwner(ownerId);
              },
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 12 : 16),
                child: isWeb
                    ? _buildWebCardContent(context, site, statusColor, provider)
                    : _buildMobileCardContent(context, site, statusColor, provider),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildWebCardContent(BuildContext context, ConstructionSite site, Color statusColor, SiteProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smaller icon for web
            Container(
              width: 40, // Reduced from 56
              height: 40, // Reduced from 56
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12), // Reduced radius
                border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(
                site.isActive == true ? Icons.construction_rounded : Icons.pause_circle_rounded,
                color: statusColor,
                size: 20, // Reduced from 24
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Site Name - Compact
                  Text(
                    site.name,
                    style: const TextStyle(
                      fontSize: 14, // Reduced from 16
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Reduced spacing

                  // Status - Compact
                  Row(
                    children: [
                      Container(
                        width: 6, // Reduced from 8
                        height: 6, // Reduced from 8
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        site.isActive == true ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11, // Reduced from 13
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Compact Action Menu
            _buildCompactActionMenu(context, site, provider),
          ],
        ),

        const SizedBox(height: 8), // Reduced spacing

        // Address - Compact
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]), // Smaller icon
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                site.adresse,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]), // Smaller text
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Owner - Compact
        if (site.owner.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.business_outlined, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  site.owner,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        const Spacer(), // Push metrics to bottom

        // Bottom Metrics - Compact
        if (site.budget != null || site.endDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (site.budget != null) ...[
                Expanded(
                  child: _buildCompactMetricChip(
                    Icons.account_balance_wallet_rounded,
                    "TND ${site.budget}",
                    const Color(0xFF10B981),
                  ),
                ),
              ],
              if (site.budget != null && site.endDate != null)
                const SizedBox(width: 6), // Reduced spacing
              if (site.endDate != null)
                Expanded(
                  child: _buildCompactMetricChip(
                    Icons.schedule_rounded,
                    _formatDate(site.endDate!),
                    const Color(0xFF3B82F6),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMobileCardContent(BuildContext context, ConstructionSite site, Color statusColor, SiteProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row: Avatar + Details + Menu
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Site Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(
                site.isActive == true ? Icons.construction_rounded : Icons.pause_circle_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Site Name
                  Text(
                    site.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Status
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        site.isActive == true ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          site.adresse,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Owner
                  if (site.owner.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            site.owner,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Menu
            _buildActionMenu(context, site, provider),
          ],
        ),

        // Bottom Metrics Row
        if (site.budget != null || site.endDate != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (site.budget != null) ...[
                Expanded(
                  child: _buildInfoChip(
                    Icons.account_balance_wallet_rounded,
                    "TND ${site.budget}",
                    const Color(0xFF10B981),
                  ),
                ),
              ],
              if (site.budget != null && site.endDate != null)
                const SizedBox(width: 8),
              if (site.endDate != null) ...[
                Expanded(
                  child: _buildInfoChip(
                    Icons.schedule_rounded,
                    _formatDate(site.endDate!),
                    const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // New compact metric chip for web
  Widget _buildCompactMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6), // Smaller radius
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color), // Smaller icon
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 9, // Smaller text
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // New compact action menu for web
  Widget _buildCompactActionMenu(BuildContext context, ConstructionSite site, SiteProvider provider) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: Colors.grey[600],
          size: 14, // Smaller icon
        ),
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
              Icon(Icons.edit_rounded, size: 16, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              const Text('Edit', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 16, color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              const Text('Delete', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
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
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: Colors.grey[600],
          size: 18,
        ),
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
              Icon(Icons.edit_rounded, size: 18, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              const Text('Edit Site'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              const Text('Delete Site'),
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