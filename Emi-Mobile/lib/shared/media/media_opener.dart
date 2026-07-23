import 'package:url_launcher/url_launcher.dart';

abstract interface class MediaOpener {
  Future<bool> open(String url);
}

class ExternalMediaOpener implements MediaOpener {
  const ExternalMediaOpener();

  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
