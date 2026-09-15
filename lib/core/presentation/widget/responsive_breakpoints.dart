import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveBreakpointsConfig {
  static Widget builder(BuildContext context, Widget? child) {
    return ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(start: 0, end: 375, name: 'SMALL_MOBILE'),
        Breakpoint(start: 376, end: 767, name: 'MOBILE'),
        Breakpoint(start: 768, end: 1024, name: 'TABLET'),
        Breakpoint(start: 1025, end: 1440, name: 'LAPTOP'),
        Breakpoint(start: 1441, end: 1920, name: 'DESKTOP'),
        Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      ],
      child: child!,
    );
  }
}
