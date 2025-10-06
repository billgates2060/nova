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
      final products = (jsonDecode(productsResp.body) as List).cast<dynamic>();

      final summaryResp = await ApiClient.get(
        '/summary/daily?date=$today',
        auth: true,
      );
      final summary = jsonDecode(summaryResp.body) as Map<String, dynamic>;

      final salesResp = await ApiClient.get('/sales', auth: true);
      final allSales = (jsonDecode(salesResp.body) as List)
          .cast<Map<String, dynamic>>();
      final recent = allSales.take(3).toList();

      // Low stock products
      final lowStockResp = await ApiClient.get(
        '/products/low_stock',
        auth: true,
      );
      final lowStock = lowStockResp.statusCode == 200
          ? (jsonDecode(lowStockResp.body) as List).cast<Map<String, dynamic>>()
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
