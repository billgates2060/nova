import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/responsive_widgets.dart';
import 'admin_users_screen.dart';
import '../services/currency.dart';

class AdminStoreSelectorScreen extends StatefulWidget {
  const AdminStoreSelectorScreen({super.key});

  @override
  State<AdminStoreSelectorScreen> createState() =>
      _AdminStoreSelectorScreenState();
}

class _AdminStoreSelectorScreenState extends State<AdminStoreSelectorScreen> {
  List<StoreInfo> _stores = [];
  bool _isLoading = true;
  StoreStats? _globalStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stores = await AdminService.getStores();
      final globalStats = await AdminService.getGlobalStats();

      setState(() {
        _stores = stores;
        _globalStats = globalStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'Gerenciar Lojas',
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estatísticas Globais
                  if (_globalStats != null) ...[
                    _buildGlobalStatsCard(_globalStats!),
                    const SizedBox(height: 24),
                  ],

                  // Lista de Lojas
                  Text(
                    'Lojas Cadastradas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _stores.isEmpty
                        ? _buildEmptyState()
                        : ResponsiveList(
                            children: _stores
                                .map((store) => _buildStoreCard(store))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGlobalStatsCard(StoreStats stats) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.purple[700], size: 28),
              const SizedBox(width: 12),
              Text(
                'Visão Geral - Todas as Lojas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            mobileColumns: 2,
            tabletColumns: 3,
            desktopColumns: 6,
            children: [
              _buildStatItem(
                'Lojas',
                '${_stores.length}',
                Icons.store,
                Colors.blue,
              ),
              _buildStatItem(
                'Usuários',
                '${stats.users}',
                Icons.people,
                Colors.green,
              ),
              _buildStatItem(
                'Ativos',
                '${stats.activeUsers}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Vendas',
                '${stats.salesCount}',
                Icons.shopping_cart,
                Colors.orange,
              ),
              _buildStatItem(
                'Produtos',
                '${stats.productsCount}',
                Icons.inventory,
                Colors.blue,
              ),
              _buildStatItem(
                'Receita',
                Currency.fcfa(stats.revenue),
                Icons.attach_money,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(StoreInfo store) {
    return ResponsiveCard(
      child: InkWell(
        onTap: () => _navigateToStoreDetails(store),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store,
                      color: Colors.purple[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${store.storeId}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToStoreDetails(store),
                      icon: const Icon(Icons.people),
                      label: const Text('Gerenciar Usuários'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewStoreStats(store),
                      icon: const Icon(Icons.analytics),
                      label: const Text('Ver Estatísticas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma loja cadastrada',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'As lojas aparecerão aqui quando usuários forem cadastrados',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToStoreDetails(StoreInfo store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminUsersScreen(selectedStore: store),
      ),
    );
  }

  void _viewStoreStats(StoreInfo store) async {
    try {
      final stats = await AdminService.getStoreStats(store.storeId);
      if (mounted) {
        _showStoreStatsDialog(store, stats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar estatísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStoreStatsDialog(StoreInfo store, StoreStats stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estatísticas - ${store.storeName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Usuários', '${stats.users}'),
              _buildStatRow('Usuários Ativos', '${stats.activeUsers}'),
              _buildStatRow('Total de Vendas', '${stats.salesCount}'),
              _buildStatRow('Receita Total', Currency.fcfa(stats.revenue)),
              _buildStatRow('Produtos Cadastrados', '${stats.productsCount}'),
              _buildStatRow('Clientes Cadastrados', '${stats.clientsCount}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToStoreDetails(store);
            },
            child: const Text('Gerenciar Loja'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
