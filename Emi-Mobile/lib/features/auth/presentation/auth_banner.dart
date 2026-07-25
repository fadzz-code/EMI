import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import 'auth_style.dart';

enum AuthBannerTone { error, success }

/// Bordered, tinted message banner used on the auth screens, matching the
/// reference mock: soft tinted background, a solid 2px border in the same
/// hue, rounded corners, and no shadow.
class AuthBanner extends StatelessWidget {
  const AuthBanner({
    super.key,
    required this.message,
    this.tone = AuthBannerTone.error,
  });

  final String message;
  final AuthBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == AuthBannerTone.error;
    final background = isError
        ? AuthStyle.errorBackground
        : EmiColors.success.withValues(alpha: 0.16);
    final border = isError ? AuthStyle.errorText : EmiColors.success;
    final textColor = isError ? AuthStyle.errorText : AuthStyle.successText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.md,
        vertical: EmiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AuthStyle.fieldRadius),
        border: Border.all(color: border, width: 2),
      ),
      child: Text(
        message,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
