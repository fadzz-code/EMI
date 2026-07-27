import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public privacy policy URL shown in Google Play Store listing and linked
/// from the in-app profile screens. Kept in one place so the URL stays
/// consistent across roles.
const String kPrivacyPolicyUrl = 'https://emi-kolaka.id/privacy';

/// Opens the privacy policy in an external browser. Shows a SnackBar if the
/// URL cannot be launched (e.g. no browser available).
Future<void> openPrivacyPolicy(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.parse(kPrivacyPolicyUrl);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Kebijakan privasi belum bisa dibuka. Coba lagi nanti.'),
      ),
    );
  }
}
