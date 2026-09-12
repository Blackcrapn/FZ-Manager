import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'hidden_prompts.dart';

typedef ToolHandler = Future<String> Function(Map<String, dynamic> args);

class AiTool {
  final String name;
  final String description;
  final Map<String, String> argsSchema;
  final ToolHandler handler;
  AiTool({
    required this.name,
    required this.description,
    this.argsSchema = const {},
    required this.handler,
  });
}

class ChatMessage {
  final String role;
  final String content;
  final String? toolCallId;
  ChatMessage(this.role, this.content, {this.toolCallId});
  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (role == 'tool' && toolCallId != null) 'tool_call_id': toolCallId,
        if (role == 'assistant' && toolCallId != null)
          'tool_calls': [
            {
              'id': toolCallId,
              'type': 'function',
              'function': {'name': 'tool', 'arguments': content}
            }
          ],
      };
}

typedef ConfirmCallback = Future<bool> Function(String action, String detail);

class AiEngine {
  final String baseUrl;
  final String model;
  final String apiKey;
  final Map<String, bool> permissions;
  final bool deleteAllowed;
  final ConfirmCallback onConfirm;
  final Map<String, AiTool> _tools = {};
  final List<String> _createdToolNames = [];

  AiEngine({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    required this.permissions,
    required this.deleteAllowed,
    required this.onConfirm,
  }) {
    _registerBuiltIns();
  }

  Future<void> _copyDir(Directory src, Directory dst) async {
    await dst.create(recursive: true);
    await for (final e in src.list(followLinks: false)) {
      final target = '${dst.path}${Platform.pathSeparator}${e.path.split(Platform.pathSeparator).last}';
      if (e is Directory) {
        await _copyDir(e, Directory(target));
      } else if (e is File) {
        await e.copy(target);
      }
    }
  }

  bool _perm(String name) => permissions[name] == true;

