import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One message inside an AI Brain chat.
class AiMessage {
  final String role; // user | assistant
  final String content;
  final DateTime created;
  AiMessage({required this.role, required this.content, DateTime? created})
      : created = created ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'created': created.toIso8601String(),
      };
  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
        role: j['role'] as String,
        content: j['content'] as String,
        created: DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A persistent chat with the AI Brain.
class AiChat {
  final String id;
  String title;
  final List<AiMessage> messages;
  DateTime created;
  DateTime updated;
  AiChat({required this.id, required this.title, List<AiMessage>? messages, DateTime? created, DateTime? updated})
      : messages = messages ?? [],
        created = created ?? DateTime.now(),
        updated = updated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };
  factory AiChat.fromJson(Map<String, dynamic> j) => AiChat(
        id: j['id'] as String,
        title: j['title'] as String,
        messages: (j['messages'] as List? ?? [])
            .map((m) => AiMessage.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        created: DateTime.tryParse(j['created'] as String? ?? ''),
        updated: DateTime.tryParse(j['updated'] as String? ?? ''),
      );
}

/// Stores AI Brain chats locally (JSON in SharedPreferences).
class ChatService {
  static const _key = 'fz_ai_chats';
  final SharedPreferences _p;
  ChatService._(this._p);

  static Future<ChatService> load() async =>
      ChatService._(await SharedPreferences.getInstance());

  List<AiChat> loadChats() {
    final raw = _p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((c) => AiChat.fromJson((c as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChats(List<AiChat> chats) async {
    await _p.setString(
        _key, jsonEncode(chats.map((c) => c.toJson()).toList()));
  }
}
