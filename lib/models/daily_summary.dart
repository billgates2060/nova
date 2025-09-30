
import 'sale.dart';

class DailySummary {
  final DateTime date;
  final double totalSales;
  final int totalProductsSold;
  final List<Sale> sales;

  DailySummary({
    required this.date,
    required this.totalSales,
    required this.totalProductsSold,
    required this.sales,
  });

  factory DailySummary.fromSales(List<Sale> sales, DateTime date) {
    final daySales = sales.where((Sale sale) =>
      sale.saleDate.year == date.year &&
      sale.saleDate.month == date.month &&
      sale.saleDate.day == date.day
    ).toList();

    final totalSales = daySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalPrice);
    final totalProductsSold = daySales.fold(0, (int sum, Sale sale) => sum + sale.quantity);

    return DailySummary(
      date: date,
      totalSales: totalSales,
      totalProductsSold: totalProductsSold,
      sales: daySales,
    );
  }
}
