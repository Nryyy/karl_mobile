import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../providers/login_provider.dart';
import '../../domain/auth_failure.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/login_form.dart';
import '../widgets/platform_features_section.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final authError = ref.watch(authErrorProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                    PopupMenuButton<String>(
                      tooltip: AppLocalizations.of(context)?.language ?? 'Language',
                      icon: const Icon(Icons.language),
                      onSelected: (value) async {
                        Locale? locale;
                        if (value == 'system') {
                          locale = null;
                        } else {
                          locale = Locale(value);
                        }
                        await ref.read(localeProvider.notifier).setLocale(locale);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'system', child: Text(AppLocalizations.of(context)?.languageSystemDefault ?? 'System')),
                        PopupMenuItem(value: 'en', child: Text(AppLocalizations.of(context)?.languageEnglish ?? 'English')),
                        PopupMenuItem(value: 'uk', child: Text(AppLocalizations.of(context)?.languageUkrainian ?? 'Українська')),
                        PopupMenuItem(value: 'pl', child: Text(AppLocalizations.of(context)?.languagePolish ?? 'Polski')),
                      ],
                    ),
                  ],
                ),

                // Logo and title section
                _buildHeaderSection(context),
                const SizedBox(height: 32),

                // Login form section
                _buildLoginFormSection(context, ref, isLoading, authError),
                const SizedBox(height: 32),

                // Sign up link
                _buildSignUpSection(context),
                const SizedBox(height: 24),

                // Platform features section
                PlatformFeaturesSection(features: _features(context)),
                const SizedBox(height: 24),

                // Footer
                _buildFooterSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primaryContainer],
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
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)?.appTitle ?? 'Karl',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          AppLocalizations.of(context)?.appTagline ?? 'Intelligent document circulation platform',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFormSection(BuildContext context, WidgetRef ref, bool isLoading, AuthFailure? authError) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
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
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.loginSubtitle ?? 'Enter your credentials to access the platform',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          LoginForm(
            onEmailPasswordSubmitted: (email, password) async {
              await ref.read(loginProvider.notifier).signInWithEmailAndPassword(email, password);
            },
            onGooglePressed: () => ref.read(loginProvider.notifier).signInWithGoogle(),
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
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
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.createAccountSubtitle ?? 'Create an account in minutes',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
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

  Widget _buildFooterSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: colorScheme.outlineVariant, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '© 2024 Karl Platform. ${AppLocalizations.of(context)?.ok ?? ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            _buildFooterLink(context, AppLocalizations.of(context)?.privacy ?? 'Privacy'),
            _buildFooterLink(context, AppLocalizations.of(context)?.terms ?? 'Terms'),
            _buildFooterLink(context, AppLocalizations.of(context)?.footerHelp ?? 'Help'),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {},
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  List<PlatformFeature> _features(BuildContext context) => [
        PlatformFeature(
          icon: Icons.folder_open_outlined,
          title: AppLocalizations.of(context)?.feature1_title ?? 'Document management',
          description: AppLocalizations.of(context)?.feature1_desc ?? 'Store and organize all documents in one place',
        ),
        PlatformFeature(
          icon: Icons.smart_toy_outlined,
          title: AppLocalizations.of(context)?.feature2_title ?? 'AI assistant',
          description: AppLocalizations.of(context)?.feature2_desc ?? 'Smart document processing and workflow automation',
        ),
        PlatformFeature(
          icon: Icons.people_outline,
          title: AppLocalizations.of(context)?.feature3_title ?? 'Teamwork',
          description: AppLocalizations.of(context)?.feature3_desc ?? 'Collaborate on documents with colleagues in real time',
        ),
        PlatformFeature(
          icon: Icons.security_outlined,
          title: AppLocalizations.of(context)?.feature4_title ?? 'Data security',
          description: AppLocalizations.of(context)?.feature4_desc ?? 'Enterprise-grade protection for your confidential documents',
        ),
      ];
}
