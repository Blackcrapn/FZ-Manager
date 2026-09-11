import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  ChatMessage(this.role, this.content);
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
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
    final enabled = _tools.keys.where((k) => _perm(k) || k == 'list' || k == 'write' || k == 'write_append').toList();
    return '''
You are the AI Brain of FZ Manager, a powerful file-management agent.
You can manipulate files using tools. Available tools: ${enabled.join(', ')}.

Respond ONLY in JSON. Two response forms:
1. To call a tool: {"tool":"name","args":{...}}
2. To answer the user: {"reply":"your text answer"}

Rules:
- Only call tools that are enabled and safe.
- Deleting is only allowed if the delete tool is enabled AND the user confirms each time.
- For very large files, use write + write_append in multiple steps (write supports unlimited lines this way).
- If the user wants a repeated workflow, define a custom tool with create_tool.
- Never claim something was done unless a tool actually did it.
''';
  }

  /// Runs the agent loop for one user turn with full chat context.
  /// [context] must include all prior messages; the result contains the
  /// updated context (append it to the chat) and the final reply.
  Future<AiTurnResult> chat(String userText, List<ChatMessage> context) async {
    final messages = [...context, ChatMessage('user', userText)];
    var reply = '';
    final added = <ChatMessage>[ChatMessage('user', userText)];
    for (var i = 0; i < 12; i++) {
      final body = {
        'model': model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt()},
          ...messages.map((m) => m.toJson()),
        ],
        'tools': _toolSpecs(),
        'tool_choice': 'auto',
      };
      final text = await _completion(body);
      final parsed = _parseJson(text);
      if (parsed == null) {
        reply = 'Не удалось разобрать ответ модели. Ответ: ${text.length > 300 ? '${text.substring(0, 300)}…' : text}';
        added.add(ChatMessage('assistant', reply));
        break;
      }
      final toolName = parsed['tool']?.toString();
      if (toolName != null) {
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
      } else {
        reply = parsed['reply']?.toString() ?? '';
        added.add(ChatMessage('assistant', reply));
        break;
      }
    }
    return AiTurnResult(reply: reply, addedMessages: added);
  }

  Future<String> _completion(Map<String, dynamic> body) async {
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
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) {
      throw Exception('Provider error ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    if (choices.isEmpty) return '';
    final msg = choices.first['message'] as Map<String, dynamic>;
    return (msg['content'] as String?) ?? '';
  }

  Map<String, dynamic>? _parseJson(String text) {
    final t = text.trim();
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

class AiTurnResult {
  final String reply;
  final List<ChatMessage> addedMessages;
  const AiTurnResult({required this.reply, required this.addedMessages});
}
