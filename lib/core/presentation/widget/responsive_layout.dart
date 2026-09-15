import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';

enum DeviceBreakpoint {
  smallMobile,
  mobile,
  tablet,
  laptop,
  desktop,
  fourK,
}

enum DeviceLongitude {
  small,
  long,
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    this.smallMobileBody = const SizedBox.shrink(),
    this.mobileBody = const SizedBox.shrink(),
    this.tabletBody = const SizedBox.shrink(),
    this.laptopBody = const SizedBox.shrink(),
    this.desktopBody = const SizedBox.shrink(),
    this.fourKBody = const SizedBox.shrink(),
    super.key,
  });

  final Widget smallMobileBody;
  final Widget mobileBody;
  final Widget tabletBody;
  final Widget laptopBody;
  final Widget desktopBody;
  final Widget fourKBody;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        final isSmallMobile = ResponsiveBreakpoints.of(context).equals('SMALL_MOBILE');
        final isMobile = ResponsiveBreakpoints.of(context).equals('MOBILE');
        final isTablet = ResponsiveBreakpoints.of(context).equals('TABLET');
        final isLaptop = ResponsiveBreakpoints.of(context).equals('LAPTOP');
        final isDesktop = ResponsiveBreakpoints.of(context).equals('DESKTOP');
        final is4K = ResponsiveBreakpoints.of(context).equals('4K');

        if (is4K) {
          if (fourKBody == const SizedBox.shrink()) return desktopBody;
          return fourKBody;
        } else if (isDesktop) {
          return desktopBody;
        } else if (isLaptop) {
          if (laptopBody == const SizedBox.shrink()) return desktopBody;
          return laptopBody;
        } else if (isTablet) {
          if (tabletBody == const SizedBox.shrink()) return desktopBody;
          return tabletBody;
        } else if (isMobile) {
          if (mobileBody == const SizedBox.shrink()) return desktopBody;
          return mobileBody;
        } else if (isSmallMobile) {
          if (smallMobileBody == const SizedBox.shrink()) return desktopBody;
          return smallMobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });

  final Widget Function(DeviceBreakpoint device, DeviceLongitude longitude) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        final isSmallMobile = ResponsiveBreakpoints.of(context).equals('SMALL_MOBILE');
        final isMobile = ResponsiveBreakpoints.of(context).equals('MOBILE');
        final isTablet = ResponsiveBreakpoints.of(context).equals('TABLET');
        final isLaptop = ResponsiveBreakpoints.of(context).equals('LAPTOP');
        final isDesktop = ResponsiveBreakpoints.of(context).equals('DESKTOP');
        final is4K = ResponsiveBreakpoints.of(context).equals('4K');

        if (is4K) {
          return builder(DeviceBreakpoint.fourK, DeviceLongitude.long);
        } else if (isDesktop) {
          return builder(DeviceBreakpoint.desktop, DeviceLongitude.long);
        } else if (isLaptop) {
          return builder(DeviceBreakpoint.laptop, DeviceLongitude.long);
        } else if (isTablet) {
          return builder(DeviceBreakpoint.tablet, DeviceLongitude.small);
        } else if (isMobile) {
          return builder(DeviceBreakpoint.mobile, DeviceLongitude.small);
        } else if (isSmallMobile) {
          return builder(DeviceBreakpoint.smallMobile, DeviceLongitude.small);
        } else {
          return builder(DeviceBreakpoint.mobile, DeviceLongitude.small);
        }
      },
    );
  }
}
