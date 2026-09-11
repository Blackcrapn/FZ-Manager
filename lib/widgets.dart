import 'package:flutter/material.dart';

/// App logo rendered from the asset, with gradient fallback.
class FzLogo extends StatelessWidget {
  const FzLogo({super.key, this.size = 74});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .28),
          gradient: const LinearGradient(
            colors: [Color(0xff7184ff), Color(0xff5140c8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [BoxShadow(color: Color(0x554654ff), blurRadius: 24)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * .28),
          child: Image.asset(
            'assets/logo/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.folder_rounded,
                size: size * .58, color: Colors.white),
          ),
        ),
      );
}

/// Fizzy avatar: art asset with soft glow ring.
class AssistantIcon extends StatelessWidget {
  const AssistantIcon({super.key, this.size = 52});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [Color(0xff37d6c0), Color(0xff536dfe)]),
          boxShadow: const [
            BoxShadow(color: Color(0x4437d6c0), blurRadius: 16),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/assistant/fizzy_avatar.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.auto_awesome_rounded,
              size: size * .52,
              color: Colors.white,
            ),
          ),
        ),
      );
}

/// Frosted glass card used across redesigned screens.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (color ?? scheme.primaryContainer).withValues(alpha: 0.10),
            (color ?? scheme.secondaryContainer).withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Section header with gradient accent bar.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff7184ff), Color(0xff37d6c0)],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ],
    );
  }
}

/// Beautiful empty state with art asset.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/hero/empty_folder.png',
                width: 200,
                height: 200,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.folder_open, size: 96)),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      );
}

String formatBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1048576) return '${(n / 1024).toStringAsFixed(1)} KB';
  if (n < 1073741824) return '${(n / 1048576).toStringAsFixed(1)} MB';
  return '${(n / 1073741824).toStringAsFixed(1)} GB';
}
