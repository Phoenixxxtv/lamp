import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/complete_profile_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/post_detail_screen.dart';
import '../../features/community/screens/new_post_screen.dart';
import '../../features/habits/screens/habits_screen.dart';
import '../../features/habits/screens/habit_detail_screen.dart';
import '../../features/habits/screens/create_habit_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../features/tasks/screens/task_detail_screen.dart';
import '../../features/tasks/screens/create_task_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../widgets/main_scaffold.dart';

/// Route names for navigation
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String community = '/community';
  static const String habits = '/habits';
  static const String tasks = '/tasks';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String newPost = '/community/new';
  static const String postDetail = '/community/:id';
  static const String habitDetail = '/habits/:id';
  static const String createHabit = '/habits/new';
  static const String taskDetail = '/tasks/:id';
  static const String createTask = '/tasks/new';
}

/// Router provider that depends on auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final needsProfile = authState.status == AuthStatus.needsProfileCompletion;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      final isOnCompleteProfile = state.matchedLocation == AppRoutes.completeProfile;

      // Allow splash to handle initial navigation
      if (isOnSplash) return null;

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !needsProfile && !isOnLogin) {
        return AppRoutes.login;
      }

      // If needs profile completion and not on that page
      if (needsProfile && !isOnCompleteProfile) {
        return AppRoutes.completeProfile;
      }

      // If logged in and on login/complete-profile, go to home
      if (isLoggedIn && (isOnLogin || isOnCompleteProfile)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash screen (initial route)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login screen
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Complete profile screen
      GoRoute(
        path: AppRoutes.completeProfile,
        name: 'completeProfile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.community,
            name: 'community',
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: AppRoutes.habits,
            name: 'habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            name: 'tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Notifications (outside shell)
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // New post (outside shell)
      GoRoute(
        path: AppRoutes.newPost,
        name: 'newPost',
        builder: (context, state) => const NewPostScreen(),
      ),

      // Post detail (outside shell)
      GoRoute(
        path: AppRoutes.postDetail,
        name: 'postDetail',
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),

      // Create habit (outside shell)
      GoRoute(
        path: AppRoutes.createHabit,
        name: 'createHabit',
        builder: (context, state) => const CreateHabitScreen(),
      ),

      // Habit detail (outside shell)
      GoRoute(
        path: AppRoutes.habitDetail,
        name: 'habitDetail',
        builder: (context, state) {
          final assignmentId = state.pathParameters['id']!;
          return HabitDetailScreen(assignmentId: assignmentId);
        },
      ),

      // Create task (outside shell)
      GoRoute(
        path: AppRoutes.createTask,
        name: 'createTask',
        builder: (context, state) => const CreateTaskScreen(),
      ),

      // Task detail (outside shell)
      GoRoute(
        path: AppRoutes.taskDetail,
        name: 'taskDetail',
        builder: (context, state) {
          final assignmentId = state.pathParameters['id']!;
          return TaskDetailScreen(assignmentId: assignmentId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Helper class to refresh router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this.ref) {
    ref.listen(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}

/// Legacy router for backwards compatibility (used by main.dart)
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      name: 'completeProfile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.community,
          name: 'community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: AppRoutes.habits,
          name: 'habits',
          builder: (context, state) => const HabitsScreen(),
        ),
        GoRoute(
          path: AppRoutes.tasks,
          name: 'tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.newPost,
      name: 'newPost',
      builder: (context, state) => const NewPostScreen(),
    ),
    GoRoute(
      path: AppRoutes.postDetail,
      name: 'postDetail',
      builder: (context, state) {
        final postId = state.pathParameters['id']!;
        return PostDetailScreen(postId: postId);
      },
    ),
    GoRoute(
      path: AppRoutes.createHabit,
      name: 'createHabit',
      builder: (context, state) => const CreateHabitScreen(),
    ),
    GoRoute(
      path: AppRoutes.habitDetail,
      name: 'habitDetail',
      builder: (context, state) {
        final assignmentId = state.pathParameters['id']!;
        return HabitDetailScreen(assignmentId: assignmentId);
      },
    ),
    GoRoute(
      path: AppRoutes.createTask,
      name: 'createTask',
      builder: (context, state) => const CreateTaskScreen(),
    ),
    GoRoute(
      path: AppRoutes.taskDetail,
      name: 'taskDetail',
      builder: (context, state) {
        final assignmentId = state.pathParameters['id']!;
        return TaskDetailScreen(assignmentId: assignmentId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
