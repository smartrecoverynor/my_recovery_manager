import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/welcome/welcome_page.dart';
import '../features/authentication/login_page.dart';
import '../features/authentication/register_page.dart';
import '../features/assessment/assessment_page.dart';
import '../features/profile/profile_setup_page.dart';
import '../features/motivation/motivation_page.dart';
import '../features/recommendation/models/mrm_cra_assessment.dart';
import '../features/recommendation/recommendation_factors_page.dart';
import '../features/recommendation/recommendation_page.dart';
import '../features/goals/goal_selection_page.dart';
import '../features/goals/moderation_goal_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/today/today_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/map/map_page.dart';
import '../features/profile/profile_page.dart';
import '../features/statistics/statistics_export_page.dart';
import '../features/privacy/data_privacy_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({String initialLocation = '/dashboard'}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/data-privacy',
        builder: (context, state) => const DataPrivacyPage(),
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) => AssessmentPage(
          assessment: state.extra is MrmCraAssessment
              ? state.extra as MrmCraAssessment
              : null,
        ),
      ),
      GoRoute(
        path: '/motivation',
        builder: (context, state) => MotivationPage(
          assessment: state.extra is MrmCraAssessment
              ? state.extra as MrmCraAssessment
              : null,
        ),
      ),
      GoRoute(
        path: '/recommendation-factors',
        builder: (context, state) => RecommendationFactorsPage(
          assessment: state.extra is MrmCraAssessment
              ? state.extra as MrmCraAssessment
              : null,
        ),
      ),
      GoRoute(
        path: '/recommendation',
        builder: (context, state) => RecommendationPage(
          assessment: state.extra is MrmCraAssessment
              ? state.extra as MrmCraAssessment
              : null,
        ),
      ),
      GoRoute(
        path: '/goal-selection',
        builder: (context, state) {
          final assessmentCompleted = state.extra as bool? ?? true;
          return GoalSelectionPage(assessmentCompleted: assessmentCompleted);
        },
      ),
      GoRoute(
        path: '/moderation-goal',
        builder: (context, state) => const ModerationGoalPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(path: '/today', builder: (context, state) => const TodayPage()),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapPage()),
      GoRoute(
        path: '/statistics-export',
        builder: (context, state) => const StatisticsExportPage(),
      ),
    ],
  );
}
