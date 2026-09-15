import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';

extension DeviceContextExt on BuildContext {
  DeviceBreakpoint get deviceBreakpoint {
    final bp = ResponsiveBreakpoints.of(this);

    if (bp.equals('4K')) return DeviceBreakpoint.fourK;
    if (bp.equals('DESKTOP')) return DeviceBreakpoint.desktop;
    if (bp.equals('LAPTOP')) return DeviceBreakpoint.laptop;
    if (bp.equals('TABLET')) return DeviceBreakpoint.tablet;
    if (bp.equals('MOBILE')) return DeviceBreakpoint.mobile;
    if (bp.equals('SMALL_MOBILE')) return DeviceBreakpoint.smallMobile;

    return DeviceBreakpoint.mobile;
  }

  DeviceLongitude get deviceLongitude {
    final bp = ResponsiveBreakpoints.of(this);

    if (bp.equals('4K')) return DeviceLongitude.long;
    if (bp.equals('DESKTOP')) return DeviceLongitude.long;
    if (bp.equals('LAPTOP')) return DeviceLongitude.long;
    if (bp.equals('TABLET')) return DeviceLongitude.long;
    if (bp.equals('MOBILE')) return DeviceLongitude.small;
    if (bp.equals('SMALL_MOBILE')) return DeviceLongitude.small;

    return DeviceLongitude.small;
  }

  bool get isSmallScreen => deviceLongitude == DeviceLongitude.small;
  bool get isWideScreen => deviceLongitude == DeviceLongitude.long;
}
