import 'package:flutter/material.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/presentation/dashboard/widgets/dashboard_header.dart';
import 'package:catsy_pos/presentation/dashboard/widgets/tables_section.dart';
import 'package:catsy_pos/presentation/dashboard/widgets/held_orders_section.dart';
import 'package:catsy_pos/presentation/dashboard/widgets/reservation_requests_section.dart';
import 'package:catsy_pos/presentation/dashboard/widgets/stamps_section.dart';
import 'package:catsy_pos/presentation/dashboard/widgets/reward_requests_section.dart';
import 'package:catsy_pos/presentation/dashboard/widgets/dashboard_bottom_bar.dart';

class NewDashboardScreen extends StatelessWidget {
  const NewDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          // Header (Online Status & Branding)
          DashboardHeader(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TablesSection(),
                  HeldOrdersSection(),
                  ReservationRequestsSection(),
                  StampsSection(),
                  RewardRequestsSection(),

                  // Bottom Padding to ensure last item is not hidden by sticky bar
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomBar(),
    );
  }
}
