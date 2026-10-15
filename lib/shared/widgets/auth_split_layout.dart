import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/official_logo.dart';
import 'package:flutter/material.dart';

class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout(
      {required this.form,
      required this.heroTitle,
      required this.heroSubtitle,
      this.heroBullets = const [],
      super.key});
  final Widget form;
  final String heroTitle, heroSubtitle;
  final List<String> heroBullets;
  static const double splitBreakpoint = 960;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final split = constraints.maxWidth >= splitBreakpoint;
        if (!split) {
          return Scaffold(
              backgroundColor: UiColors.background,
              body: SafeArea(
                  child: Center(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Row(children: [
                                      OfficialLogo(compact: true),
                                      SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(OfficialLogo.institution,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15)),
                                            SizedBox(height: 4),
                                            Text(OfficialLogo.system,
                                                style: TextStyle(
                                                    color:
                                                        UiColors.textSecondary,
                                                    fontSize: 13)),
                                          ]))
                                    ]),
                                    const SizedBox(height: 24),
                                    form,
                                  ]))))));
        }
        return Scaffold(
            body: Row(children: [
          Expanded(
              child: Container(
                  color: UiColors.surface,
                  padding: const EdgeInsets.all(48),
                  child: Center(
                      child: SingleChildScrollView(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const OfficialLogo(width: 380),
                                    const SizedBox(height: 28),
                                    Text(heroTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                height: 1.25)),
                                    const SizedBox(height: 12),
                                    Text(heroSubtitle,
                                        style: const TextStyle(
                                            color: UiColors.textSecondary,
                                            height: 1.5)),
                                    if (heroBullets.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      for (final item in heroBullets)
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Text(item,
                                                style: const TextStyle(
                                                    color: UiColors
                                                        .textSecondary)))
                                    ],
                                  ])))))),
          Expanded(
              child: Container(
                  color: UiColors.background,
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: form)))),
        ]));
      });
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