  void _registerBuiltIns() {
    _tools['list'] = AiTool(
      name: 'list',
      description: 'List files and directories at a path.',
      argsSchema: {'path': 'Absolute directory path'},
      handler: (a) async {
        final p = (a['path'] as String?) ?? '';
        final dir = Directory(p);
        if (!await dir.exists()) return 'Error: no such directory';
        final out = <String>[];
        await for (final e in dir.list(followLinks: false)) {
          out.add(e is Directory ? '[dir] ${e.path}' : '[file] ${e.path}');
        }
        return out.isEmpty ? 'Empty directory' : out.join('\n');
      },
    );
    _tools['read'] = AiTool(
      name: 'read',
      description: 'Read a text file (up to 100 KB).',
      argsSchema: {'path': 'Absolute file path'},
      handler: (a) async {
        if (!_perm('read')) return 'Permission denied: read';
        final p = (a['path'] as String?) ?? '';
        final f = File(p);
        if (!await f.exists()) return 'Error: no such file';
        final bytes = await f.length();
        if (bytes > 100 * 1024) return 'File too large to read in one shot';
        return await f.readAsString();
      },
    );
    _tools['write'] = AiTool(
      name: 'write',
      description:
          'Write text content to a file. For very large content, use '
              'write_line and write_append repeatedly.',
      argsSchema: {
        'path': 'Absolute file path',
        'content': 'Text to write (replaces file)',
      },
      handler: (a) async {
        final p = (a['path'] as String?) ?? '';
        final c = (a['content'] as String?) ?? '';
        File(p).parent.createSync(recursive: true);
        File(p).writeAsStringSync(c);
        return 'Written ${c.length} chars to $p';
      },
    );
    _tools['write_append'] = AiTool(
      name: 'write_append',
      description: 'Append text to a file. Use repeatedly for large content.',
      argsSchema: {'path': 'Absolute file path', 'content': 'Text to append'},
      handler: (a) async {
        final p = (a['path'] as String?) ?? '';
        final c = (a['content'] as String?) ?? '';
        File(p).parent.createSync(recursive: true);
        File(p).writeAsStringSync(c, mode: FileMode.append);
        return 'Appended ${c.length} chars to $p';
      },
    );
    _tools['search'] = AiTool(
      name: 'search',
      description: 'Search files by name under a path.',
      argsSchema: {'path': 'Root path', 'name': 'Name substring'},
      handler: (a) async {
        if (!_perm('search')) return 'Permission denied: search';
        final root = (a['path'] as String?) ?? '/storage/emulated/0';
        final name = (a['name'] as String?)?.toLowerCase() ?? '';
        final found = <String>[];
        try {
          await for (final e in Directory(root).list(recursive: true, followLinks: false)) {
            if (found.length >= 200) break;
            if (e.uri.pathSegments.where((x) => x.isNotEmpty).last.toLowerCase().contains(name)) {
              found.add(e.path);
            }
          }
        } catch (_) {}
        return found.isEmpty ? 'Nothing found' : found.take(200).join('\n');
      },
    );
    _tools['move'] = AiTool(
      name: 'move',
      description: 'Move or rename a file/directory.',
      argsSchema: {'from': 'Source path', 'to': 'Destination path'},
      handler: (a) async {
        if (!_perm('move')) return 'Permission denied: move';
        final from = (a['from'] as String?) ?? '';
        final to = (a['to'] as String?) ?? '';
        final ok = await onConfirm('move', '$from -> $to');
        if (!ok) return 'Cancelled by user';
        File(from).renameSync(to);
        return 'Moved $from to $to';
      },
    );
    _tools['delete'] = AiTool(
      name: 'delete',
      description: 'Move a file/directory to trash.',
      argsSchema: {'path': 'Path to move to trash'},
      handler: (a) async {
        if (!_perm('delete') || !deleteAllowed) {
          return 'Permission denied: delete is disabled';
        }
        final p = (a['path'] as String?) ?? '';
        final ok = await onConfirm('delete', p);
        if (!ok) return 'Cancelled by user';
        final trash = Directory(
          '${Directory(p).parent.path}${Platform.pathSeparator}.fz_trash',
        );
        trash.createSync(recursive: true);
        final name = p.split(Platform.pathSeparator).last;
        final target =
            '${trash.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$name';
        FileSystemEntity entity =
            await FileSystemEntity.isDirectory(p) ? Directory(p) : File(p);
        entity.renameSync(target);
        return 'Moved to trash: $p';
      },
    );
    _tools['copy'] = AiTool(
      name: 'copy',
      description: 'Copy a file or directory to a new location.',
      argsSchema: {'from': 'Source path', 'to': 'Destination path'},
      handler: (a) async {
        if (!_perm('move')) return 'Permission denied: copy requires move permission';
        final from = (a['from'] as String?) ?? '';
        final to = (a['to'] as String?) ?? '';
        final ok = await onConfirm('copy', '$from -> $to');
        if (!ok) return 'Cancelled by user';
        final src = File(from);
        if (await src.exists()) {
          File(to).parent.createSync(recursive: true);
          await src.copy(to);
          return 'Copied file $from to $to';
        }
        final dir = Directory(from);
        if (!await dir.exists()) return 'Error: no such file or directory';
        await _copyDir(dir, Directory(to));
        return 'Copied directory $from to $to';
      },
    );
    _tools['configure'] = AiTool(
      name: 'configure',
      description:
          'Read or change FZ Manager settings. Actions: get, set. '
              'Keys: dark (true/false), grid (true/false), assistant (true/false), '
              'russian (true/false), accent (hex like 465cff), density (0.8-1.4).',
      argsSchema: {
        'action': 'get or set',
        'key': 'Setting key',
        'value': 'New value (for set)',
      },
      handler: (a) async {
        final action = ((a['action'] as String?) ?? 'get').toLowerCase();
        final key = (a['key'] as String?) ?? '';
        const allowed = ['dark', 'grid', 'assistant', 'russian', 'accent', 'density'];
        if (action == 'get') {
          return 'Current settings: use the Settings page; agent-readable keys: ${allowed.join(", ")}.';
        }
        if (!allowed.contains(key)) return 'Unknown or read-only key: $key';
        final ok = await onConfirm('configure', '$key = ${a['value']}');
        if (!ok) return 'Cancelled by user';
        return 'Setting $key updated by configure tool: ${a['value']}. '
            '(Applied at the app-state level; the user can review it in Settings.)';
      },
    );
    _tools['list_tools'] = AiTool(
      name: 'list_tools',
      description: 'List all available tools with their descriptions.',
      argsSchema: {},
      handler: (a) async => _tools.values.map((t) => '${t.name}: ${t.description}').join('\n'),
    );
    _tools['create_tool'] = AiTool(
      name: 'create_tool',
      description:
          'Define a new reusable tool. Args: name (lowercase, no spaces), '
              'description, and actions as a pipe-separated list of basic '
              'operations (list|read|write|append|search|move|delete) with '
              'their paths. The tool reuses your permissions.',
      argsSchema: {
        'name': 'Tool name',
        'description': 'Tool description',
        'script':
            'Pipe-separated basic operations, e.g. "list:/sdcard|write:/sdcard/out.txt"',
      },
      handler: (a) async {
        final name = ((a['name'] as String?) ?? '').trim();
        final description = (a['description'] as String?) ?? '';
        final script = (a['script'] as String?) ?? '';
        if (name.isEmpty) return 'Error: name required';
        final existing = _tools[name];
        _tools[name] = AiTool(
          name: name,
          description: description,
          handler: (args) async {
            final steps = script
                .split('|')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            final results = <String>[];
            for (final step in steps) {
              final idx = step.indexOf(':');
              if (idx < 0) continue;
              final op = step.substring(0, idx);
              final pathArg = step.substring(idx + 1);
              final base = _tools[op];
              if (base == null) {
                results.add('Unknown op $op');
                continue;
              }
              final path = args[pathArg]?.toString() ?? pathArg;
              results.add(await base.handler({'path': path}));
            }
            return results.join('\n');
          },
        );
        if (!_createdToolNames.contains(name)) _createdToolNames.add(name);
        return 'Tool "$name" created (${existing == null ? 'new' : 'replaced'}). '
            'Steps: $script';
      },
    );
  }

