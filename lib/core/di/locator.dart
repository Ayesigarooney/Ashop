import 'package:get_it/get_it.dart';
import '../../features/product/data/repositories/product_repository.dart';
import '../../features/sale/data/repositories/sale_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/notes/data/repositories/note_repository.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  if (!locator.isRegistered<SettingsRepository>()) {
    locator.registerLazySingleton<SettingsRepository>(() => SettingsRepository());
  }
  if (!locator.isRegistered<ProductRepository>()) {
    locator.registerLazySingleton<ProductRepository>(() => ProductRepository());
  }
  if (!locator.isRegistered<SaleRepository>()) {
    locator.registerLazySingleton<SaleRepository>(() => SaleRepository());
  }
  if (!locator.isRegistered<NoteRepository>()) {
    locator.registerLazySingleton<NoteRepository>(() => NoteRepository());
  }
}

T getIt<T extends Object>() => locator<T>();
