
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/models/product_model.dart';
import 'data/models/product_category.dart';
import 'data/repositories/product_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'core/services/notification_service.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(ProductCategoryAdapter());
  
  // Open Boxes (Initialize Repository)
  final productRepo = ProductRepository();
  await productRepo.init();

  // Initialize Notifications
  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  
  await initializeDateFormatting('en_US', null);

  runApp(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(productRepo),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const ExpirelyApp(),
    ),
  );
}

class ExpirelyApp extends StatelessWidget {
  const ExpirelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Expirely',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
