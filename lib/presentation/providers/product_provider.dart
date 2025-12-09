
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/services/notification_service.dart';

class ProductListNotifier extends Notifier<List<ProductModel>> {
  late ProductRepository _repo;
  late NotificationService _notifService;

  @override
  List<ProductModel> build() {
    _repo = ref.read(productRepositoryProvider);
    _notifService = ref.read(notificationServiceProvider);
    return _repo.getAllProducts();
  }

  Future<void> addProduct(ProductModel product) async {
    await _repo.addProduct(product);
    await _notifService.scheduleExpiryNotifications(product);
    state = _repo.getAllProducts();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repo.updateProduct(product);
    await _notifService.scheduleExpiryNotifications(product);
    state = _repo.getAllProducts();
  }

  Future<void> deleteProduct(String id) async {
    final idBase = id.hashCode;
    await _notifService.cancelNotification(idBase + 7);
    await _notifService.cancelNotification(idBase + 3);
    await _notifService.cancelNotification(idBase + 1);
    await _notifService.cancelNotification(idBase);

    await _repo.deleteProduct(id);
    state = _repo.getAllProducts();
  }

  Future<void> deleteExpired() async {
    final all = _repo.getAllProducts();
    final expired = all.where((p) => p.daysRemaining < 0).toList();

    for (var p in expired) {
      final idBase = p.id.hashCode;
      await _notifService.cancelNotification(idBase + 7);
      await _notifService.cancelNotification(idBase + 3);
      await _notifService.cancelNotification(idBase + 1);
      await _notifService.cancelNotification(idBase);
      await _repo.deleteProduct(p.id);
    }
    state = _repo.getAllProducts();
  }
}

final productListProvider = NotifierProvider<ProductListNotifier, List<ProductModel>>(ProductListNotifier.new);
