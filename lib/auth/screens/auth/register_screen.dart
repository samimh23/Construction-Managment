  import 'package:constructionproject/Construction/Core/Constants/app_colors.dart';
  import 'package:constructionproject/auth/models/auth_models.dart';
  import 'package:constructionproject/auth/Providers/auth_provider.dart';
  import 'package:constructionproject/auth/Widgets/Forms/custom_text%20_field.dart';
  import 'package:constructionproject/auth/Widgets/Forms/password_strength_indicator.dart';
  import 'package:constructionproject/core/utils/validators.dart';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';

  class RegisterScreen extends StatefulWidget {
    const RegisterScreen({super.key});

    @override
    State<RegisterScreen> createState() => _RegisterScreenState();
  }

  class _RegisterScreenState extends State<RegisterScreen> {
    final _formKey = GlobalKey<FormState>();
    final _fullNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _companyController = TextEditingController();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    bool _obscurePassword = true;
    bool _obscureConfirmPassword = true;
    bool _acceptTerms = false;
    String _password = '';

    @override
    void initState() {
      super.initState();
      _passwordController.addListener(() {
        setState(() {
          _password = _passwordController.text;
        });
      });
    }

    @override
    void dispose() {
      _fullNameController.dispose();
      _emailController.dispose();
      _phoneController.dispose();
      _companyController.dispose();
      _passwordController.dispose();
      _confirmPasswordController.dispose();
      super.dispose();
    }

    Future<void> _handleRegister() async {
      if (!_formKey.currentState!.validate()) return;

      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authProvider = context.read<AuthProvider>();

      // SPLIT FULL NAME
      final names = _fullNameController.text.trim().split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final registerRequest = RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        company: _companyController.text.trim(),
        password: _passwordController.text,
      );

      final success = await authProvider.register(registerRequest);

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }

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
          // Left side - Brand section
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary ?? Colors.blue,
                    AppColors.primary?.withOpacity(0.8) ?? Colors.blue.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction,
                      size: 120,
                      color: Colors.white,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Join Our Platform',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Start managing your construction projects today',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side - Register form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(48),
                  child: _buildRegisterContent(),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildTabletLayout(BuildContext context) {
      return SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.all(32),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: _buildRegisterContent(),
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildMobileLayout(BuildContext context, double screenHeight) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: constraints.maxHeight < 700 ? 16 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: constraints.maxHeight < 700 ? 16 : 20),
                    _buildRegisterContent(isMobile: true),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    Widget _buildRegisterContent({bool isMobile = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isMobile),
          SizedBox(height: isMobile ? 24 : 32),
          _buildRegisterForm(isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _buildLoginLink(),
        ],
      );
    }

    Widget _buildHeader(bool isMobile) {
      return Column(
        children: [
          Container(
            width: isMobile ? 70 : 80,
            height: isMobile ? 70 : 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
            ),
            child: Icon(
              Icons.person_add,
              size: isMobile ? 35 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: isMobile ? 24 : null,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'Join our construction management platform',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: isMobile ? 14 : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    Widget _buildRegisterForm(bool isMobile) {
      final fieldSpacing = isMobile ? 16.0 : 20.0;

      return Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Full Name and Email Row (Desktop/Tablet only)
                if (!isMobile) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _fullNameController,
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: Validators.required,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Email Address',
                          hint: 'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                          required: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: fieldSpacing),

                  // Phone and Company Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          validator: Validators.phone,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Company/Organization',
                          hint: 'Enter your company name',
                          controller: _companyController,
                          prefixIcon: const Icon(Icons.business_outlined),
                          validator: Validators.required,
                          required: true,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Mobile: Stack fields vertically
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _fullNameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: Validators.required,
                    required: true,
                  ),
                  SizedBox(height: fieldSpacing),

                  CustomTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.email,
                    required: true,
                  ),
                  SizedBox(height: fieldSpacing),

                  CustomTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: Validators.phone,
                    required: true,
                  ),
                  SizedBox(height: fieldSpacing),

                  CustomTextField(
                    label: 'Company/Organization',
                    hint: 'Enter your company name',
                    controller: _companyController,
                    prefixIcon: const Icon(Icons.business_outlined),
                    validator: Validators.required,
                    required: true,
                  ),
                ],

                SizedBox(height: fieldSpacing),

                // Password
                CustomTextField(
                  label: 'Password',
                  hint: 'Create a strong password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: Validators.strongPassword,
                  required: true,
                ),

                // Password Strength Indicator
                PasswordStrengthIndicator(password: _password),

                SizedBox(height: fieldSpacing),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  required: true,
                ),

                SizedBox(height: isMobile ? 20 : 24),

                // Terms and Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: isMobile ? 13 : null,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 24 : 32),

                // Error Message
                if (authProvider.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: isMobile ? 13 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: isMobile ? 48 : 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    Widget _buildLoginLink() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: Text(
              'Sign In',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
  }