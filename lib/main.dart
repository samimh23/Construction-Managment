import 'package:constructionproject/screens/auth/LoginPage.dart';
import 'package:constructionproject/screens/auth/register_screen.dart';
import 'package:constructionproject/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';


import 'Providers/auth_provider.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) => Dio(BaseOptions(
            baseUrl: 'https://your-api-url.com/api',
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