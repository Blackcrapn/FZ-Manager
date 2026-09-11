import 'package:flutter/material.dart';

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
      boxShadow: [BoxShadow(color: Color(0x554654ff), blurRadius: 24)],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.folder_rounded, size: size * .58, color: Colors.white),
        Positioned(
          right: size * .14,
          bottom: size * .15,
          child: Icon(
            Icons.bolt_rounded,
            size: size * .28,
            color: const Color(0xffffd76a),
          ),
        ),
      ],
    ),
  );
}

class AssistantIcon extends StatelessWidget {
  const AssistantIcon({super.key, this.size = 52});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xff37d6c0), Color(0xff536dfe)]),
    ),
    child: Icon(
      Icons.auto_awesome_rounded,
      size: size * .52,
      color: Colors.white,
    ),
  );
}

String formatBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1048576) return '${(n / 1024).toStringAsFixed(1)} KB';
  if (n < 1073741824) return '${(n / 1048576).toStringAsFixed(1)} MB';
  return '${(n / 1073741824).toStringAsFixed(1)} GB';
}
