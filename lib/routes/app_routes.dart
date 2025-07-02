import 'package:flutter/material.dart';
import '../screens/LoginPage.dart';
import '../screens/register_page.dart';
import '../screens/home_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String splash = '/splash';
  
  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      home: (context) => const HomePage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (context) => const RegisterPage(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
    }
  }
}

// Route protection wrapper
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String redirectRoute;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.redirectRoute = AppRoutes.login,
  });

  @override
  Widget build(BuildContext context) {
    // This would typically check authentication state
    // For now, we'll assume the user is authenticated if they reach this route
    return child;
  }
}