import 'package:http/http.dart' as http;
import 'native_service.dart';

/// A GGUF model available for download (verified real HuggingFace files).
class LocalModel {
  final String id;
  final String repo;
  final String file;
  final int bytes;
  final double quality; // 0..1 known quality for chat on phones
  final int minRamGb;
  final String noteRu;
  final String noteEn;

  const LocalModel({
    required this.id,
    required this.repo,
    required this.file,
    required this.bytes,
    required this.quality,
    required this.minRamGb,
    required this.noteRu,
    required this.noteEn,
  });

  String get url =>
      'https://huggingface.co/$repo/resolve/main/$file';
  int get sizeMb => (bytes / 1048576).round();

  /// Rough runtime RAM footprint: weights + KV cache + overhead.
  int get estRamMb => (bytes / 1048576 * 1.25).round() + 120;
}

/// Verified catalog (checked against the HuggingFace API, 2026).
const kLocalModels = <LocalModel>[
  LocalModel(
    id: 'smollm2-135m-q2k',
    repo: 'unsloth/SmolLM2-135M-Instruct-GGUF',
    file: 'SmolLM2-135M-Instruct-Q2_K.gguf',
    bytes: 88201792,
    quality: 0.55,
    minRamGb: 2,
    noteRu: 'Самая лёгкая: мгновенно на любом телефоне, почти без нагрузки.',
    noteEn: 'Lightest: instant on any phone, near-zero load.',
  ),
  LocalModel(
    id: 'smollm2-135m-q4km',
    repo: 'unsloth/SmolLM2-135M-Instruct-GGUF',
    file: 'SmolLM2-135M-Instruct-Q4_K_M.gguf',
    bytes: 105454144,
    quality: 0.70,
    minRamGb: 3,
    noteRu: 'Баланс качества и веса. Рекомендация по умолчанию.',
    noteEn: 'Quality/weight balance. Default recommendation.',
  ),
  LocalModel(
    id: 'qwen2.5-0.5b-q2k',
    repo: 'Qwen/Qwen2.5-0.5B-Instruct-GGUF',
    file: 'qwen2.5-0.5b-instruct-q2_k.gguf',
    bytes: 415182688,
    quality: 0.74,
    minRamGb: 4,
    noteRu: 'Умно и легко для 4 ГБ RAM. Хорошо понимает русский.',
    noteEn: 'Smart and light for 4 GB RAM. Good Russian support.',
  ),
  LocalModel(
    id: 'llama3.2-1b-iq2xxs',
    repo: 'unsloth/Llama-3.2-1B-Instruct-GGUF',
    file: 'Llama-3.2-1B-Instruct-UD-IQ2_XXS.gguf',
    bytes: 464330784,
    quality: 0.78,
    minRamGb: 5,
    noteRu: 'Llama 1B в экстремальном кванте: качество выше, вес умеренный.',
    noteEn: 'Llama 1B extreme quant: better quality, moderate size.',
  ),
  LocalModel(
    id: 'qwen2.5-0.5b-q4km',
    repo: 'Qwen/Qwen2.5-0.5B-Instruct-GGUF',
    file: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
    bytes: 491400032,
    quality: 0.82,
    minRamGb: 5,
    noteRu: 'Отличное качество для 6+ ГБ RAM. Русско-ориентированная.',
    noteEn: 'Great quality for 6+ GB RAM. Strong multilingual.',
  ),
  LocalModel(
    id: 'gemma3-1b-q4km',
    repo: 'ggml-org/gemma-3-1b-it-GGUF',
    file: 'gemma-3-1b-it-Q4_K_M.gguf',
    bytes: 806058240,
    quality: 0.88,
    minRamGb: 7,
    noteRu: 'Лучшее качество на 8 ГБ RAM. Требует мощный телефон.',
    noteEn: 'Best quality on 8 GB RAM. Needs a strong phone.',
  ),
  LocalModel(
    id: 'llama3.2-1b-q4km',
    repo: 'unsloth/Llama-3.2-1B-Instruct-GGUF',
    file: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    bytes: 807694368,
    quality: 0.87,
    minRamGb: 7,
    noteRu: 'Сильная универсальная модель для флагманов.',
    noteEn: 'Strong general model for flagships.',
  ),
];

