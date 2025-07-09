import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Construction/Provider/ConstructionSite/Provider.dart';
import 'Construction/service/ConstructionSiteService.dart';
import 'Construction/screen/ConstructionSite/Home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // The fix: fetchSites() runs as soon as provider is created!
          create: (_) => SiteProvider(SiteService())..fetchSites(),
        ),
        // Add more providers here if needed
      ],
      child: MaterialApp(
        title: 'Construction Manager',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(),
      ),
    );
  }
}