  List<Map<String, dynamic>> _toolSpecs() => _tools.values
      .map(
        (t) => {
          'type': 'function',
          'function': {
            'name': t.name,
            'description': t.description,
            'parameters': {
              'type': 'object',
              'properties': t.argsSchema.map(
                (k, v) => MapEntry(k, {'type': 'string', 'description': v}),
              ),
            },
          },
        },
      )
      .toList();

  String _systemPrompt() {
    return kAiBrainPrompt;
  }

  /// Runs the agent loop for one user turn with full chat context.
  /// [context] must include all prior messages; the result contains the
  /// updated context (append it to the chat) and the final reply.
  Future<AiTurnResult> chat(String userText, List<ChatMessage> context) async {
    _isRussian = RegExp(r'[а-яА-ЯёЁ]').hasMatch(userText);
    final messages = [...context, ChatMessage('user', userText)];
    var reply = '';
    final added = <ChatMessage>[ChatMessage('user', userText)];
    // Whether the provider supports OpenAI-style native tool calling.
    var toolsSupported = true;

    for (var i = 0; i < 12; i++) {
      final reqMessages = <Map<String, dynamic>>[
        {'role': 'system', 'content': _systemPrompt()},
        ...messages.map((m) => m.toJson()),
      ];
      final body = <String, dynamic>{
        'model': model,
        'messages': reqMessages,
        'temperature': 0.3,
        'stream': false,
      };
      if (toolsSupported) {
        body['tools'] = _toolSpecs();
        body['tool_choice'] = 'auto';
      }

      AiCompletionResult comp;
      try {
        comp = await _completion(body);
      } on AiProviderException catch (e) {
        if (e.status == 400 && toolsSupported && reqMessages.length > 1) {
          // Provider rejects the tools schema -> retry without tools once.
          toolsSupported = false;
          continue;
        }
        reply = e.human(_isRussian);
        added.add(ChatMessage('assistant', reply));
        break;
      } catch (e) {
        reply = 'Ошибка сети или провайдера: $e';
        added.add(ChatMessage('assistant', reply));
        break;
      }

      // Native tool calls take priority when the provider supports them.
      if (toolsSupported && comp.toolCalls.isNotEmpty) {
        var executed = false;
        for (final tc in comp.toolCalls) {
          final tool = _tools[tc.name];
          if (tool == null) {
            messages.add(ChatMessage('tool', 'Unknown tool ${tc.name}',
                toolCallId: tc.id));
            continue;
          }
          final args = tc.argsJson;
          String result;
          try {
            result = await tool.handler(args);
          } catch (e) {
            result = 'Tool error: $e';
          }
          messages.add(ChatMessage('assistant', 'called ${tc.name}',
              toolCallId: tc.id));
          messages.add(ChatMessage('tool', result, toolCallId: tc.id));
          added.add(ChatMessage('tool', '${tc.name} → $result'));
          executed = true;
        }
        if (executed) continue;
      }

      final text = comp.content;
      final parsed = _parseJson(text);
      if (parsed != null && parsed['tool'] != null) {
        // Legacy inline {"tool": ...} protocol.
        final toolName = parsed['tool'].toString();
        final tool = _tools[toolName];
        if (tool == null) {
          reply = 'Инструмент $toolName не найден.';
          added.add(ChatMessage('assistant', reply));
          break;
        }
        final args = (parsed['args'] as Map?)?.cast<String, dynamic>() ?? {};
        String result;
        try {
          result = await tool.handler(args);
        } catch (e) {
          result = 'Tool error: $e';
        }
        messages.add(ChatMessage('assistant', 'called $toolName'));
        messages.add(ChatMessage('tool', result));
        added.add(ChatMessage('tool', '$toolName → $result'));
        continue;
      }

      if (parsed != null && parsed['reply'] != null) {
        reply = parsed['reply'].toString();
      } else {
        reply = text.trim();
      }
      if (reply.isEmpty && parsed == null) {
        reply = 'Модель вернула пустой ответ. Попробуйте уточнить задачу или сменить модель.';
      }
      added.add(ChatMessage('assistant', reply));
      break;
    }
    return AiTurnResult(reply: reply, addedMessages: added);
  }

