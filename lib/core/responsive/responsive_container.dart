import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Constrains and centers content on tablet screens (720dp+).
/// On phones it is transparent and adds no constraints.
///
/// Wrap the main content column of each screen with this widget.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;

  const ResponsiveContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.isTablet) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: child,
      ),
    );
  }
}
