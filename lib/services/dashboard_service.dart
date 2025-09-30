import 'dart:convert';
import 'package:intl/intl.dart';
import 'api_client.dart';

class DashboardService {
  static Future<Map<String, dynamic>> fetchOverview() async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final productsResp = await ApiClient.get('/products', auth: true);
    final products = (jsonDecode(productsResp.body) as List).cast<dynamic>();

    final summaryResp = await ApiClient.get('/summary/daily?date=$today', auth: true);
    final summary = jsonDecode(summaryResp.body) as Map<String, dynamic>;

    final salesResp = await ApiClient.get('/sales', auth: true);
    final allSales = (jsonDecode(salesResp.body) as List).cast<Map<String, dynamic>>();
    final recent = allSales.take(3).toList();

    final totals = {
      'productsCount': products.length,
      'todaysSalesCount': (summary['sales'] as List<dynamic>).length,
      'todaysRevenue': (summary['totalSales'] ?? 0).toDouble(),
      'recentSales': recent,
    };
    return totals;
  }
}