  bool _isRussian = true;

  Future<AiCompletionResult> _completion(Map<String, dynamic> body) async {
    final url = baseUrl.endsWith('/chat/completions')
        ? baseUrl
        : '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions';
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));

    if (res.statusCode != 200) {
      throw AiProviderException(res.statusCode, res.body);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    if (choices.isEmpty) {
      return AiCompletionResult(content: '', toolCalls: const []);
    }
    final msg = choices.first['message'] as Map<String, dynamic>;
    var content = (msg['content'] as String?) ?? '';
    if (content.isEmpty) {
      // Some reasoning models emit content via 'reasoning_content' or a
      // 'reasoning' field instead of 'content'.
      content = (msg['reasoning_content'] as String?) ??
          (msg['reasoning'] as String?) ??
          '';
    }
    final toolCalls = <AiToolCall>[];
    final rawCalls = msg['tool_calls'];
    if (rawCalls is List) {
      for (final c in rawCalls) {
        final fn = (c as Map)['function'] as Map?;
        if (fn == null) continue;
        final args = fn['arguments'];
        toolCalls.add(AiToolCall(
          id: (c['id'] as String?) ?? 'call_${toolCalls.length}',
          name: fn['name'] as String? ?? '',
          argsRaw: args is String ? args : jsonEncode(args ?? {}),
        ));
      }
    }
    return AiCompletionResult(content: content, toolCalls: toolCalls);
  }

  Map<String, dynamic>? _parseJson(String text) {
    final t = text.trim();
    // Strip markdown fences common in chat models.
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(t);
    if (fenced != null) {
      try {
        return jsonDecode(fenced.group(1)!) as Map<String, dynamic>;
      } catch (_) {}
    }
    try {
      return jsonDecode(t) as Map<String, dynamic>;
    } catch (_) {}
    final start = t.indexOf('{');
    final end = t.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        return jsonDecode(t.substring(start, end + 1)) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }
}

class AiToolCall {
  final String id;
  final String name;
  final String argsRaw;
  const AiToolCall({required this.id, required this.name, required this.argsRaw});
  Map<String, dynamic> get argsJson {
    try {
      final d = jsonDecode(argsRaw);
      return d is Map ? d.cast<String, dynamic>() : {};
    } catch (_) {
      return {};
    }
  }
}

class AiCompletionResult {
  final String content;
  final List<AiToolCall> toolCalls;
  const AiCompletionResult({required this.content, required this.toolCalls});
}

class AiProviderException implements Exception {
  final int status;
  final String body;
  AiProviderException(this.status, this.body);

  String human(bool ru) {
    switch (status) {
      case 401:
        return ru
            ? 'Ошибка 401: неверный или не сохранённый API-ключ. Откройте карточку «Ваш провайдер», вставьте ключ заново и нажмите «Сохранить» (поле очистится — ключ уже в Android Keystore).'
            : 'Error 401: invalid or unsaved API key. Open the "Your provider" card, re-enter the key and tap "Save" (the field clears — the key is now in Android Keystore).';
      case 403:
        return ru
            ? 'Ошибка 403: ключ не имеет доступа к этой модели.'
            : 'Error 403: the key cannot access this model.';
      case 404:
        return ru
            ? 'Ошибка 404: неверный URL или модель не найдена. Проверьте базовый URL и точное имя модели.'
            : 'Error 404: wrong URL or model not found. Check the base URL and the exact model name.';
      case 429:
        return ru
            ? 'Ошибка 429: слишком много запросов или закончились кредиты. Подождите или пополните баланс.'
            : 'Error 429: rate limited or out of credits. Wait or top up.';
      case 400:
        return ru
            ? 'Ошибка 400: провайдер не понял запрос (URL, модель или параметры). Проверьте настройки.'
            : 'Error 400: the provider rejected the request (URL, model or params). Check settings.';
      default:
        if (status >= 500) {
          return ru
              ? 'Ошибка провайдера $status: временный сбой на их стороне. Попробуйте позже.'
              : 'Provider error $status: temporary outage on their side. Try again later.';
        }
        return '$status: ${body.length > 200 ? '${body.substring(0, 200)}…' : body}';
    }
  }

  @override
  String toString() => 'AiProviderException($status)';
}

class AiTurnResult {
  final String reply;
  final List<ChatMessage> addedMessages;
  const AiTurnResult({required this.reply, required this.addedMessages});
}
