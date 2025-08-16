import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Widget/Sites/SiteMap.dart';
import '../../Widget/Sites/SiteList.dart';
import '../../Provider/ConstructionSite/Provider.dart';
import '../../Widget/Sites/UpdateSiteDialog.dart';
import 'package:latlong2/latlong.dart';

class SitesScreen extends StatefulWidget {
  final int selectedTab;
  final LatLng? mapInitialCenter; // <-- Add this
  final double? mapInitialZoom;   // <-- Add this

  const SitesScreen({
    super.key,
    required this.selectedTab,
    this.mapInitialCenter,
    this.mapInitialZoom,
  });

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;
  String _ownerId = '';

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
        _ownerId = ownerId;
        final managerProvider = Provider.of<ManagerLocationProvider>(context, listen: false);

        managerProvider.connectAsOwner();
        managerProvider.onConnected(() {
          managerProvider.requestManagersForOwner(ownerId);
        });

        await context.read<SiteProvider>().fetchSitesByOwner(ownerId);

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


  Future<void> _refreshSites() async {
    try {
      if (mounted && _ownerId.isNotEmpty) {
        await context.read<SiteProvider>().fetchSitesByOwner(_ownerId);
      }
    } catch (e) {
      debugPrint('Error refreshing sites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RepaintBoundary(
      child: widget.selectedTab == 0
          ? SiteMap(
        onAddSite: _showAddSiteDialog,
        initialCenter: widget.mapInitialCenter,
        initialZoom: widget.mapInitialZoom,
      )
          : SiteList(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}