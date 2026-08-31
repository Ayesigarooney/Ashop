import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_theme.dart';
import 'features/product/data/models/product_model.dart';
import 'features/product/data/repositories/product_repository.dart';
import 'features/product/presentation/bloc/product_cubit.dart';
import 'features/sale/data/models/sale_model.dart';
import 'features/sale/data/repositories/sale_repository.dart';
import 'features/sale/presentation/bloc/sale_cubit.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/notes/data/repositories/note_repository.dart';
import 'features/notes/presentation/bloc/note_cubit.dart';
import 'core/config/constants.dart';
import 'core/di/locator.dart';
import 'core/navigation/app_router.dart';
import 'core/utils/security_helper.dart';
import 'presentation/splash/splash_screen.dart';

/// Shared future so the splash screen can await Hive readiness
Future<void> get appReady => _appReadyCompleter.future;
final _appReadyCompleter = Completer<void>();

Future<void> initializeApp({
  bool initializePlatform = true,
  bool initializeHive = true,
}) async {
  if (_appReadyCompleter.isCompleted) {
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();

  if (initializePlatform) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  if (initializeHive) {
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(SaleModelAdapter());
    Hive.registerAdapter(SaleItemModelAdapter());

    await Hive.initFlutter();

    final hiveKey = await SecurityHelper.getHiveEncryptionKey();

    await Future.wait([
      // Settings box is now encrypted — the PIN lockout counters are protected too
      Hive.openBox(AppConstants.settingsBox, encryptionKey: hiveKey),
      Hive.openBox<ProductModel>(AppConstants.productsBox, encryptionKey: hiveKey),
      Hive.openBox<SaleModel>(AppConstants.salesBox, encryptionKey: hiveKey),
      Hive.openBox<dynamic>(AppConstants.notesBox, encryptionKey: hiveKey),
    ]);
  }

  setupLocator();
  _appReadyCompleter.complete();
}

void main() async {
  await initializeApp();
  runApp(const AshopApp());
}

class AshopApp extends StatefulWidget {
  const AshopApp({super.key});

  @override
  State<AshopApp> createState() => _AshopAppState();
}

class _AshopAppState extends State<AshopApp> {
  bool _ready = false;
  SettingsRepository? _settingsRepo;

  @override
  void initState() {
    super.initState();
    appReady.then((_) {
      if (mounted) {
        _settingsRepo = getIt<SettingsRepository>();
        _settingsRepo!.themeNotifier.addListener(_onThemeChanged);
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _settingsRepo?.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        home: const SplashScreen(simple: true),
      );
    }

    final productRepo = getIt<ProductRepository>();
    final saleRepo = getIt<SaleRepository>();
    final noteRepo = getIt<NoteRepository>();

    final repo = _settingsRepo!;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repo),
        RepositoryProvider.value(value: productRepo),
        RepositoryProvider.value(value: saleRepo),
        RepositoryProvider.value(value: noteRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ProductCubit>(
            create: (_) => ProductCubit(productRepo)..loadProducts(),
          ),
          BlocProvider<SaleCubit>(
            create: (_) => SaleCubit(saleRepo, productRepo, repo),
          ),
          BlocProvider<NoteCubit>(
            create: (_) => NoteCubit(noteRepo)..loadNotes(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Ashop \u2013 Smart Shop Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: repo.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
