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

  /// Decrypts and returns the stored API key (null when absent).
  Future<String?> getApiKey() async {
    try {
      return await _channel.invokeMethod<String>('getApiKey');
    } catch (_) {
      return null;
    }
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

  /// Live "music island" notification while audio plays.
  Future<bool> startMusicEffect() async {
    final ok = await _channel.invokeMethod<bool>('startMusicEffect');
    return ok ?? false;
  }

  Future<bool> stopMusicEffect() async {
    final ok = await _channel.invokeMethod<bool>('stopMusicEffect');
    return ok ?? false;
  }

  Future<bool> isRootAvailable() async {
    final v = await _channel.invokeMethod<bool>('rootAvailable');
    return v ?? false;
  }

  /// Deep root probe: managers (Magisk/KernelSU/APatch/SuperSU), SELinux,
  /// kernel, binaries, write test. Returns null if the host channel is
  /// unavailable.
  Future<RootProbe?> rootProbe() async {
    try {
      final map = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('rootProbe')
          .timeout(const Duration(seconds: 15));
      if (map == null) return null;
      return RootProbe(map.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
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

/// Parsed result of the deep native root probe.
class RootProbe {
  final Map<String, dynamic> data;
  RootProbe(this.data);

  bool get rootGranted => data['rootGranted'] == true;
  String get manager => data['manager']?.toString() ?? 'None';
  bool get hasMagisk => data['hasMagisk'] == true;
  bool get hasKernelSU => data['hasKernelSU'] == true;
  bool get hasAPatch => data['hasAPatch'] == true;
  bool get hasSuperSU => data['hasSuperSU'] == true;
  String get magiskVersion => data['magiskVersion']?.toString() ?? '';
  bool get canWrite => data['canWrite'] == true;
  bool get canRemount => data['canRemount'] == true;
  String get kernel => data['kernel']?.toString() ?? '';
  String get androidVersion => data['androidVersion']?.toString() ?? '';
  String get device => data['device']?.toString() ?? '';
  String get selinux => data['selinux']?.toString() ?? '';
  String get idOutput => data['idOutput']?.toString() ?? '';
  List<String> get suBinaries =>
      (data['suBinaries'] as List?)?.map((e) => e.toString()).toList() ?? [];
  List<String> get managerApps =>
      (data['managerApps'] as List?)?.map((e) => e.toString()).toList() ?? [];
  bool get hasKsud => data['ksud'] == true;

  /// Human-readable verdict for the Root section.
  String verdict(bool russian) {
    if (rootGranted) {
      final mgr = manager == 'None'
          ? (russian ? 'root' : 'root')
          : manager;
      final w = canWrite
          ? (russian ? ', запись доступна' : ', writable')
          : (russian ? ', только чтение' : ', read-only');
      return russian
          ? 'Root подтверждён: $mgr$w'
          : 'Root verified: $mgr$w';
    }
    if (hasMagisk || hasKernelSU || hasAPatch || hasSuperSU ||
        managerApps.isNotEmpty || suBinaries.isNotEmpty) {
      return russian
          ? 'Root-менеджер найден ($manager), но su не дал uid=0 — выдайте разрешение в приложении менеджера'
          : 'Root manager found ($manager), but su did not grant uid=0 — approve the request in its app';
    }
    return russian ? 'Root не обнаружен' : 'Root not found';
  }

  String iconKind() {
    if (rootGranted) return 'ok';
    if (hasMagisk) return 'magisk';
    if (hasKernelSU) return 'ksu';
    if (hasAPatch) return 'apatch';
    if (hasSuperSU || managerApps.contains('SuperSU')) return 'supersu';
    if (suBinaries.isNotEmpty) return 'su_partial';
    return 'none';
  }
}
