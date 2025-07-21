import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Widget/Sites/DeleteSite.dart';
import '../../Widget/Sites/SiteList.dart';
import '../../Widget/Sites/SiteMap.dart';
import '../../Widget/Sites/UpdateSiteDialog.dart';
import 'Details.dart';


class SitesScreen extends StatefulWidget {
  final int selectedTab;
  const SitesScreen({super.key, required this.selectedTab});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  void _showAddSiteDialog(BuildContext context, LatLng tappedPoint) {
    showDialog(
      context: context,
      builder: (ctx) => AddSiteDialog(
        tappedPoint: tappedPoint,
        onSiteAdded: () =>
            context.read<SiteProvider>().fetchSites(),
      ),
    );
  }

  Future<void> _deleteSite(BuildContext context, ConstructionSite site) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteSiteDialog(site: site),
    );
    if (deleted == true) {
      await context.read<SiteProvider>().deleteSite(site.id ?? "");
      await context.read<SiteProvider>().fetchSites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Site deleted', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.selectedTab == 0
        ? SiteMap(onAddSite: _showAddSiteDialog)
        : SiteList(onDeleteSite: _deleteSite);
  }
}