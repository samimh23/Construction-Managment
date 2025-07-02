import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_response_model.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/password_strength_indicator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Focus nodes
  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _companyFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  // State
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _showPasswordStrength = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _companyFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _showPasswordStrength = _passwordController.text.isNotEmpty;
    });
  }

  void _onEmailChanged() {
    // Clear email error when user starts typing
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  Future<void> _checkEmailAvailability() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || Validators.validateEmail(email) != null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exists = await authProvider.checkEmailExists(email);
    
    if (exists && mounted) {
      setState(() {
        _emailError = 'This email address is already registered';
      });
    }
  }

  Future<void> _handleRegister() async {
    // Clear email error before validation
    setState(() {
      _emailError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showErrorSnackBar('Please accept the terms and conditions');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Check email availability one more time
    await _checkEmailAvailability();
    if (_emailError != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final registerRequest = RegisterRequest(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      company: _companyController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      acceptTerms: _acceptTerms,
    );

    final success = await authProvider.register(registerRequest);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Show success message and navigate
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      // Show error message
      if (mounted) {
        _showErrorSnackBar(authProvider.errorMessage ?? 'Registration failed');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Welcome!'),
          ],
        ),
        content: const Text(
          'Your account has been created successfully. You can now start managing your construction projects.',
        ),
        actions: [
          CustomButton(
            text: 'Get Started',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            type: ButtonType.primary,
            height: 36,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Creating your account...',
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 32),
                
                // Registration Form
                _buildRegistrationForm(),
                
                const SizedBox(height: 24),
                
                // Terms and Conditions
                _buildTermsAcceptance(),
                
                const SizedBox(height: 24),
                
                // Register Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                  type: ButtonType.primary,
                ),
                
                const SizedBox(height: 16),
                
                // Login Link
                _buildLoginLink(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person_add,
            color: AppColors.white,
            size: 30,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Title
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        const Text(
          'Join Construction Management and streamline your projects',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        // Full Name
        CustomTextField(
          label: 'Full Name',
          hintText: 'Enter your full name',
          controller: _fullNameController,
          keyboardType: TextInputType.name,
          focusNode: _fullNameFocusNode,
          textInputAction: TextInputAction.next,
          required: true,
          validator: Validators.validateFullName,
          prefixIcon: const Icon(
            Icons.person_outline,
            color: AppColors.mediumGrey,
          ),
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_emailFocusNode);
          },
        ),
        
        const SizedBox(height: 16),
        
        // Email
        CustomTextField(
          label: 'Email Address',
          hintText: 'Enter your email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          focusNode: _emailFocusNode,
          textInputAction: TextInputAction.next,
          required: true,
          validator: (value) {
            final emailValidation = Validators.validateEmail(value);
            return _emailError ?? emailValidation;
          },
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: AppColors.mediumGrey,
          ),
          onSubmitted: (_) {
            _checkEmailAvailability();
            FocusScope.of(context).requestFocus(_phoneFocusNode);
          },
        ),
        
        const SizedBox(height: 16),
        
        // Phone Number
        CustomTextField(
          label: 'Phone Number',
          hintText: 'Enter your phone number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          focusNode: _phoneFocusNode,
          textInputAction: TextInputAction.next,
          required: true,
          validator: Validators.validatePhoneNumber,
          prefixIcon: const Icon(
            Icons.phone_outlined,
            color: AppColors.mediumGrey,
          ),
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_companyFocusNode);
          },
        ),
        
        const SizedBox(height: 16),
        
        // Company
        CustomTextField(
          label: 'Company/Organization',
          hintText: 'Enter your company name',
          controller: _companyController,
          keyboardType: TextInputType.text,
          focusNode: _companyFocusNode,
          textInputAction: TextInputAction.next,
          required: true,
          validator: Validators.validateCompany,
          prefixIcon: const Icon(
            Icons.business_outlined,
            color: AppColors.mediumGrey,
          ),
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
        ),
        
        const SizedBox(height: 16),
        
        // Password
        PasswordTextField(
          label: 'Password',
          hintText: 'Create a strong password',
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          textInputAction: TextInputAction.next,
          required: true,
          validator: Validators.validatePassword,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
          },
        ),
        
        // Password Strength Indicator
        if (_showPasswordStrength) ...[
          const SizedBox(height: 8),
          PasswordStrengthIndicator(
            password: _passwordController.text,
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Confirm Password
        PasswordTextField(
          label: 'Confirm Password',
          hintText: 'Confirm your password',
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          textInputAction: TextInputAction.done,
          required: true,
          validator: (value) => Validators.validateConfirmPassword(
            value,
            _passwordController.text,
          ),
          onSubmitted: (_) => _handleRegister(),
        ),
      ],
    );
  }

  Widget _buildTermsAcceptance() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}