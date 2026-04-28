import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/firebase_auth_service.dart';
import '../../domain/auth_failure.dart';
import '../../domain/auth_service.dart';
import '../widgets/login_form.dart';
import '../widgets/platform_features_section.dart';

/// Main login page for Karl document circulation platform.
///
/// Provides a professional, informative interface for first-time users.
/// Combines login form with platform features overview.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final AuthService _authService = FirebaseAuthService();

  final List<PlatformFeature> _features = [
    PlatformFeature(
      icon: Icons.folder_open_outlined,
      title: 'Управління документами',
      description: 'Зберігайте та організуйте всі документи в одному місці',
    ),
    PlatformFeature(
      icon: Icons.smart_toy_outlined,
      title: 'AI-асистент',
      description:
          'Розумна обробка документів та автоматизація робочих процесів',
    ),
    PlatformFeature(
      icon: Icons.people_outline,
      title: 'Командна робота',
      description: 'Спільна робота над документами з колегами в реальному часі',
    ),
    PlatformFeature(
      icon: Icons.security_outlined,
      title: 'Безпека даних',
      description:
          'Захист на рівні підприємства для ваших конфіденційних документів',
    ),
  ];

  Future<void> _handleEmailPasswordLogin(String email, String password) async {
    setState(() => _isLoading = true);

    try {
      final userName = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      context.goNamed('welcome', queryParameters: {'name': userName});
    } on AuthFailure catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Не вдалося увійти. Спробуйте ще раз.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final userName = await _authService.signInWithGoogle();
      if (!mounted) {
        return;
      }
      context.goNamed('welcome', queryParameters: {'name': userName});
    } on AuthFailure catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Не вдалося увійти через Google.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and title section
                _buildHeaderSection(),
                const SizedBox(height: 32),

                // Login form section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Вхід до системи',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Введіть ваші облікові дані для доступу до платформи',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LoginForm(
                        onEmailPasswordSubmitted: _handleEmailPasswordLogin,
                        onGooglePressed: _handleGoogleLogin,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sign up link
                if (!isSmallScreen) ...[
                  _buildSignUpSection(),
                  const SizedBox(height: 24),
                ],

                // Platform features section
                PlatformFeaturesSection(features: _features),
                const SizedBox(height: 24),

                // Footer
                _buildFooterSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'K',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Karl',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Інтелектуальна платформа для документообігу',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Новий користувач?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Створіть аккаунт за кілька хвилин',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              // Navigate to sign up
            },
            child: Text(
              'Зареєструватися',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '© 2024 Karl Platform. Усі права захищені.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            _buildFooterLink('Конфіденційність'),
            _buildFooterLink('Умови використання'),
            _buildFooterLink('Допомога'),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {
        // Navigate to link
      },
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
