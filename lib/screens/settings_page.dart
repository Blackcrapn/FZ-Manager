import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../permission_service.dart';

const _accents = <String, Color>{
  '465cff': Color(0xff465cff),
  '7c4dff': Color(0xff7c4dff),
  '00b386': Color(0xff00b386),
  'ff7043': Color(0xffff7043),
  'ec407a': Color(0xffec407a),
  'fbc02d': Color(0xfffbc02d),
};

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});
  final AppState state;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SectionHeader(
          title: tr(s, 'Настройки', 'Settings'),
          subtitle: tr(s, 'Кастомизируйте FZ Manager под себя', 'Customize FZ Manager to your taste'),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name.isEmpty
                          ? tr(s, 'Профиль', 'Profile')
                          : '$s.name $s.surname'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(tr(s, 'Локальный профиль · данные только на устройстве',
                        'Local profile · data stays on device'),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: Text(tr(s, 'Тёмная тема', 'Dark theme')),
                value: s.dark,
                onChanged: (v) => s.dark = v),
              SwitchListTile(
                secondary: const Icon(Icons.grid_view_rounded),
                title: Text(tr(s, 'Сетка по умолчанию', 'Default grid view')),
                value: s.grid,
                onChanged: (v) => s.grid = v),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: Text(tr(s, 'Показывать скрытые файлы', 'Show hidden files')),
                value: s.showHidden,
                onChanged: (v) => s.showHidden = v),
              SwitchListTile(
                secondary: const Icon(Icons.auto_awesome),
                title: Text(tr(s, 'Подсказки Физзи', 'Fizzy tips')),
                value: s.assistant,
                onChanged: (v) => s.assistant = v),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(s, 'Язык', 'Language'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(tr(s, 'Русский', 'Russian'))),
                  ButtonSegment(value: false, label: Text(tr(s, 'Английский', 'English'))),
                ],
                selected: {s.russian},
                onSelectionChanged: (v) => s.russian = v.first,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionHeader(title: tr(s, 'Кастомизация', 'Customization')),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(s, 'Акцентный цвет', 'Accent color'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _accents.entries.map((e) {
                  final sel = s.accent == e.key;
                  return InkWell(
                    onTap: () => s.accent = e.key,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : Colors.transparent,
                          width: 3),
                        boxShadow: sel
                            ? [BoxShadow(color: e.value, blurRadius: 14, spreadRadius: 2)]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text(tr(s, 'Плотность интерфейса', 'UI density'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Slider(
                value: s.density,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                label: s.density.toStringAsFixed(1),
                onChanged: (v) => s.density = v),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: Text(tr(s, 'Разрешения', 'Permissions')),
            subtitle: Text(tr(s, 'Проверить и выдать «Все файлы»', 'Check and grant "All files"')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final has = await PermissionService.requestAllFiles();
              messenger.showSnackBar(SnackBar(
                content: Text(has
                    ? tr(s, 'Доступ уже выдан', 'Access already granted')
                    : tr(s, 'Включите «Все файлы» в настройках и вернитесь',
                        'Enable "All files" in settings and return'))));
            },
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  const FzLogo(size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FZ Manager',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(tr(s, 'Файловый менеджер нового поколения',
                          'A next-generation file manager'),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
