import 'package:flutter/material.dart';
import '../constants/app_design.dart';

/// Standard card widget với style đồng bộ
class StandardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderSide? border;
  final VoidCallback? onTap;

  const StandardCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.border,
    this.onTap,
  });

  /// Card cho danh sách (History pages)
  const StandardCard.list({
    super.key,
    required this.child,
    this.padding,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.m),
    this.color,
    this.elevation = AppElevation.card,
    this.border,
    this.onTap,
  });

  /// Card cho thông tin (Form pages)
  const StandardCard.info({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.margin,
    this.color,
    this.elevation = AppElevation.none,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = color ?? 
        (elevation == 0 
            ? cs.surfaceVariant.withOpacity(0.3) 
            : null);

    final card = Card(
      elevation: elevation ?? AppElevation.card,
      margin: margin,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        side: border ?? 
            (elevation == 0 
                ? BorderSide(
                    color: cs.outline.withOpacity(0.2), 
                    width: 1,
                  )
                : BorderSide.none),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.l),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
