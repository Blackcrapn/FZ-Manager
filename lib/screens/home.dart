import 'dart:ui';
import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../permission_service.dart';
import '../native_service.dart';
import 'files_page.dart';
import 'insights_page.dart';
import 'root_page.dart';
import 'kernel_page.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await PermissionService.requestNotifications();
      if (granted && widget.state.musicIsland) {
        await NativeService.instance.startMusicEffect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = <Widget>[
      FilesPage(state: s),
      InsightsPage(state: s),
      KernelPage(state: s),
      RootPage(state: s),
      AiPage(state: s),
      AssistantPage(state: s),
      SettingsPage(state: s),
    ];
    return LayoutBuilder(
      builder: (c, x) {
        final wide = x.maxWidth >= 800;
        final scheme = Theme.of(context).colorScheme;
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
                    destinations: [
                      _d(s, Icons.folder_outlined, Icons.folder, 'Файлы', 'Files'),
                      _d(s, Icons.donut_large, Icons.donut_large, 'Обзор', 'Insights'),
                      _d(s, Icons.memory_rounded, Icons.memory_rounded, 'Ядро', 'Kernel'),
                      _d(s, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Root', 'Root'),
                      _d(s, Icons.psychology_outlined, Icons.psychology, 'ИИ Мозг', 'AI Brain'),
                      _d(s, Icons.auto_awesome_outlined, Icons.auto_awesome, 'Физзи', 'Fizzy'),
                      _d(s, Icons.settings_outlined, Icons.settings, 'Настройки', 'Settings'),
                    ],
                    selectedIndex: index,
                    onDestinationSelected: (v) => setState(() => index = v),
                  ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.06),
                          scheme.surface,
                        ],
                      ),
                    ),
                    child: pages[index],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide ? null : LiquidGlassDock(
            index: index,
            onChanged: (v) => setState(() => index = v),
            items: [
              _DockItem(icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded, label: tr(s, 'Файлы', 'Files')),
              _DockItem(icon: Icons.donut_large, activeIcon: Icons.donut_large, label: tr(s, 'Обзор', 'Insights')),
              _DockItem(icon: Icons.memory_outlined, activeIcon: Icons.memory_rounded, label: tr(s, 'Ядро', 'Kernel')),
              _DockItem(icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings_rounded, label: 'Root'),
              _DockItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, label: tr(s, 'ИИ Мозг', 'AI Brain')),
              _DockItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: tr(s, 'Физзи', 'Fizzy')),
              _DockItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: tr(s, 'Настройки', 'Settings')),
            ],
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

class _DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _DockItem({required this.icon, required this.activeIcon, required this.label});
}

/// Liquid Glass bottom dock: frosted blur capsule with animated indicator.
class LiquidGlassDock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<_DockItem> items;
  const LiquidGlassDock({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.14),
                    scheme.secondaryContainer.withValues(alpha: 0.10),
                  ],
                ),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (i) {
                    final it = items[i];
                    final active = i == index;
                    return _DockButton(
                      item: it,
                      active: active,
                      scheme: scheme,
                      onTap: () => onChanged(i),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final _DockItem item;
  final bool active;
  final ColorScheme scheme;
  final VoidCallback onTap;
  const _DockButton({
    required this.item,
    required this.active,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? scheme.primaryContainer.withValues(alpha: 0.65)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: active
                ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.25), blurRadius: 14)]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: active ? 11.5 : 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
