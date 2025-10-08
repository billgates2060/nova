import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'store_stats_screen.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  bool _loading = true;
  List<StoreInfo> _stores = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stores = await AdminService.getStores();
    setState(() {
      _stores = stores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lojas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _stores.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = _stores[i];
                  return ListTile(
                    leading: const Icon(Icons.storefront),
                    title: Text(s.storeName),
                    subtitle: Text(s.storeId),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoreStatsScreen(storeId: s.storeId, storeName: s.storeName),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}


