import 'package:flutter/services.dart';

/// Thin wrapper around the native Android host channel.
class NativeService {
  static const _channel = MethodChannel('fz_manager/secure');
  static final NativeService instance = NativeService._();
  NativeService._();

  Future<bool> saveApiKey(String value) async {
    final ok = await _channel.invokeMethod<bool>('saveApiKey', {'value': value});
    return ok ?? false;
  }

  Future<bool> hasApiKey() async {
    final v = await _channel.invokeMethod<bool>('hasApiKey');
    return v ?? false;
  }

  Future<void> deleteApiKey() async {
    await _channel.invokeMethod('deleteApiKey');
  }

  Future<bool> isAllFilesAccess() async {
    final v = await _channel.invokeMethod<bool>('checkManageStorage');
    return v ?? false;
  }

  Future<bool> openManageStorageSettings() async {
    final ok = await _channel.invokeMethod<bool>('openManageStorageSettings');
    return ok ?? false;
  }

  Future<bool> isRootAvailable() async {
    final v = await _channel.invokeMethod<bool>('rootAvailable');
    return v ?? false;
  }

  Future<({bool ok, String stdout, String stderr})> rootExec(
    String command,
  ) async {
    final map = await _channel.invokeMapMethod<String, dynamic>(
      'rootExec',
      {'command': command},
    );
    return (
      ok: map?['ok'] == true,
      stdout: (map?['stdout'] as String?) ?? '',
      stderr: (map?['stderr'] as String?) ?? '',
    );
  }

  /// Reads a file through su (for files not accessible to the app).
  Future<({bool ok, String stdout, String stderr})> readRootFile(
    String path,
  ) async =>
      rootExec('head -c 65536 "$path"');

  /// Runs a shell script through su. Only for explicitly chosen files.
  Future<({bool ok, String stdout, String stderr})> runRootScript(
    String path,
  ) async =>
      rootExec('sh "$path"');

  Future<String> readFile(String path) async {
    final v = await _channel.invokeMethod<String>('readFile', {'path': path});
    return v ?? '';
  }

  Future<bool> writeFile(String path, String content) async {
    final ok = await _channel.invokeMethod<bool>(
      'writeFile',
      {'path': path, 'content': content},
    );
    return ok ?? false;
  }
}
