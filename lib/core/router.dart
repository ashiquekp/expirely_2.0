
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/product_list_screen.dart';
import '../../presentation/screens/add_product_screen.dart';
import '../../presentation/screens/shopping_list_screen.dart';
import '../../presentation/screens/splash_screen.dart';

// Shell scaffolding
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.squaresFour),
            selectedIcon: Icon(PhosphorIconsFill.squaresFour),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.listDashes),
            selectedIcon: Icon(PhosphorIconsFill.listDashes),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.shoppingCart),
            selectedIcon: Icon(PhosphorIconsFill.shoppingCart),
            label: 'Shopping',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.plusCircle),
            selectedIcon: Icon(PhosphorIconsFill.plusCircle),
            label: 'Add',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/shopping')) return 2;
    if (location.startsWith('/add')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/products');
        break;
      case 2:
        context.go('/shopping');
        break;
      case 3:
        context.go('/add');
        break;
    }
  }
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(
          path: '/shopping',
          builder: (context, state) => const ShoppingListScreen(),
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) => const AddProductScreen(),
        ),
      ],
    ),
  ],
);
