import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/expenses/expense_list_screen.dart';
import 'presentation/screens/expenses/add_expense_screen.dart';
import 'presentation/screens/expenses/expense_detail_screen.dart';
import 'presentation/screens/insights/insights_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/budget/budget_screen.dart';
import 'presentation/screens/groups/groups_list_screen.dart';
import 'presentation/screens/groups/create_group_screen.dart';
import 'presentation/screens/groups/group_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    const darkStatusBar = Color(0xFF1E2A3A);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: darkStatusBar,
      statusBarIconBrightness: Brightness.light,
    ));
    return MaterialApp.router(
      title: 'Hisab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildPage(const SplashScreen(), state),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildPage(const OnboardingScreen(), state),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPage(const LoginScreen(), state),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildPage(const RegisterScreen(), state),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) => _buildPage(_ShellScreen(child: child), state),
      routes: [
        GoRoute(
          path: '/home/dashboard',
          pageBuilder: (context, state) => _buildPage(const DashboardScreen(), state),
        ),
        GoRoute(
          path: '/home/expenses',
          pageBuilder: (context, state) => _buildPage(const ExpenseListScreen(), state),
        ),
        GoRoute(
          path: '/home/expenses/add',
          pageBuilder: (context, state) => _buildPage(const AddExpenseScreen(), state),
        ),
        GoRoute(
          path: '/home/expenses/:id',
          pageBuilder: (context, state) => _buildPage(
            ExpenseDetailScreen(id: state.pathParameters['id']!),
            state,
          ),
        ),
        GoRoute(
          path: '/home/insights',
          pageBuilder: (context, state) => _buildPage(const InsightsScreen(), state),
        ),
        GoRoute(
          path: '/home/profile',
          pageBuilder: (context, state) => _buildPage(const ProfileScreen(), state),
        ),
        GoRoute(
          path: '/home/profile/budget',
          pageBuilder: (context, state) => _buildPage(const BudgetScreen(), state),
        ),
        GoRoute(
          path: '/home/profile/groups',
          pageBuilder: (context, state) => _buildPage(const GroupsListScreen(), state),
        ),
        GoRoute(
          path: '/home/profile/groups/create',
          pageBuilder: (context, state) => _buildPage(const CreateGroupScreen(), state),
        ),
        GoRoute(
          path: '/home/profile/groups/:id',
          pageBuilder: (context, state) => _buildPage(
            GroupDetailScreen(id: state.pathParameters['id']!),
            state,
          ),
        ),
      ],
    ),
  ],
);

Page _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class _ShellScreen extends StatelessWidget {
  final Widget child;
  const _ShellScreen({required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/home/dashboard')) return 0;
    if (location.startsWith('/home/expenses')) return 1;
    if (location.startsWith('/home/insights')) return 2;
    if (location.startsWith('/home/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _currentIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0x1A000000)
                  : const Color(0x33000000),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (i) {
                switch (i) {
                  case 0: context.go('/home/dashboard');
                  case 1: context.go('/home/expenses');
                  case 2: context.go('/home/insights');
                  case 3: context.go('/home/profile');
                }
              },
              selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
              unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.selectedLabelStyle,
              unselectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.unselectedLabelStyle,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Expenses'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Insights'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
