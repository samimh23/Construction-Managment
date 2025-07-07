import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ManagerDataProvider>().loadSiteAndWorkers());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ManagerDataProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manager Dashboard')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(child: Text(provider.error!))
          : provider.site == null
          ? const Center(child: Text('No assigned site.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            provider.site!.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(provider.site!.adresse),
          const SizedBox(height: 8),
          Text('Location: ${provider.site!.latitude}, ${provider.site!.longitude}'),
          Text('Geofence radius: ${provider.site!.geofenceRadius ?? "N/A"} m'),
          Text('Active: ${provider.site!.isActive ? "Yes" : "No"}'),
          Text('Budget: ${provider.site!.budget ?? "N/A"}'),
          const SizedBox(height: 24),
          Text('Workers:', style: Theme.of(context).textTheme.titleMedium),
          ...provider.workers.map((w) => ListTile(
            leading: const Icon(Icons.person),
            title: Text(w['firstName'] ?? 'Unknown'),
            subtitle: Text('ID: ${w['_id']}'),
          )),
          if (provider.workers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No workers assigned.'),
            ),
        ],
      ),
    );
  }
}