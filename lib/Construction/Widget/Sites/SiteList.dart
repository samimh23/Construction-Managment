import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../screen/ConstructionSite/Details.dart';

class SiteList extends StatefulWidget {
  const SiteList({super.key});

  @override
  State<SiteList> createState() => _SiteListState();
}

class _SiteListState extends State<SiteList> {
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 800;

    return Consumer<SiteProvider>(
      builder: (context, provider, child) {
        final filteredSites = _getFilteredSites(provider.sites);

        return Column(
          children: [
            // Filter Section
            _buildFilterSection(provider.sites.length, filteredSites.length),

            // Sites List/Grid
            Expanded(
              child: filteredSites.isEmpty
                  ? _buildEmptyState()
                  : isWeb
                  ? _buildWebGrid(context, provider, filteredSites)
                  : _buildMobileList(context, provider, filteredSites),
            ),
          ],
        );
      },
    );
  }

  List<ConstructionSite> _getFilteredSites(List<ConstructionSite> allSites) {
    switch (_filterStatus) {
      case 'active':
        return allSites.where((site) => site.isActive == true).toList();
      case 'inactive':
        return allSites.where((site) => site.isActive != true).toList();
      case 'all':
      default:
        return allSites;
    }
  }

  Widget _buildFilterSection(int totalCount, int filteredCount) {
    final isWeb = MediaQuery.of(context).size.width >= 800;

    return Container(
      margin: EdgeInsets.all(isWeb ? 24 : 16),
      padding: EdgeInsets.all(isWeb ? 20 : 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: const Color(0xFF3B82F6),
                  size: isWeb ? 20 : 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filter Construction Sites',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              // Results counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '$filteredCount of $totalCount sites',
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                'all',
                'All Sites',
                Icons.domain_rounded,
                const Color(0xFF3B82F6),
                totalCount,
              ),
              _buildFilterChip(
                'active',
                'Active',
                Icons.construction_rounded,
                const Color(0xFF10B981),
                _getFilteredSites(_getSitesFromContext()).where((site) => site.isActive == true).length,
              ),
              _buildFilterChip(
                'inactive',
                'Inactive',
                Icons.pause_circle_rounded,
                const Color(0xFFEF4444),
                _getFilteredSites(_getSitesFromContext()).where((site) => site.isActive != true).length,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, Color color, int count) {
    final isSelected = _filterStatus == value;
    final isWeb = MediaQuery.of(context).size.width >= 800;

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 14,
          vertical: isWeb ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isWeb ? 18 : 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isWeb ? 14 : 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: isWeb ? 12 : 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ConstructionSite> _getSitesFromContext() {
    return Provider.of<SiteProvider>(context, listen: false).sites;
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    switch (_filterStatus) {
      case 'active':
        message = 'No active construction sites found';
        subtitle = 'All sites are currently inactive';
        icon = Icons.construction_rounded;
        break;
      case 'inactive':
        message = 'No inactive construction sites found';
        subtitle = 'All sites are currently active';
        icon = Icons.pause_circle_rounded;
        break;
      default:
        message = 'No construction sites found';
        subtitle = 'Add your first construction site to get started';
        icon = Icons.domain_disabled_outlined;
    }

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
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_filterStatus != 'all') ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _filterStatus = 'all'),
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Show All Sites'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebGrid(BuildContext context, SiteProvider provider, List<ConstructionSite> sites) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 :
          MediaQuery.of(context).size.width > 1000 ? 3 : 2,
          childAspectRatio: 1.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: sites.length,
        itemBuilder: (ctx, i) {
          return _buildSiteCard(context, sites[i], provider, isWeb: true);
        },
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, SiteProvider provider, List<ConstructionSite> sites) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      itemCount: sites.length,
      itemBuilder: (ctx, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSiteCard(context, sites[i], provider, isWeb: false),
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