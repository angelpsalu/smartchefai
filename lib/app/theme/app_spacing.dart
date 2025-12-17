import 'package:flutter/material.dart';

/// SmartChefAI Spacing System
/// Consistent spacing and sizing throughout the app
class AppSpacing {
  AppSpacing._();

  // Base spacing unit (4dp)
  static const double unit = 4.0;

  // Spacing values
  static const double xxs = 2.0;   // 0.5x
  static const double xs = 4.0;    // 1x
  static const double sm = 8.0;    // 2x
  static const double md = 16.0;   // 4x
  static const double lg = 24.0;   // 6x
  static const double xl = 32.0;   // 8x
  static const double xxl = 48.0;  // 12x
  static const double xxxl = 64.0; // 16x

  // Padding presets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // Vertical padding
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets screenPaddingLarge = EdgeInsets.symmetric(horizontal: lg);

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;
  static const double radiusFull = 999.0;

  // Border radius presets
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // Card sizes
  static const double cardHeightSm = 120.0;
  static const double cardHeightMd = 180.0;
  static const double cardHeightLg = 240.0;

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Avatar sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  // Button heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // Responsive breakpoints
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;
}

/// Gap widgets for consistent spacing
class Gap extends StatelessWidget {
  final double size;
  final Axis axis;

  const Gap(this.size, {super.key, this.axis = Axis.vertical});

  const Gap.xxs({super.key, this.axis = Axis.vertical}) : size = AppSpacing.xxs;
  const Gap.xs({super.key, this.axis = Axis.vertical}) : size = AppSpacing.xs;
  const Gap.sm({super.key, this.axis = Axis.vertical}) : size = AppSpacing.sm;
  const Gap.md({super.key, this.axis = Axis.vertical}) : size = AppSpacing.md;
  const Gap.lg({super.key, this.axis = Axis.vertical}) : size = AppSpacing.lg;
  const Gap.xl({super.key, this.axis = Axis.vertical}) : size = AppSpacing.xl;
  const Gap.xxl({super.key, this.axis = Axis.vertical}) : size = AppSpacing.xxl;
  const Gap.xxxl({super.key, this.axis = Axis.vertical}) : size = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axis == Axis.horizontal ? size : null,
      height: axis == Axis.vertical ? size : null,
    );
  }
}

/// Horizontal gap
class HGap extends Gap {
  const HGap(super.size, {super.key}) : super(axis: Axis.horizontal);
  const HGap.xxs({super.key}) : super(AppSpacing.xxs, axis: Axis.horizontal);
  const HGap.xs({super.key}) : super(AppSpacing.xs, axis: Axis.horizontal);
  const HGap.sm({super.key}) : super(AppSpacing.sm, axis: Axis.horizontal);
  const HGap.md({super.key}) : super(AppSpacing.md, axis: Axis.horizontal);
  const HGap.lg({super.key}) : super(AppSpacing.lg, axis: Axis.horizontal);
  const HGap.xl({super.key}) : super(AppSpacing.xl, axis: Axis.horizontal);
}
