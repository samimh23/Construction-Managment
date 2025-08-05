import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../Widget/Sites/SiteMap.dart';
import '../../Widget/Sites/SiteList.dart';
import '../../Model/Constructionsite/ConstructionSiteModel.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../Widget/Sites/DeleteSite.dart';
import '../../Widget/Sites/UpdateSiteDialog.dart';
import 'package:latlong2/latlong.dart';

class SitesScreen extends StatefulWidget {
  final int selectedTab;
  const SitesScreen({super.key, required this.selectedTab});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    if (_isInitialized) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      final ownerId = user?.id ?? '';

      if (ownerId.isNotEmpty) {
        final managerProvider = Provider.of<ManagerLocationProvider>(context, listen: false);

        managerProvider.connectAsOwner();
        managerProvider.onConnected(() {
          managerProvider.requestManagersForOwner(ownerId);
        });

        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Error initializing providers: $e');
    }
  }

  void _showAddSiteDialog(BuildContext context, LatLng tappedPoint) {
    showDialog(
      context: context,
      builder: (ctx) => AddSiteDialog(
        tappedPoint: tappedPoint,
        onSiteAdded: () => _refreshSites(),
      ),
    );
  }

  Future<void> _deleteSite(BuildContext context, ConstructionSite site) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteSiteDialog(site: site),
    );

    if (deleted == true && mounted) {
      try {
        final siteProvider = context.read<SiteProvider>();
        await siteProvider.deleteSite(site.id ?? "");
        await _refreshSites();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Site deleted successfully',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting site: $e',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _refreshSites() async {
    try {
      if (mounted) {
        await context.read<SiteProvider>().fetchSites();
      }
    } catch (e) {
      debugPrint('Error refreshing sites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return RepaintBoundary(
      child: widget.selectedTab == 0
          ? SiteMap(onAddSite: _showAddSiteDialog)
          : SiteList(onDeleteSite: _deleteSite),
    );
  }

  @override
  void dispose() {
    // Clean up any listeners or connections here if needed
    super.dispose();
  }
}