import 'package:constructionproject/Manger/Screens/manager_home_page.dart';
import 'package:constructionproject/Manger/Service/manager_service.dart';
import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:constructionproject/Providers/auth_provider.dart';
import 'package:constructionproject/Worker/Provider/worker_provider.dart';
import 'package:constructionproject/Worker/Screens/worker_list_page.dart';
import 'package:constructionproject/Worker/Service/worker_service.dart';
import 'package:constructionproject/core/constants/api_constants.dart';
import 'package:constructionproject/core/constants/app_colors.dart';
import 'package:constructionproject/screens/auth/LoginPage.dart';
import 'package:constructionproject/screens/auth/register_screen.dart';
import 'package:constructionproject/services/auth/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Construction/Provider/ConstructionSite/Provider.dart';
import 'Construction/service/ConstructionSiteService.dart';
import 'Construction/screen/ConstructionSite/Home.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(MyApp(sharedPreferences: sharedPreferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) => Dio(BaseOptions(
            baseUrl: ApiConstants.localBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          )),
        ),
        Provider<SharedPreferences>.value(value: sharedPreferences),

        // AuthService depends on Dio and SharedPreferences
        ProxyProvider2<Dio, SharedPreferences, AuthService>(
          update: (_, dio, sharedPreferences, __) => AuthService(
            dio: dio,
            sharedPreferences: sharedPreferences,
          ),
        ),

        // AuthProvider depends on AuthService
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
          ),
          update: (_, authService, __) => AuthProvider(
            authService: authService,
          ),
        ),

        // WorkerService depends on Dio and AuthService
        ProxyProvider2<Dio, AuthService, WorkerService>(
          update: (_, dio, authService, __) => WorkerService(dio, authService),
        ),
        // WorkerProvider depends on WorkerService
        ChangeNotifierProxyProvider<WorkerService, WorkerProvider>(
          create: (context) => WorkerProvider(context.read<WorkerService>()),
          update: (_, workerService, __) => WorkerProvider(workerService),
        ),

        // Construction site provider
        ChangeNotifierProvider(
          create: (_) => SiteProvider(SiteService()),
        ),

        // ManagerService depends on Dio and AuthService
        ProxyProvider2<Dio, AuthService, ManagerService>(
          update: (_, dio, authService, __) => ManagerService(dio, authService),
        ),

        // ManagerDataProvider depends on ManagerService
        ChangeNotifierProxyProvider<ManagerService, ManagerDataProvider>(
          create: (context) => ManagerDataProvider(context.read<ManagerService>()),
          update: (_, managerService, __) => ManagerDataProvider(managerService),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          '/worker': (context) => const WorkerListPage(),
          '/home': (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final role = authProvider.user?.role?.toLowerCase();
            if (role == 'manager' || role == 'construction_manager') {
              return const ManagerHomeScreen();
            } else {
              return const HomeScreen();
            }
          },
        },
      ),
    );
  }
}