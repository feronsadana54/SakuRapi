import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'tabs/daily_report_tab.dart';
import 'tabs/hutang_report_tab.dart';
import 'tabs/monthly_report_tab.dart';
import 'tabs/payday_report_tab.dart';
import 'tabs/piutang_report_tab.dart';
import 'tabs/range_report_tab.dart';
import 'tabs/yearly_report_tab.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const _tabs = [
    AppStrings.daily,
    AppStrings.monthly,
    AppStrings.yearly,
    AppStrings.dateRange,
    AppStrings.paydayCycle,
    AppStrings.hutang,
    AppStrings.piutang,
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.reports),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: _tabs
                .map((t) => Tab(
                      child: Text(
                        t,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
          ),
        ),
        body: const TabBarView(
          children: [
            DailyReportTab(),
            MonthlyReportTab(),
            YearlyReportTab(),
            RangeReportTab(),
            PaydayReportTab(),
            HutangReportTab(),
            PiutangReportTab(),
          ],
        ),
      ),
    );
  }
}
