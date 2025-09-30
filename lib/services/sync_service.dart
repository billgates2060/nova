import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../repositories/products_repository.dart';

class SyncService {
  static final SyncService _i = SyncService._();
  SyncService._();
  factory SyncService() => _i;

  final _connectivity = Connectivity();
  StreamSubscription? _sub;
  bool _syncing = false;
  static final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);

  final _productsRepo = ProductsRepository();

  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((_) => sync());
    sync();
  }

  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    syncing.value = true;
    try {
      await _productsRepo.pushQueue();
      await _productsRepo.syncFromRemote();
    } finally {
      _syncing = false;
      syncing.value = false;
    }
  }
}
