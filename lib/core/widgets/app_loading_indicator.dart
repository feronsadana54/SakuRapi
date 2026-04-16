import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Full-screen centered loading indicator used by all async screens.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
