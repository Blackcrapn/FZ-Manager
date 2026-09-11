import 'dart:io';
import 'dart:math' as math;

/// Smart path suggestions and fuzzy correction of non-existent segments.
///
/// Feature: as the user types a path, the system checks which segments
/// exist and auto-completes/corrects the parts that are missing.
class PathService {
  /// Returns existing child directories of [parent] whose name starts
  /// with [prefix] (case-insensitive). Used for live auto-completion.
  static Future<List<String>> suggest(String parent, String prefix) async {
    final dir = Directory(parent);
    if (!await dir.exists()) return const [];
    final p = prefix.toLowerCase();
    final out = <String>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        if (e is! Directory) continue;
        final name = _base(e.path);
        if (name.toLowerCase().startsWith(p)) {
          out.add(name);
        }
      }
    } catch (_) {}
    out.sort();
    return out;
  }

  /// Given a (possibly incomplete) absolute path, returns the longest
  /// existing prefix plus the suggestions for the next segment.
  /// Returns null if no existing prefix could be determined.
  static Future<PathCompletion?> complete(String raw) async {
    final norm = raw.replaceAll('\\', '/').replaceAll(RegExp(r'/+'), '/');
    if (norm.isEmpty || !norm.startsWith('/')) return null     ;
    final segments = norm.split('/').where((s) => s.isNotEmpty).toList();
    // Walk down to find the longest existing directory prefix.
    var existing = '';
    for (var i = 0; i < segments.length; i++) {
      final candidate = '/' + segments.take(i + 1).join('/');
      if (await Directory(candidate).exists()) {
        existing = candidate;
      } else {
        break;
      }
    }
    if (existing.isEmpty) {
      if (await Directory('/').exists()) {
        existing = '/';
      } else {
        return null;
      }
    }
    // The remaining (non-existing) segment is what we are typing.
    final restSegments = segments.skip(_segments(existing)).toList();
    final lastTyped = restSegments.isEmpty ? '' : restSegments.last;
    final suggestions = await suggest(existing, lastTyped);
    return PathCompletion(
      existingPrefix: existing,
      typedSegment: lastTyped,
      suggestions: suggestions,
      completePath: existing,
    );
  }

  /// Corrects the final segment of a path if it does not exist, using
  /// a bounded Levenshtein distance against existing sibling directories.
  static Future<String?> fixLastSegment(String raw) async {
    final norm = raw.replaceAll('\\', '/');
    final cut = norm.lastIndexOf('/');
    if (cut < 1) return null;
    final parent = Directory(norm.substring(0, cut));
    if (!await parent.exists()) return null;
    final wanted = norm.substring(cut + 1).toLowerCase();
    if (wanted.isEmpty) return null;
    String? best;
    var bestScore = 4;
    await for (final e in parent.list(followLinks: false)) {
      if (e is! Directory) continue;
      final name = _base(e.path).toLowerCase();
      final d = _distance(wanted, name);
      if (d < bestScore) {
        bestScore = d;
        best = e.path;
      }
    }
    return bestScore <= 2 ? best : null;
  }

  static int _segments(String path) =>
      path.split('/').where((s) => s.isNotEmpty).length;

  static String _base(String path) {
    final parts = path.split('/');
    return parts.where((x) => x.isNotEmpty).lastOrNull ?? path;
  }

  static int _distance(String a, String b) {
    final n = a.length, m = b.length;
    if (n == 0) return m;
    if (m == 0) return n;
    var prev = List<int>.generate(m + 1, (i) => i);
    for (var i = 1; i <= n; i++) {
      final curr = List<int>.filled(m + 1, 0);
      curr[0] = i;
      for (var j = 1; j <= m; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = math.min(
          math.min(prev[j] + 1, curr[j - 1] + 1),
          prev[j - 1] + cost,
        );
      }
      prev = curr;
    }
    return prev[m];
  }
}

class PathCompletion {
  final String existingPrefix;
  final String typedSegment;
  final List<String> suggestions;
  final String completePath;
  PathCompletion({
    required this.existingPrefix,
    required this.typedSegment,
    required this.suggestions,
    required this.completePath,
  });
}
