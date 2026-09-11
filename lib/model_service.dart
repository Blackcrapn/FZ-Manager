import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads a small GGUF model for local use into the app's documents dir.
class ModelService {
  final String url;
  final String fileName;

  ModelService({required this.url, String? fileName})
      : fileName = fileName ?? url.split('/').last;

  Future<String> localPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}$fileName';
  }

  Future<bool> exists() async => File(await localPath()).exists();

  Future<int> size() async => (await File(await localPath()).length());

  /// Downloads the model with progress callbacks. Returns the final file size.
  Future<int> download(void Function(double p) onProgress) async {
    final target = File(await localPath());
    final tmp = File('${target.path}.part');
    final req = http.Request('GET', Uri.parse(url));
    final client = http.Client();
    try {
      final res = await client.send(req);
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final total = int.tryParse(res.headers['content-length'] ?? '') ?? 0;
      final sink = tmp.openWrite();
      var received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
      await sink.close();
      await tmp.rename(target.path);
      return target.lengthSync();
    } catch (e) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> delete() async {
    final f = File(await localPath());
    if (await f.exists()) await f.delete();
  }
}
