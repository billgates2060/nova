import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/currency.dart';

class StoreStatsScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  const StoreStatsScreen({super.key, required this.storeId, required this.storeName});

  @override
  State<StoreStatsScreen> createState() => _StoreStatsScreenState();
}

class _StoreStatsScreenState extends State<StoreStatsScreen> {
  StoreStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await AdminService.getStoreStats(widget.storeId);
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loja: ${widget.storeName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _kpi('Usuários', (_stats?.users ?? 0).toString(), Icons.people),
                      _kpi('Ativos', (_stats?.activeUsers ?? 0).toString(), Icons.verified_user),
                      _kpi('Vendas', (_stats?.salesCount ?? 0).toString(), Icons.point_of_sale),
                      _kpi('Receita', Currency.fcfa((_stats?.revenue ?? 0) * 1.0), Icons.payments),
                      _kpi('Produtos', (_stats?.productsCount ?? 0).toString(), Icons.inventory_2),
                      _kpi('Clientes', (_stats?.clientsCount ?? 0).toString(), Icons.people_alt),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _kpi(String label, String value, IconData icon) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


