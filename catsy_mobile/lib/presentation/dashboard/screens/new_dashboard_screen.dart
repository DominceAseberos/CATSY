import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/tables_section.dart';
import '../widgets/held_orders_section.dart';
import '../widgets/reservation_requests_section.dart';
import '../widgets/stamps_section.dart';
import '../widgets/reward_requests_section.dart';
import '../widgets/dashboard_bottom_bar.dart';

class NewDashboardScreen extends StatelessWidget {
  const NewDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          // Header (Online Status & Branding)
          const DashboardHeader(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
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
      bottomNavigationBar: const DashboardBottomBar(),
    );
  }
}
