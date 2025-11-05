import 'package:flutter/material.dart';
import '../constants/app_design.dart';

/// Standard info row widget với icon và text
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? textColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finalIconColor = iconColor ?? cs.onSurfaceVariant;
    final finalTextColor = textColor ?? cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: finalIconColor,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: finalTextColor,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Container cho info rows với background và border
class InfoContainer extends StatelessWidget {
  final List<Widget> children;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const InfoContainer({
    super.key,
    required this.children,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? cs.surfaceVariant.withOpacity(0.3);
    final border = borderColor ?? cs.outline.withOpacity(0.2);

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.container),
        border: borderColor != null 
            ? Border.all(color: border, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
