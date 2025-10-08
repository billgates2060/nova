import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../repositories/products_repository.dart';
import '../repositories/sales_repository.dart';
import '../repositories/clients_repository.dart';
import '../services/retry_service.dart';

class SyncService {
  static final SyncService _i = SyncService._();
  SyncService._();
  factory SyncService() => _i;

  final _connectivity = Connectivity();
  StreamSubscription? _sub;
  bool _syncing = false;
  static final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);

  final _productsRepo = ProductsRepository();
  final _salesRepo = SalesRepository();
  final _clientsRepo = ClientsRepository();

  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((_) => sync());
    sync();
  }

  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    syncing.value = true;
    
    try {
      await RetryService.networkRetry(
        () async {
          // Sincronizar produtos
          await _productsRepo.pushQueue();
          await _productsRepo.syncFromRemote();
          
          // Sincronizar vendas
          await _salesRepo.syncPendingSales();
          await _salesRepo.syncFromRemote();
          
          // Sincronizar clientes
          await _clientsRepo.syncPendingClients();
          await _clientsRepo.syncFromRemote();
        },
        operationName: 'sincronizacao_completa',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na sincronização: $e');
      }
      // Não relançar - sistema continua funcionando offline
    } finally {
      _syncing = false;
      syncing.value = false;
    }
  }
  
  /// Sincronização apenas de vendas
  Future<void> syncSales() async {
    if (_syncing) return;
    
    try {
      await RetryService.networkRetry(
        () async {
          await _salesRepo.syncPendingSales();
          await _salesRepo.syncFromRemote();
        },
        operationName: 'sincronizacao_vendas',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na sincronização de vendas: $e');
      }
    }
  }
  
  /// Força sincronização completa
  Future<void> forceSync() async {
    _syncing = false; // Reset flag
    await sync();
  }
  
  void dispose() {
    _sub?.cancel();
  }
}
