import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout({
    required this.form,
    required this.heroTitle,
    required this.heroSubtitle,
    this.heroBullets = const [],
    super.key,
  });

  final Widget form;
  final String heroTitle;
  final String heroSubtitle;
  final List<String> heroBullets;

  /// Breakpoint mínimo para dividir en 2 paneles (Hero + Formulario).
  /// En anchos menores a 960px cada mitad tendría menos de 480px,
  /// lo que comprime y trunca textos y botones.
  static const double splitBreakpoint = 960.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= splitBreakpoint;

        if (!isSplit) {
          final isMobile = constraints.maxWidth < 480;
          return Scaffold(
            backgroundColor: UiColors.background,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 24 : 36,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _CompactLogoMark(),
                        const SizedBox(height: 24),
                        form,
                        const SizedBox(height: 20),
                        const Text(
                          'Gobierno Autónomo Municipal de Sipe Sipe',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: UiColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: AppDecorations.heroBackground,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 40,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _LogoMark(),
                            const SizedBox(height: 48),
                            Text(
                              heroTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              heroSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                            ),
                            if (heroBullets.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              ...heroBullets.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.92),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 40),
                            Text(
                              'Gobierno Autónomo Municipal de Sipe Sipe',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: UiColors.background,
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: form,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: AppDecorations.borderRadiusMd,
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAM SIPE SIPE',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
              ),
              Text(
                'Correspondencia institucional',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactLogoMark extends StatelessWidget {
  const _CompactLogoMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: UiColors.primary.withOpacity(0.12),
            borderRadius: AppDecorations.borderRadiusMd,
            border: Border.all(color: UiColors.primary.withOpacity(0.25)),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: UiColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAM SIPE SIPE',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: UiColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Correspondencia institucional',
                style: TextStyle(
                  color: UiColors.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.surfaceCard(),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: UiColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
