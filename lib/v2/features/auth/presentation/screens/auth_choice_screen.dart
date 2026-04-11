import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/screens/email_login_screen.dart';
import 'package:tunify/v2/features/welcome/presentation/widgets/tunify_logo.dart';

/// Auth Choice Screen - Spotify-inspired social login options
/// 
/// Same layout as Welcome screen:
/// - Logo at top center
/// - Header text
/// - Social buttons with left-aligned icon, centered text
/// 
/// Options: Google, Apple, Email/Phone (NO Facebook per user request)
/// 
/// Two modes:
/// - Login: "Sign in to Tunify" header, "Don't have an account? Sign up" footer
/// - Sign up: "Sign up to start listening" header, "Already have an account? Log in" footer
/// 
/// Per DESIGN.md:
/// - Background: #121212 (nearBlack)
/// - Outlined Pill buttons: transparent bg, 1px #7c7c7c border, 9999px radius
/// - Links: Brand Green (#1ed760)
enum AuthMode { login, signup }

class AuthChoiceScreen extends StatelessWidget {
  final AuthMode mode;

  const AuthChoiceScreen({
    super.key,
    required this.mode,
  });

  String get _headerText =>
      mode == AuthMode.login ? 'Sign in to Tunify' : 'Sign up to start listening';

  String get _footerPrefix => mode == AuthMode.login
      ? "Don't have an account? "
      : 'Already have an account? ';

  String get _footerAction => mode == AuthMode.login ? 'Sign up' : 'Log in';

  AuthMode get _toggleMode => mode == AuthMode.login ? AuthMode.signup : AuthMode.login;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.08;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Tunify Logo - Same as Welcome screen
              const TunifyLogo(size: 72),

              const SizedBox(height: AppSpacing.xxl),

              // Header - Section Title 24px/700 per DESIGN.md
              Text(
                _headerText,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle,
              ),

              const Spacer(flex: 3),

              // Continue with Google
              _buildSocialButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                onPressed: () {
                  // TODO: Google sign in
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Continue with Apple
              _buildSocialButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                onPressed: () {
                  // TODO: Apple sign in
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Continue with Email/Phone
              _buildSocialButton(
                label: 'Continue with Email or phone',
                icon: Icons.email_outlined,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EmailLoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Footer toggle link
              // DESIGN.md: Micro 10px/400, white with brand green action
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => AuthChoiceScreen(mode: _toggleMode),
                    ),
                  );
                },
                child: Text.rich(
                  TextSpan(
                    text: _footerPrefix,
                    style: AppTextStyles.micro.copyWith(
                      color: AppColors.white,
                    ),
                    children: [
                      TextSpan(
                        text: _footerAction,
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  /// Social login button per DESIGN.md Outlined Pill:
  /// - Full width
  /// - Background: transparent
  /// - Border: 1px solid #7c7c7c (lightBorder)
  /// - Text: #ffffff
  /// - Radius: 9999px (fullPill)
  /// - Height: 48px
  /// - Icon: LEFT aligned (16px from left)
  /// - Text: CENTERED
  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.xxxl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.fullPill),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppBorderRadius.fullPill),
          child: Container(
            width: double.infinity,
            height: AppSpacing.xxxl,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.lightBorder,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.fullPill),
            ),
            child: Row(
              children: [
                // Left padding + icon
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  child: Icon(
                    icon,
                    color: AppColors.white,
                    size: AppSpacing.xl,
                  ),
                ),
                // Centered text in remaining space
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.buttonUppercase.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Right padding to balance the icon
                const SizedBox(width: AppSpacing.xxxl - 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