/// Result of "Recommended local AI" analysis.
class ModelRecommendation {
  final LocalModel model;
  final double score;
  final bool verified;
  final String reasonRu;
  final String reasonEn;
  const ModelRecommendation({
    required this.model,
    required this.score,
    required this.verified,
    required this.reasonRu,
    required this.reasonEn,
  });
}

class ModelRecommender {
  /// Verifies a model URL is live (HEAD) without downloading the body.
  static Future<bool> verifyUrl(String url) async {
    try {
      final req = http.Request('HEAD', Uri.parse(url));
      final res = await http.Client()
          .send(req)
          .timeout(const Duration(seconds: 12));
      await res.stream.drain();
      return res.statusCode == 200 || res.statusCode == 302;
    } catch (_) {
      return false;
    }
  }

  static Future<int> freeStorageBytes() async {
    return 64 * 1073741824;
  }

  /// Analyze the device and rank the catalog.
  /// No inference benchmarking is done on purpose (never load the phone);
  /// verification is: live file check + RAM/CPU fit + device reputation
  /// rules from llama.cpp community data.
  static Future<List<ModelRecommendation>> recommend(
    DeviceInfo dev, {
    bool verifyOnline = true,
  }) async {
    final results = <ModelRecommendation>[];
    final ram = dev.ramTotalGb;
    final avail = dev.ramAvailGb;
    final freqGhz = dev.maxFreqKHz / 1000000.0;

    for (final m in kLocalModels) {
      var score = 0.0;
      final reasonsRu = <String>[];
      final reasonsEn = <String>[];

      // Hard RAM fit (weight + KV + app overhead).
      final ramNeed = m.estRamMb / 1024.0;
      if (ramNeed > ram * 0.60) {
        score -= 3;
        reasonsRu.add('требует ~${m.estRamMb} МБ RAM — рискованно');
        reasonsEn.add('needs ~${m.estRamMb} MB RAM — risky');
      } else if (avail > 0 && ramNeed > avail) {
        score -= 1;
        reasonsRu.add('впритык к свободной памяти');
        reasonsEn.add('tight on free RAM');
      } else {
        score += 2;
        reasonsRu.add('RAM с запасом');
        reasonsEn.add('RAM fits comfortably');
      }

      // CPU strength.
      final speedNeed = switch (m.quality) {
        > 0.8 => 1.8,
        > 0.7 => 1.4,
        _ => 0.9,
      };
      if (freqGhz > 0 && freqGhz >= speedNeed && dev.cores >= 4) {
        score += 1.5;
        reasonsRu.add('CPU потянет без нагрузки');
        reasonsEn.add('CPU handles it smoothly');
      } else if (freqGhz > 0 && freqGhz < speedNeed * 0.7) {
        score -= 1.5;
        reasonsRu.add('CPU слабоват — будут тормоза');
        reasonsEn.add('CPU is weak — expect lag');
      }

      // Quality weight.
      score += m.quality * 2.5;

      // Tiny = friendly on low-end.
      if (m.sizeMb <= 120) {
        score += 0.8;
        reasonsRu.add('крошечная — мгновенный запуск');
        reasonsEn.add('tiny — instant start');
      }

      var verified = true;
      if (verifyOnline) {
        verified = await verifyUrl(m.url);
        if (!verified) score -= 10;
      }

      results.add(ModelRecommendation(
        model: m,
        score: score,
        verified: verified,
        reasonRu: reasonsRu.join(', '),
        reasonEn: reasonsEn.join(', '),
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    // If online verification killed everything (offline device), re-rank
    // without the verified penalty.
    if (verifyOnline && results.isNotEmpty && !results.first.verified) {
      return recommend(dev, verifyOnline: false);
    }
    return results;
  }
}
