import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../models/sale.dart';
import '../models/daily_summary.dart';
import '../services/api_client.dart';
import 'dart:convert';
import '../services/currency.dart';
import '../services/sync_service.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final resp = await ApiClient.get('/sales', auth: true);
    if (!mounted) return;
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      final List<dynamic> rawList = decoded is List
          ? decoded
          : (decoded is Map && decoded['items'] is List)
          ? decoded['items'] as List
          : (decoded is Map && decoded['data'] is List)
          ? decoded['data'] as List
          : (decoded is Map && decoded['sales'] is List)
          ? decoded['sales'] as List
          : <dynamic>[];
      final list = rawList
          .map(
            (m) => Sale(
              id: m['id'],
              productId: m['product_id'],
              productName: m['product_name'],
              quantity: (m['quantity'] as num).toInt(),
              unitPrice: (m['unit_price'] as num).toDouble(),
              totalPrice: (m['total_price'] as num).toDouble(),
              saleDate: DateTime.parse(m['sale_date']),
              createdAt: DateTime.parse(m['created_at']),
            ),
          )
          .toList();
      setState(() {
        _sales = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailySummary = DailySummary.fromSales(_sales, _selectedDate);
    final isToday = _isToday(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dailySummary),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: SyncService.syncing,
            builder: (context, syncing, _) {
              return syncing
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de data
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? AppLocalizations.of(context)!.today
                          : AppLocalizations.of(context)!.selectedDate,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _selectDate,
                  icon: Icon(
                    Icons.calendar_month,
                    color: Colors.purple[700],
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          // Resumo do dia (layout refinado)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[600]!, Colors.purple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.daySummaryTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth > 640;
                    final cards = [
                      _buildSummaryCard(
                        AppLocalizations.of(context)!.totalSold,
                        Currency.fcfa(dailySummary.totalSales),
                        Icons.attach_money,
                      ),
                      _buildSummaryCard(
                        AppLocalizations.of(context)!.productsSold,
                        '${dailySummary.totalProductsSold}',
                        Icons.shopping_cart,
                      ),
                      _buildSummaryCard(
                        AppLocalizations.of(context)!.salesCount,
                        '${dailySummary.sales.length}',
                        Icons.receipt,
                      ),
                    ];
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[2]),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 12),
                        cards[1],
                        const SizedBox(height: 12),
                        cards[2],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Lista de vendas do dia
          Expanded(
            child: dailySummary.sales.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dailySummary.sales.length,
                    itemBuilder: (context, index) {
                      final sale = dailySummary.sales[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple[100],
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.purple[700],
                            ),
                          ),
                          title: Text(
                            sale.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${sale.quantity} x ${Currency.fcfa(sale.unitPrice)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Currency.fcfa(sale.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma venda registrada',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Não há vendas para a data selecionada',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
