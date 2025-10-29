import 'package:constructionproject/Dashboard/pages/Dashboard_Page.dart';
import 'package:constructionproject/Manger/Screens/manager_home_page.dart';
import 'package:constructionproject/Manger/Service/attendance_service.dart';
import 'package:constructionproject/Manger/Service/conectivty_service.dart';
import 'package:constructionproject/Manger/Service/manager_service.dart';
import 'package:constructionproject/Manger/manager_provider/ManagerLocationProvider.dart';
import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:constructionproject/Worker/Provider/worker_provider.dart';
import 'package:constructionproject/Worker/Screens/worker_list_page.dart';
import 'package:constructionproject/Worker/Service/worker_service.dart';
import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:constructionproject/auth/Widgets/Forms/confirm_code_screeb.dart';
import 'package:constructionproject/auth/Widgets/Forms/forget_password_screen.dart';
import 'package:constructionproject/auth/Widgets/Forms/reset_password_scrren.dart';
import 'package:constructionproject/auth/screens/auth/LoginPage.dart';
import 'package:constructionproject/auth/screens/auth/register_screen.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:constructionproject/core/constants/api_constants.dart';
import 'package:constructionproject/core/constants/app_colors.dart';
import 'package:constructionproject/profile/provider/profile_provider.dart';
import 'package:constructionproject/profile/screens/Profile_page.dart';
import 'package:constructionproject/profile/service/profile_service.dart';
// ADD THESE IMPORTS FOR OFFLINE FUNCTIONALITY:
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Construction/Provider/ConstructionSite/Provider.dart';
import 'Construction/service/ConstructionSiteService.dart';
import 'Construction/screen/ConstructionSite/Home.dart';
// ADD THESE IMPORTS FOR OFFLINE FUNCTIONALITY:
import 'package:constructionproject/Manger/Service/offline_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  // REMOVED: ConnectivityService.initialize() - not needed with the new implementation

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
          create:
              (_) => Dio(
                BaseOptions(
                  baseUrl: ApiConstants.localBaseUrl,
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                ),
              ),
        ),
        Provider<SharedPreferences>.value(value: sharedPreferences),

        // ADD: Offline functionality services
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        Provider(create: (_) => OfflineStorageService()),

        ProxyProvider2<Dio, SharedPreferences, AuthService>(
          update:
              (_, dio, sharedPreferences, __) =>
                  AuthService(dio: dio, sharedPreferences: sharedPreferences),
        ),

        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create:
              (context) =>
                  AuthProvider(authService: context.read<AuthService>()),
          update:
              (_, authService, __) => AuthProvider(authService: authService),
        ),

        ProxyProvider2<Dio, AuthService, WorkerService>(
          update: (_, dio, authService, __) => WorkerService(dio, authService),
        ),
        ChangeNotifierProxyProvider<WorkerService, WorkerProvider>(
          create: (context) => WorkerProvider(context.read<WorkerService>()),
          update: (_, workerService, __) => WorkerProvider(workerService),
        ),

        ChangeNotifierProvider(create: (_) => SiteProvider(SiteService())),
        ProxyProvider2<Dio, AuthService, ManagerService>(
          update: (_, dio, authService, __) => ManagerService(dio, authService),
        ),
        ChangeNotifierProxyProvider<ManagerService, ManagerDataProvider>(
          create:
              (context) => ManagerDataProvider(context.read<ManagerService>()),
          update:
              (_, managerService, __) => ManagerDataProvider(managerService),
        ),

        // UPDATED: AttendanceService with offline support
        ProxyProvider3<
          Dio,
          ConnectivityService,
          OfflineStorageService,
          AttendanceService
        >(
          update:
              (_, dio, connectivity, offline, __) => AttendanceService(
                dio,
                offlineStorage: offline,
                connectivityService: connectivity,
              ),
        ),

        // UPDATED: AttendanceProvider with offline functionality
        ChangeNotifierProxyProvider4<
          AttendanceService,
          ConnectivityService,
          OfflineStorageService,
          AuthService,
          AttendanceProvider
        >(
          create:
              (context) => AttendanceProvider(
                context.read<AttendanceService>(),
                authService: context.read<AuthService>(), // Pass AuthService!
                connectivityService: context.read<ConnectivityService>(),
                offlineStorage: context.read<OfflineStorageService>(),
              ),
          update:
              (_, service, connectivity, offline, authService, provider) =>
                  provider ??
                  AttendanceProvider(
                    service,
                    authService: authService, // Pass AuthService!
                    connectivityService: connectivity,
                    offlineStorage: offline,
                  ),
        ),

        // --- Profile providers ---
        ProxyProvider2<Dio, AuthService, ProfileService>(
          update: (_, dio, authService, __) => ProfileService(dio, authService),
        ),
        ChangeNotifierProxyProvider<ProfileService, ProfileProvider>(
          create: (context) => ProfileProvider(context.read<ProfileService>()),
          update: (_, profileService, __) => ProfileProvider(profileService),
        ),
        ChangeNotifierProvider(create: (_) => ManagerLocationProvider()),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            final role = authProvider.user?.role.toLowerCase();

            // Route based on actual role
            if (role == 'manager' || role == 'construction_manager') {
              return const ManagerHomeScreen();
            } else if (role == 'owner') {
              return HomeScreen();
            } else {
              // If role is null or unknown, stay on login
              // This happens during hot restart before user data loads
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/login');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
          '/profile': (context) => const ProfilePage(),
          '/owner': (context) => const HomeScreen(),
          '/manager': (context) => const ManagerHomeScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/confirm-code': (context) => const ConfirmCodeScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/dash': (context) => DashboardPage(),
        },
      ),
    );
  }
}
