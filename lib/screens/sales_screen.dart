import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/api_client.dart';
import 'dart:convert';
import '../services/currency.dart';
import 'sale_form_screen.dart';
import '../services/sync_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final resp = await ApiClient.get('/sales', auth: true);
    if (!mounted) return;
    if (resp.statusCode == 200) {
      final list = (jsonDecode(resp.body) as List)
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
      if (!mounted) return;
      setState(() {
        _sales = list;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaySales = _sales
        .where(
          (sale) =>
              sale.saleDate.year == DateTime.now().year &&
              sale.saleDate.month == DateTime.now().month &&
              sale.saleDate.day == DateTime.now().day,
        )
        .toList();

    final todayTotal = todaySales.fold(
      0.0,
      (sum, sale) => sum + sale.totalPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas'),
        backgroundColor: Colors.green[600],
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
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implementar filtros
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumo do dia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hoje',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      Currency.fcfa(todayTotal),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${todaySales.length} vendas realizadas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.green[600]),
                ),
              ],
            ),
          ),
          // Lista de vendas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.green[700],
                            ),
                          ),
                          title: Text(
                            sale.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantidade: ${sale.quantity} x ${Currency.fcfa(sale.unitPrice)}',
                              ),
                              Text(
                                '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year} às ${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            Currency.fcfa(sale.totalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSale,
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma venda registrada',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para registrar sua primeira venda',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _addSale() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaleFormScreen()),
    );

    if (!mounted) return;
    if (result != null && result is Sale) {
      await ApiClient.post('/sales', {
        'product_id': result.productId,
        'product_name': result.productName,
        'quantity': result.quantity,
        'unit_price': result.unitPrice,
        'sale_date': result.saleDate.toIso8601String(),
      }, auth: true);
      await _loadSales();
    }
  }
}
