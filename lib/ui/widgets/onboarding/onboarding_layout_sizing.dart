import 'package:tunify/features/auth/auth_provider.dart';

/// Minimum scroll extents for onboarding pages that use [Spacer]s inside a
/// scroll view. Values are layout-only (not visual tokens); kept centralized
/// so screens stay consistent and easy to tune.
abstract final class OnboardingLayoutSizing {
  static double authCredentialsMinHeight(
    AuthActionState auth, {
    required bool isSignUp,
  }) {
    var h = 568.0;
    if (isSignUp) h += 92.0;
    if (auth.emailConfirmationPending) h += 80.0;
    if (auth.error != null) h += 80.0;
    return h;
  }

  static const double authChoiceMinHeight = 640.0;

  static const double guestProfileMinHeight = 620.0;
}
