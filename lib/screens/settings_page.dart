import 'package:flutter/material.dart';
import '../app.dart';

const _accents = <String, Color>{
  '465cff': Color(0xff465cff),
  '7c4dff': Color(0xff7c4dff),
  '00b386': Color(0xff00b386),
  'ff7043': Color(0xffff7043),
  'ec407a': Color(0xffec407a),
  'fbc02d': Color(0xfffbc02d),
};

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(tr(state, 'Настройки', 'Settings'),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ListTile(
        leading: const Icon(Icons.person),
        title: Text(state.name.isEmpty
            ? tr(state, 'Профиль', 'Profile')
            : '${state.name} ${state.surname}'),
        subtitle: Text(tr(state, 'Локальный профиль', 'Local profile')),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.dark_mode_outlined),
        title: Text(tr(state, 'Тёмная тема', 'Dark theme')),
        value: state.dark,
        onChanged: (v) => state.dark = v,
      ),
      SwitchListTile(
        secondary: const Icon(Icons.grid_view),
        title: Text(tr(state, 'Сетка по умолчанию', 'Default grid view')),
        value: state.grid,
        onChanged: (v) => state.grid = v,
      ),
      SwitchListTile(
        secondary: const Icon(Icons.visibility_outlined),
        title: Text(tr(state, 'Показывать скрытые файлы', 'Show hidden files')),
        value: state.showHidden,
        onChanged: (v) => state.showHidden = v,
      ),
      SwitchListTile(
        secondary: const Icon(Icons.auto_awesome),
        title: Text(tr(state, 'Подсказки Физзи', 'Fizzy tips')),
        value: state.assistant,
        onChanged: (v) => state.assistant = v,
      ),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(tr(state, 'Язык', 'Language')),
        trailing: DropdownButton<bool>(
          value: state.russian,
          items: const [
            DropdownMenuItem(value: true, child: Text('Русский')),
            DropdownMenuItem(value: false, child: Text('English')),
          ],
          onChanged: (v) {
            if (v != null) state.russian = v;
          },
        ),
      ),
      const Divider(),
      Text(tr(state, 'Кастомизация', 'Customization'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      ListTile(
        leading: const Icon(Icons.palette_outlined),
        title: Text(tr(state, 'Акцентный цвет', 'Accent color')),
        trailing: Wrap(
          spacing: 6,
          children: _accents.entries
              .map((e) => InkWell(
                    onTap: () => state.accent = e.key,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                        border: state.accent == e.key
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.zoom_out_map),
        title: Text(tr(state, 'Плотность интерфейса', 'UI density')),
        subtitle: Slider(
          value: state.density,
          min: 0.8,
          max: 1.4,
          divisions: 6,
          label: state.density.toStringAsFixed(2),
          onChanged: (v) => state.density = v,
        ),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('FZ Manager'),
        subtitle: Text(tr(
          state,
          'Файловый менеджер нового поколения с Root и ИИ Мозгом.',
          'Next-generation file manager with Root and AI Brain.',
        )),
      ),
    ],
  );
}
