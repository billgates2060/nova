import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'daily_summary_screen.dart';
import '../services/auth_service.dart';
import 'admin_store_selector_screen.dart';
import '../services/dashboard_service.dart';
import 'welcome_screen.dart';
import 'settings_screen.dart';
import 'clients_screen.dart';
import 'receipts_history_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/responsive_widgets.dart';
import '../services/auth_service_ext.dart';
import '../services/notifications_service.dart';
import 'notifications_screen.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../services/currency.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const ProductsScreen(),
    const SalesScreen(),
    const DailySummaryScreen(),
    const ClientsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: Scaffold(
        drawer: const AppDrawer(),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Início'),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: 'Produtos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Vendas',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Resumo'),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt),
              label: 'Clientes',
            ),
          ],
        ),
      ),
      tablet: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Início'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2),
                  label: Text('Produtos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Vendas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics),
                  label: Text('Resumo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt),
                  label: Text('Clientes'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Início'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2),
                  label: Text('Produtos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Vendas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics),
                  label: Text('Resumo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt),
                  label: Text('Clientes'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late Future<Map<String, dynamic>> _future;
  late Future<AuthProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _future = DashboardService.fetchOverview();
    _profileFuture = AuthProfile.current();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DashboardService.fetchOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationsService.unreadCount,
            builder: (context, count, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.notifications,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 10,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          FutureBuilder<String?>(
            future: AuthService.getRole(),
            builder: (context, snapshot) {
              final isAdmin = snapshot.data == 'admin';
              if (!isAdmin) return const SizedBox.shrink();
              return Tooltip(
                message: AppLocalizations.of(context)!.admin,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminStoreSelectorScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'Admin',
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                // Logout e voltar para a tela inicial
                AuthService.logout().then((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final int productsCount = (data['productsCount'] as int?) ?? 0;
          final int todaysSalesCount = (data['todaysSalesCount'] as int?) ?? 0;
          final double todaysRevenue =
              (data['todaysRevenue'] as num?)?.toDouble() ?? 0.0;
          final List<dynamic> recent =
              (data['recentSales'] as List<dynamic>?) ?? const [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ResponsivePadding(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Hero/Header com nome da loja e KPIs
                    FutureBuilder<AuthProfile?>(
                      future: _profileFuture,
                      builder: (context, profSnap) {
                        final storeName =
                            profSnap.data?.storeName ?? 'Sua Loja';
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1E40AF,
                                ).withOpacity(0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Resumo de hoje',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ResponsiveGrid(
                                mobileColumns: 1,
                                tabletColumns: 2,
                                desktopColumns: 3,
                                children: [
                                  _buildSummaryCard(
                                    'Vendas',
                                    '$todaysSalesCount',
                                    Icons.shopping_cart_rounded,
                                    const Color(0xFF10B981),
                                    context,
                                  ),
                                  _buildSummaryCard(
                                    'Faturamento',
                                    Currency.fcfa(todaysRevenue),
                                    Icons.attach_money_rounded,
                                    const Color(0xFF8B5CF6),
                                    context,
                                  ),
                                  _buildSummaryCard(
                                    'Produtos',
                                    '$productsCount',
                                    Icons.inventory_2_rounded,
                                    const Color(0xFF3B82F6),
                                    context,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Progresso gamificado (meta simples = 10 vendas)
                    _DailyGoalProgress(current: todaysSalesCount, goal: 10),
                    const SizedBox(height: 16),
                    Text(
                      'Estoque Baixo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LowStockList(
                      items:
                          (data['lowStock'] as List<Map<String, dynamic>>? ??
                          const []),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      'Nova Venda',
                      Icons.add_shopping_cart_rounded,
                      const Color(0xFF10B981),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SalesScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                    ResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 3,
                      children: [
                        _buildActionCard(
                          'Novo Produto',
                          Icons.add_box_rounded,
                          const Color(0xFF3B82F6),
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProductsScreen(),
                              ),
                            );
                          },
                          context,
                        ),
                        _buildActionCard(
                          'Ver Relatórios',
                          Icons.analytics_rounded,
                          const Color(0xFF8B5CF6),
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DailySummaryScreen(),
                              ),
                            );
                          },
                          context,
                        ),
                        _buildActionCard(
                          'Recibos',
                          Icons.receipt_long_rounded,
                          const Color(0xFFF59E0B),
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReceiptsHistoryScreen(),
                              ),
                            );
                          },
                          context,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Botão de Gerenciamento de Lojas (apenas para admin)
                    FutureBuilder<String?>(
                      future: AuthService.getRole(),
                      builder: (context, roleSnapshot) {
                        final isAdmin = roleSnapshot.data == 'admin';
                        if (!isAdmin) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administração',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildActionCard(
                              'Gerenciar Lojas',
                              Icons.store_rounded,
                              const Color(0xFF8B5CF6),
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AdminStoreSelectorScreen(),
                                  ),
                                );
                              },
                              context,
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                    Text(
                      'Vendas Recentes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (recent.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Sem vendas recentes.'),
                            ),
                          for (final s in recent)
                            _buildRecentSaleItem(
                              (s['product_name'] ?? 'Produto').toString(),
                              '${s['quantity']}x',
                              Currency.fcfa((s['total_price'] as num?) ?? 0),
                              context,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ações Rápidas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        final actions = [
                          _buildActionCard(
                            'Configurações',
                            Icons.settings_rounded,
                            const Color(0xFF6B7280),
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                            context,
                          ),
                          _buildActionCard(
                            'Ver Relatórios',
                            Icons.analytics_rounded,
                            const Color(0xFF8B5CF6),
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DailySummaryScreen(),
                                ),
                              );
                            },
                            context,
                          ),
                        ];
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: actions[0]),
                              const SizedBox(width: 12),
                              Expanded(child: actions[1]),
                            ],
                          );
                        }
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: actions
                              .map(
                                (w) => SizedBox(
                                  width: (constraints.maxWidth - 12) / 2,
                                  child: w,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSaleItem(
    String product,
    String quantity,
    String total,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_cart_rounded,
              color: Colors.green[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quantity,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            total,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.green[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalProgress extends StatelessWidget {
  final int current;
  final int goal;
  const _DailyGoalProgress({required this.current, required this.goal});
  @override
  Widget build(BuildContext context) {
    final double pct = (current / goal).clamp(0.0, 1.0);
    final emoji = pct >= 1 ? '🎉' : (pct >= 0.5 ? '💪' : '🚀');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meta diária: $goal vendas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text('$emoji ${((pct) * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: pct.toDouble(),
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _LowStockList({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text('Tudo certo! Nenhum item com estoque baixo.'),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length.clamp(0, 5),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = items[i];
          return ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: Text(
              (it['name'] ?? 'Produto').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Estoque: ${it['stock']}  •  Alerta: ${it['low_stock_threshold']}',
            ),
          );
        },
      ),
    );
  }
}
