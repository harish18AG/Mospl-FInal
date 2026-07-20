import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NeumorphicShape { flat, concave, convex, inset }

/// Premium Soft Card — repurposed from the old neumorphic widget.
/// Same public API (zero call-site changes required) but now renders
/// as a clean, warm ivory card with a subtle shadow and a soft beige border —
/// matching the MOSPL premium leather aesthetic.
class Neumorphic extends StatelessWidget {
  const Neumorphic({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.padding,
    this.margin,
    this.shape = NeumorphicShape.flat,
    this.isClickable = false,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final NeumorphicShape shape;
  final bool isClickable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.darkCard : AppColors.ivoryWhite;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.softBeige;

    // Soft premium shadow — single, subtle, warm-toned
    final List<BoxShadow> shadows = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : AppColors.espressoBrown.withValues(alpha: 0.07),
        offset: const Offset(0, 2),
        blurRadius: 10,
        spreadRadius: 0,
      ),
    ];

    // For inset style (e.g. search box, input containers) use a slightly
    // darker fill and no shadow to suggest depth without heavy neumorphism.
    final bool isInset = shape == NeumorphicShape.inset;
    final resolvedColor = isInset
        ? (isDark ? AppColors.darkInputFill : AppColors.creamInputFill)
        : cardColor;

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isInset ? null : shadows,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: child,
    );

    if (isClickable && onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.leatherBrown.withValues(alpha: 0.06),
          highlightColor: AppColors.leatherBrown.withValues(alpha: 0.04),
          child: container,
        ),
      );
    }

    return container;
  }
}
