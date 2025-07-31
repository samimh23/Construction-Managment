import 'package:flutter/material.dart';
import 'package:constructionproject/auth/Widgets/auth_brand_side.dart';

class AuthResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool isSmallScreen;

  const AuthResponsiveLayout({
    super.key,
    required this.child,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _buildResponsiveLayout(context, isDesktop, isTablet, isMobile, screenHeight),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, bool isDesktop, bool isTablet, bool isMobile, double screenHeight) {
    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else if (isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context, screenHeight);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Brand/Image section
        const Expanded(
          flex: 3,
          child: AuthBrandSide(),
        ),
        // Right side - Form content
        Expanded(
          flex: 2,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(48),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double screenHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if content might overflow
        final availableHeight = constraints.maxHeight;
        final isSmallScreen = availableHeight < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSmallScreen ? 16 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availableHeight - (isSmallScreen ? 32 : 48),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Flexible spacing at top
                  SizedBox(height: isSmallScreen ? 20 : 40),
                  child,
                  // Flexible spacing at bottom
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}