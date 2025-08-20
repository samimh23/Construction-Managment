import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../screen/ConstructionSite/Details.dart';

class SiteList extends StatelessWidget {
  const SiteList({super.key});

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
          childAspectRatio: 1.8,
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
            height: 100,
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
                    ? _buildWebCardContent(context, site, statusColor)
                    : _buildMobileCardContent(context, site, statusColor),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebCardContent(BuildContext context, ConstructionSite site, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(
                site.isActive == true ? Icons.construction_rounded : Icons.pause_circle_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    site.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                site.adresse,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const Spacer(),

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
                const SizedBox(width: 6),
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

  Widget _buildMobileCardContent(BuildContext context, ConstructionSite site, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
          ],
        ),
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

  Widget _buildCompactMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 9,
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}