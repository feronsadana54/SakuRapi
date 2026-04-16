import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../presentation/providers/database_provider.dart';
import '../../../router/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _paydayController = TextEditingController(text: '25');
  String? _paydayError;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    _paydayController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _paydayError = null;
    });
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    // Validate payday input on the last page
    final input = _paydayController.text.trim();
    final parsed = int.tryParse(input);
    if (parsed == null || parsed < 1 || parsed > 31) {
      setState(() => _paydayError = AppStrings.paydayInvalid);
      return;
    }

    final repo = ref.read(settingsRepositoryProvider);
    await repo.setPaydayDate(parsed);
    await repo.setOnboardingComplete(true);

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  bool get _isLastPage => _currentPage == _totalPages - 1;

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              // ── Skip button ──────────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 8, right: padding),
                  child: TextButton(
                    onPressed: () async {
                      final repo = ref.read(settingsRepositoryProvider);
                      final router = GoRouter.of(context);
                      await repo.setOnboardingComplete(true);
                      if (!mounted) return;
                      router.go(AppRoutes.home);
                    },
                    child: Text(
                      AppStrings.skip,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppTypeScale.bodyText(context),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Pages ────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _OnboardingPage(
                      svgAsset: 'assets/images/onboarding_wallet.svg',
                      title: AppStrings.onboardingTitle1,
                      description: AppStrings.onboardingDesc1,
                    ),
                    _OnboardingPage(
                      svgAsset: 'assets/images/onboarding_chart.svg',
                      title: AppStrings.onboardingTitle2,
                      description: AppStrings.onboardingDesc2,
                    ),
                    _PaydayPage(
                      controller: _paydayController,
                      errorText: _paydayError,
                      onChanged: (v) {
                        setState(() => _paydayError = null);
                      },
                    ),
                  ],
                ),
              ),

              // ── Dots indicator ───────────────────────────────────────
              _PageIndicator(
                  total: _totalPages, current: _currentPage),
              SizedBox(height: AppSpacing.cardGap(context)),

              // ── Action button ────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _isLastPage ? AppStrings.done : AppStrings.next,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Onboarding info page ──────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final String svgAsset;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.svgAsset,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.pagePadding(context);
    final illustrationSize = context.isSmall ? 160.0 : 200.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG illustration
          SvgPicture.asset(
            svgAsset,
            width: illustrationSize,
            height: illustrationSize,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypeScale.heading(context),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypeScale.bodyText(context),
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payday setup page ─────────────────────────────────────────────────────────

class _PaydayPage extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _PaydayPage({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.pagePadding(context);
    final illustrationSize = context.isSmall ? 160.0 : 200.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/onboarding_calendar.svg',
            width: illustrationSize,
            height: illustrationSize,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.setPaydayTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypeScale.heading(context),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.setPaydayDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypeScale.bodyText(context),
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 160,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 2,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: AppTypeScale.statNumber(context),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.paydayHint,
                counterText: '',
                errorText: errorText,
                suffixText: 'hari',
                suffixStyle: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot indicator ─────────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  final int total;
  final int current;

  const _PageIndicator({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
