import 'dart:convert';
import 'package:http/http.dart' as http;
import 'hidden_prompts.dart';

/// Lightweight online brain for Fizzy: reuses the user's configured AI
/// provider (no tools) with a dedicated system prompt + conversation
/// context. Can also target a LOCAL OpenAI-compatible server that hosts a
/// downloaded GGUF (llama.cpp / PocketPal / LLMFarm). Falls back
/// gracefully with clear errors.
class FizzyOnline {
  final String baseUrl;
  final String model;
  final String apiKey;
  final bool isLocal;

  FizzyOnline({
    required this.baseUrl,
    required this.model,
    this.apiKey = '',
    this.isLocal = false,
  });

  String get systemPrompt => isLocal ? kFizzyLocalPrompt : kFizzySystemPrompt;

  /// history: alternating user/assistant turns (prior context), newest last.
  Future<String> ask(
    String question,
    List<List<String>> history,
    String grounded,
  ) async {
    final url = baseUrl.endsWith('/chat/completions')
        ? baseUrl
        : '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions';
    final msgs = <Map<String, String>>[
      {
        'role': 'system',
        'content': '$systemPrompt\n\nKnowledge base to ground your answers '
            '(use it, do not dump verbatim):\n$grounded'
      },
    ];
    final hist = history.length > 12
        ? history.sublist(history.length - 12)
        : history;
    for (final h in hist) {
      msgs.add({'role': h[0], 'content': h[1]});
    }
    msgs.add({'role': 'user', 'content': question});
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (!isLocal && apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': msgs,
            'temperature': 0.4,
            // Small context for mini local models.
            if (isLocal) 'max_tokens': 320,
          }),
        )
        .timeout(Duration(seconds: isLocal ? 120 : 90));
    if (res.statusCode != 200) {
      throw Exception('Fizzy${isLocal ? 'Local' : 'Online'} ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    if (choices.isEmpty) return '';
    final msg = choices.first['message'] as Map<String, dynamic>;
    var out = (msg['content'] as String?) ?? '';
    if (out.isEmpty) {
      out = (msg['reasoning_content'] as String?) ??
          (msg['reasoning'] as String?) ??
          '';
    }
    return out;
  }
}
