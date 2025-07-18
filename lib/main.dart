import 'package:constructionproject/Manger/Screens/manager_home_page.dart';
import 'package:constructionproject/Manger/Service/attendance_service.dart';
import 'package:constructionproject/Manger/Service/manager_service.dart';
import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:constructionproject/Worker/Provider/worker_provider.dart';
import 'package:constructionproject/Worker/Screens/worker_list_page.dart';
import 'package:constructionproject/Worker/Service/worker_service.dart';
import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:constructionproject/auth/screens/auth/LoginPage.dart';
import 'package:constructionproject/auth/screens/auth/register_screen.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:constructionproject/core/constants/api_constants.dart';
import 'package:constructionproject/core/constants/app_colors.dart';
import 'package:constructionproject/profile/provider/profile_provider.dart';
import 'package:constructionproject/profile/screens/Profile_page.dart';
import 'package:constructionproject/profile/service/profile_service.dart';
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

        ProxyProvider2<Dio, SharedPreferences, AuthService>(
          update: (_, dio, sharedPreferences, __) => AuthService(
            dio: dio,
            sharedPreferences: sharedPreferences,
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

        ProxyProvider2<Dio, AuthService, WorkerService>(
          update: (_, dio, authService, __) => WorkerService(dio, authService),
        ),
        ChangeNotifierProxyProvider<WorkerService, WorkerProvider>(
          create: (context) => WorkerProvider(context.read<WorkerService>()),
          update: (_, workerService, __) => WorkerProvider(workerService),
        ),

        ChangeNotifierProvider(
          create: (_) => SiteProvider(SiteService()),
        ),

        ProxyProvider2<Dio, AuthService, ManagerService>(
          update: (_, dio, authService, __) => ManagerService(dio, authService),
        ),
        ChangeNotifierProxyProvider<ManagerService, ManagerDataProvider>(
          create: (context) => ManagerDataProvider(context.read<ManagerService>()),
          update: (_, managerService, __) => ManagerDataProvider(managerService),
        ),

        ProxyProvider<Dio, AttendanceService>(
          update: (_, dio, __) => AttendanceService(dio),
        ),
        ChangeNotifierProxyProvider<AttendanceService, AttendanceProvider>(
          create: (context) => AttendanceProvider(context.read<AttendanceService>()),
          update: (_, service, __) => AttendanceProvider(service),
        ),

        // --- Profile providers ---
        ProxyProvider2<Dio, AuthService, ProfileService>(
          update: (_, dio, authService, __) => ProfileService(dio, authService),
        ),
        ChangeNotifierProxyProvider<ProfileService, ProfileProvider>(
          create: (context) => ProfileProvider(context.read<ProfileService>()),
          update: (_, profileService, __) => ProfileProvider(profileService),
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
          '/profile': (context) => const ProfilePage(),
        },
      ),
    );
  }
}