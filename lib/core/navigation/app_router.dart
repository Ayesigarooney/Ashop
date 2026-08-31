import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/app_shell.dart';
import '../../presentation/auth/pin_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/order_history/order_history_screen.dart';
import '../../presentation/pos/receipt_screen.dart';
import '../../presentation/reports/profit_loss_screen.dart';
import '../../presentation/reports/inventory_valuation_screen.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../di/locator.dart';
import '../../features/settings/data/settings_repository.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  // Handles any unmatched or broken routes gracefully instead of crashing
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Something went wrong.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/app'),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/pin',
      builder: (context, state) {
        final settings = getIt<SettingsRepository>();
        return PinScreen(settings: settings);
      },
    ),
    GoRoute(path: '/app', builder: (context, state) => const AppShell()),
    GoRoute(
      path: '/order-history',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/receipt',
      builder: (context, state) {
        // Guard against null or wrong-type extra to prevent runtime crashes
        final sale = state.extra;
        if (sale is! SaleModel) {
          // Redirect to home if navigated to /receipt without a valid sale
          return Scaffold(
            appBar: AppBar(title: const Text('Receipt')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Receipt not available.'),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/app'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }
        return ReceiptScreen(sale: sale);
      },
    ),
    GoRoute(
      path: '/reports/profit-loss',
      builder: (context, state) => const ProfitLossScreen(),
    ),
    GoRoute(
      path: '/reports/inventory-valuation',
      builder: (context, state) => const InventoryValuationScreen(),
    ),
  ],
);
