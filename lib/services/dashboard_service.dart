import 'dart:convert';
import 'package:intl/intl.dart';
import 'api_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'local_db.dart';

class DashboardService {
  static Future<Map<String, dynamic>> fetchOverview() async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity == ConnectivityResult.none;

      if (isOffline) {
        // Offline fallback: use local DB when available
        if (kIsWeb) {
          return {
            'productsCount': 0,
            'todaysSalesCount': 0,
            'todaysRevenue': 0.0,
            'recentSales': <Map<String, dynamic>>[],
            'lowStock': <Map<String, dynamic>>[],
          };
        } else {
          final Database db = await LocalDb.instance();
          final productsRows = await db.query('products');
          final salesRows = await db.query(
            'sales',
            orderBy: 'sale_date DESC',
            limit: 3,
          );
          // Note: local schema doesn't include low_stock_threshold → omit low stock offline
          return {
            'productsCount': productsRows.length,
            'todaysSalesCount':
                0, // not computed offline without per-day grouping
            'todaysRevenue': 0.0,
            'recentSales': salesRows,
            'lowStock': <Map<String, dynamic>>[],
          };
        }
      }

      // Online path
      final productsResp = await ApiClient.get('/products', auth: true);
      final pDecoded = jsonDecode(productsResp.body);
      final List<dynamic> products = pDecoded is List
          ? pDecoded
          : (pDecoded is Map && pDecoded['items'] is List)
          ? pDecoded['items'] as List
          : (pDecoded is Map && pDecoded['data'] is List)
          ? pDecoded['data'] as List
          : (pDecoded is Map && pDecoded['products'] is List)
          ? pDecoded['products'] as List
          : <dynamic>[];

      final summaryResp = await ApiClient.get(
        '/summary/daily?date=$today',
        auth: true,
      );
      final summary = jsonDecode(summaryResp.body) as Map<String, dynamic>;

      final salesResp = await ApiClient.get('/sales', auth: true);
      final sDecoded = jsonDecode(salesResp.body);
      final List<dynamic> rawSales = sDecoded is List
          ? sDecoded
          : (sDecoded is Map && sDecoded['items'] is List)
          ? sDecoded['items'] as List
          : (sDecoded is Map && sDecoded['data'] is List)
          ? sDecoded['data'] as List
          : (sDecoded is Map && sDecoded['sales'] is List)
          ? sDecoded['sales'] as List
          : <dynamic>[];
      final allSales = rawSales.cast<Map<String, dynamic>>();
      final recent = allSales.take(3).toList();

      // Low stock products
      final lowStockResp = await ApiClient.get(
        '/products/low_stock',
        auth: true,
      );
      final lowStock = lowStockResp.statusCode == 200
          ? (() {
              final lDecoded = jsonDecode(lowStockResp.body);
              final List<dynamic> raw = lDecoded is List
                  ? lDecoded
                  : (lDecoded is Map && lDecoded['items'] is List)
                  ? lDecoded['items'] as List
                  : (lDecoded is Map && lDecoded['data'] is List)
                  ? lDecoded['data'] as List
                  : (lDecoded is Map && lDecoded['lowStock'] is List)
                  ? lDecoded['lowStock'] as List
                  : <dynamic>[];
              return raw.cast<Map<String, dynamic>>();
            })()
          : <Map<String, dynamic>>[];

      final totals = {
        'productsCount': products.length,
        'todaysSalesCount': (summary['sales'] as List<dynamic>).length,
        'todaysRevenue': (summary['totalSales'] ?? 0).toDouble(),
        'recentSales': recent,
        'lowStock': lowStock,
      };
      return totals;
    } catch (_) {
      // Generic safe fallback
      return {
        'productsCount': 0,
        'todaysSalesCount': 0,
        'todaysRevenue': 0.0,
        'recentSales': <Map<String, dynamic>>[],
        'lowStock': <Map<String, dynamic>>[],
      };
    }
  }
}
