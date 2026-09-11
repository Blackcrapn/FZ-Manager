import 'package:permission_handler/permission_handler.dart';
import 'native_service.dart';

/// Requests the permissions FZ Manager needs, from inside the app.
class PermissionService {
  /// Android 13+ runtime notification permission.
  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestMedia() async {
    final statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    return statuses.values.any((s) => s.isGranted);
  }

  /// All-files access cannot be granted via a dialog on Android 11+:
  /// we open the dedicated system settings page for the user.
  static Future<bool> requestAllFiles({bool openSettings = true}) async {
    if (await NativeService.instance.isAllFilesAccess()) return true;
    if (openSettings) {
      try {
        await NativeService.instance.openManageStorageSettings();
      } catch (_) {}
    }
    return false;
  }

  static Future<bool> hasAllFiles() async =>
      await NativeService.instance.isAllFilesAccess();

  static Future<Map<String, bool>> status() async {
    final allFiles = await NativeService.instance.isAllFilesAccess();
    final media = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    return {
      'allFiles': allFiles,
      'media': media.values.every((s) => s.isGranted),
    };
  }
}
