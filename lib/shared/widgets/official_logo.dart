import 'package:flutter/material.dart';

/// Copies of the supplied official artwork; no tint, distortion or new symbols.
class OfficialLogo extends StatelessWidget {
  const OfficialLogo(
      {this.compact = false, this.white = false, this.width, super.key});
  final bool compact, white;
  final double? width;
  static const institution = 'Gobierno Autónomo Municipal de Sipe Sipe';
  static const system = 'Sistema de Gestión de Correspondencia';
  @override
  Widget build(BuildContext context) {
    final variant = compact ? 'crest' : 'horizontal';
    return Image.asset(
        'assets/branding/sipe_sipe_$variant${white ? '_white' : ''}.png',
        width: width ?? (compact ? 48 : 320),
        height: compact ? 58 : (width ?? 320) * 441 / 2033,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        semanticLabel: 'Escudo oficial del $institution');
  }
}
