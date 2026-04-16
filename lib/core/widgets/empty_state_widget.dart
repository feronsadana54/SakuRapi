import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../responsive/breakpoints.dart';

/// Generic empty-state widget with icon (or SVG asset), title, subtitle, and optional action.
///
/// If [svgAsset] is provided it is shown instead of the [icon]-in-circle.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  /// Path to an SVG asset in `assets/images/`. When set, replaces the icon.
  final String? svgAsset;

  const EmptyStateWidget({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.svgAsset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = context.isSmall ? 64.0 : 80.0;
    final svgSize  = context.isSmall ? 120.0 : 148.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset!,
                width: svgSize,
                height: svgSize,
                fit: BoxFit.contain,
              )
            else
              Container(
                width: iconSize,
                height: iconSize,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize * 0.5, color: AppColors.primary),
              ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
