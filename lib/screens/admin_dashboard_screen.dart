import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/currency.dart';
import 'store_stats_screen.dart';
import 'admin_users_screen.dart';
import 'admin_stores_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  StoreStats? _stats;
  List<dynamic> _stores = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await AdminService.getGlobalStats();
    final stores = await AdminService.getStores();
    setState(() {
      _stats = stats;
      _stores = stores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Visão Geral')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                        ),
                        icon: const Icon(Icons.group),
                        label: const Text('Usuários'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminStoresScreen()),
                        ),
                        icon: const Icon(Icons.storefront),
                        label: const Text('Lojas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _kpi('Usuários', (_stats?.users ?? 0).toString(), Icons.people),
                      _kpi('Ativos', (_stats?.activeUsers ?? 0).toString(), Icons.verified_user),
                      _kpi('Vendas', (_stats?.salesCount ?? 0).toString(), Icons.point_of_sale),
                      _kpi('Receita', Currency.fcfa((_stats?.revenue ?? 0) * 1.0), Icons.payments),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lojas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._stores.map((s) {
                    final storeId = s['store_id'] as String? ?? s['storeId'] as String? ?? '';
                    final storeName = s['store_name'] as String? ?? s['storeName'] as String? ?? storeId;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.storefront),
                        title: Text(storeName),
                        subtitle: Text(storeId),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StoreStatsScreen(storeId: storeId, storeName: storeName),
                            ),
                          );
                        },
                      ),
                    );
                  }),
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


