import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight online brain for Fizzy: reuses the user's configured AI
/// provider (no tools) with a dedicated system prompt + conversation
/// context. Falls back gracefully with clear errors.
class FizzyOnline {
  final String baseUrl;
  final String model;
  final String apiKey;
  final String systemPrompt;

  FizzyOnline({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    required this.systemPrompt,
  });

  /// history: alternating user/assistant strings (prior turns), newest last.
  Future<String> ask(String question, List<List<String>> history, String grounded) async {
    final url = baseUrl.endsWith('/chat/completions')
        ? baseUrl
        : '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions';
    final msgs = <Map<String, String>>[
      {
        'role': 'system',
        'content': '$systemPrompt\n\nInternal knowledge base to ground your '
            'answers (cite only if relevant, do not dump verbatim):\n$grounded'
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
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': msgs,
            'temperature': 0.4,
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) {
      throw Exception('FizzyOnline ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    if (choices.isEmpty) return '';
    return ((choices.first['message']?['content']) as String?) ?? '';
  }
}
