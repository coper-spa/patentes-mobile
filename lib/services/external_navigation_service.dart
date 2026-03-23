import 'package:url_launcher/url_launcher.dart';

import '../core/errors/app_exception.dart';

class ExternalNavigationService {
  Future<void> openWaze(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
    );
    await _open(uri);
  }

  Future<void> _open(Uri uri) async {
    final canOpen = await canLaunchUrl(uri);
    if (!canOpen) {
      throw const AppException('No se pudo abrir la aplicacion de navegacion.');
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw const AppException('No se pudo iniciar la navegacion.');
    }
  }
}
