import 'dart:async';
import 'package:flutter/foundation.dart';

/// Serviço para operações com retry automático
class RetryService {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    String? operationName,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (attempts < maxRetries) {
      try {
        if (kDebugMode && operationName != null) {
          print('🔄 Tentativa ${attempts + 1}/$maxRetries para $operationName');
        }
        
        final result = await operation();
        
        if (kDebugMode && operationName != null) {
          print('✅ Sucesso em $operationName após ${attempts + 1} tentativas');
        }
        
        return result;
      } catch (e) {
        attempts++;
        
        if (kDebugMode && operationName != null) {
          print('❌ Falha em $operationName (tentativa $attempts/$maxRetries): $e');
        }
        
        if (attempts >= maxRetries) {
          if (kDebugMode && operationName != null) {
            print('💥 Máximo de tentativas excedido para $operationName');
          }
          rethrow;
        }
        
        // Aguardar antes da próxima tentativa (backoff exponencial)
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }
    
    throw Exception('Máximo de tentativas excedido para $operationName');
  }
  
  /// Retry específico para operações de rede
  static Future<T> networkRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    return withRetry(
      operation,
      maxRetries: 3,
      initialDelay: const Duration(seconds: 2),
      backoffMultiplier: 1.5,
      operationName: operationName,
    );
  }
  
  /// Retry específico para operações de banco de dados
  static Future<T> databaseRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    return withRetry(
      operation,
      maxRetries: 2,
      initialDelay: const Duration(milliseconds: 500),
      backoffMultiplier: 2.0,
      operationName: operationName,
    );
  }
}
