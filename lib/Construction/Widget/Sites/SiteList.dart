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
    return Consumer<SiteProvider>(
      builder: (context, provider, child) {
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: provider.sites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final site = provider.sites[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SiteDetailsScreen(site: site),
                  ));
                  provider.fetchSites();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2)
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: site.isActive == true
                                ? AppColors.success.withOpacity(0.12)
                                : AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: site.isActive == true ? AppColors.success : AppColors.error,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 18),
                        // Main data
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      site.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: AppColors.primaryDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (site.isActive == true)
                                    Chip(
                                      label: const Text("Active", style: TextStyle(color: Colors.white, fontSize: 11)),
                                      backgroundColor: AppColors.success,
                                      avatar: const Icon(Icons.check_circle, color: Colors.white, size: 15),
                                      padding: EdgeInsets.zero,
                                    )
                                  else
                                    Chip(
                                      label: const Text("Inactive", style: TextStyle(color: Colors.white, fontSize: 11)),
                                      backgroundColor: AppColors.error,
                                      avatar: const Icon(Icons.remove_circle, color: Colors.white, size: 15),
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                site.adresse,
                                style: TextStyle(color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person, size: 14, color: AppColors.primaryDark),
                                      const SizedBox(width: 3),
                                      Text(
                                        site.owner,
                                        style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                                      ),
                                    ],
                                  ),
                                  if (site.budget != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.attach_money, size: 14, color: AppColors.success),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${site.budget}",
                                          style: TextStyle(fontSize: 12, color: AppColors.success),
                                        ),
                                      ],
                                    ),
                                  if (site.endDate != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.event, size: 14, color: AppColors.accent),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${site.endDate!.year}-${site.endDate!.month.toString().padLeft(2, '0')}-${site.endDate!.day.toString().padLeft(2, '0')}",
                                          style: TextStyle(fontSize: 12, color: AppColors.accent),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Actions
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primaryDark, size: 24),
                              tooltip: "Edit",
                              onPressed: () async {
                                await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => SiteDetailsScreen(site: site),
                                ));
                                provider.fetchSites();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: AppColors.error, size: 24),
                              tooltip: "Delete",
                              onPressed: () => onDeleteSite(context, site),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}