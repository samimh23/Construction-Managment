
import 'package:constructionproject/Providers/auth_provider.dart';
import 'package:constructionproject/core/constants/api_constants.dart';
import 'package:constructionproject/core/constants/app_colors.dart';
import 'package:constructionproject/screens/auth/LoginPage.dart';
import 'package:constructionproject/screens/auth/register_screen.dart';
import 'package:constructionproject/services/auth/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'Construction/Provider/ConstructionSite/Provider.dart';
import 'Construction/service/ConstructionSiteService.dart';
import 'Construction/screen/ConstructionSite/Home.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';


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
          create: (_) => SiteProvider(SiteService()),
        ),
        // Add more providers here if needed
      ],
      child: MaterialApp(
        title: 'Construction Manager',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(),

        Provider<Dio>(
          create: (_) => Dio(BaseOptions(
            baseUrl: ApiConstants.localBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          )),
        ),
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        ProxyProvider2<Dio, FlutterSecureStorage, AuthService>(
          update: (_, dio, secureStorage, __) => AuthService(
            dio: dio,
            secureStorage: secureStorage,
          ),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
          ),
          update: (_, authService, __) => AuthProvider(
            authService: authService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Construction Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),

          // Add other routes here
        },

      ),
    );
  }
}