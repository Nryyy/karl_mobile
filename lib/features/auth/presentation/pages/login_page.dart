import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../../../core/providers/locale_provider.dart';
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

  List<PlatformFeature> get _features => [
        PlatformFeature(
          icon: Icons.folder_open_outlined,
          title: AppLocalizations.of(context)?.feature1Title ?? 'Document management',
          description: AppLocalizations.of(context)?.feature1Desc ?? 'Store and organize all documents in one place',
        ),
        PlatformFeature(
          icon: Icons.smart_toy_outlined,
          title: AppLocalizations.of(context)?.feature2Title ?? 'AI assistant',
          description: AppLocalizations.of(context)?.feature2Desc ?? 'Smart document processing and workflow automation',
        ),
        PlatformFeature(
          icon: Icons.people_outline,
          title: AppLocalizations.of(context)?.feature3Title ?? 'Teamwork',
          description: AppLocalizations.of(context)?.feature3Desc ?? 'Collaborate on documents with colleagues in real time',
        ),
        PlatformFeature(
          icon: Icons.security_outlined,
          title: AppLocalizations.of(context)?.feature4Title ?? 'Data security',
          description: AppLocalizations.of(context)?.feature4Desc ?? 'Enterprise-grade protection for your confidential documents',
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
      context.goNamed('documents', extra: userName);
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError(AppLocalizations.of(context)?.signInError ?? 'Unable to sign in. Please try again.');
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
      context.goNamed('documents', extra: userName);
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError(AppLocalizations.of(context)?.googleSignInError ?? 'Unable to sign in with Google.');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language selector top-right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Consumer(builder: (context, ref, _) {
                      return PopupMenuButton<String>(
                        tooltip: AppLocalizations.of(context)?.language ?? 'Language',
                        icon: const Icon(Icons.language),
                        onSelected: (value) async {
                          Locale? locale;
                          if (value == 'system') locale = null;
                          else locale = Locale(value);
                          await ref.read(localeProvider.notifier).setLocale(locale);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'system', child: Text('System')),
                          const PopupMenuItem(value: 'en', child: Text('English')),
                          const PopupMenuItem(value: 'uk', child: Text('Українська')),
                          const PopupMenuItem(value: 'pl', child: Text('Polski')),
                        ],
                      );
                    }),
                  ],
                ),
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
                        AppLocalizations.of(context)?.loginTitle ?? 'Sign in',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)?.loginSubtitle ?? 'Enter your credentials to access the platform',
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
                _buildSignUpSection(),
                const SizedBox(height: 24),

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
                  AppLocalizations.of(context)?.newUser ?? 'New user?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.createAccountSubtitle ?? 'Create an account in minutes',
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
            onPressed: () => context.goNamed('register'),
            child: Text(
              AppLocalizations.of(context)?.register ?? 'Register',
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
                '© 2024 Karl Platform. ${AppLocalizations.of(context)?.ok ?? ''}',
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
            _buildFooterLink(AppLocalizations.of(context)?.privacy ?? 'Privacy'),
            _buildFooterLink(AppLocalizations.of(context)?.terms ?? 'Terms'),
            _buildFooterLink(AppLocalizations.of(context)?.footerHelp ?? 'Help'),
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
