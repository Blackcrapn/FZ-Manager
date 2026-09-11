import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import 'files_page.dart';
import 'insights_page.dart';
import 'root_page.dart';
import 'ai_page.dart';
import 'settings_page.dart';
import 'assistant_page.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.state});
  final AppState state;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = <Widget>[
      FilesPage(state: s),
      InsightsPage(state: s),
      RootPage(state: s),
      AiPage(state: s),
      AssistantPage(state: s),
      SettingsPage(state: s),
    ];
    return LayoutBuilder(
      builder: (c, x) {
        final wide = x.maxWidth >= 800;
        final dests = [
          _d(s, Icons.folder_outlined, Icons.folder, 'Файлы', 'Files'),
          _d(s, Icons.donut_large, Icons.donut_large, 'Обзор', 'Insights'),
          _d(s, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Root', 'Root'),
          _d(s, Icons.psychology_outlined, Icons.psychology, 'ИИ Мозг', 'AI Brain'),
          _d(s, Icons.auto_awesome_outlined, Icons.auto_awesome, 'Физзи', 'Fizzy'),
          _d(s, Icons.settings_outlined, Icons.settings, 'Настройки', 'Settings'),
        ];
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  NavigationRail(
                    extended: x.maxWidth > 1050,
                    leading: const Padding(
                      padding: EdgeInsets.all(12),
                      child: FzLogo(size: 48),
                    ),
                    destinations: dests,
                    selectedIndex: index,
                    onDestinationSelected: (v) => setState(() => index = v),
                  ),
                Expanded(child: pages[index]),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (v) => setState(() => index = v),
                  destinations: dests
                      .map(
                        (d) => NavigationDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: (d.label as Text).data!,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  NavigationRailDestination _d(AppState s, IconData i, IconData si, String ru, String en) =>
      NavigationRailDestination(
        icon: Icon(i),
        selectedIcon: Icon(si),
        label: Text(tr(s, ru, en)),
      );
}
