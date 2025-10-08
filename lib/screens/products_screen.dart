import 'package:flutter/material.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../models/product.dart';
import '../services/currency.dart';
import 'product_form_screen.dart';
import '../repositories/products_repository.dart';
import '../services/local_db.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/sync_service.dart';
import '../widgets/responsive_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  String _query = '';
  final _repo = ProductsRepository();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      LocalDb.instance();
      SyncService().start();
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    // Tenta sincronizar do backend primeiro, se possível
    try {
      await _repo.syncFromRemote();
    } catch (_) {}

    final rows = await _repo.getAllLocal();
    final list = rows
        .map(
          (m) => Product(
            id: m['id'] as int?,
            name: m['name'] as String,
            price: (m['price'] as num).toDouble(),
            stockQuantity: (m['stock'] as num).toInt(),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (m['updated_at'] as num).toInt(),
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              (m['updated_at'] as num).toInt(),
            ),
          ),
        )
        .toList();
    if (!mounted) return;
    setState(() {
      _products = list;
      _applyFilter();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: AppLocalizations.of(context)!.products,
        backgroundColor: Colors.blue[600],
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
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadProducts,
            tooltip: AppLocalizations.of(context)!.updateTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearch();
            },
            tooltip: AppLocalizations.of(context)!.searchTooltip,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? _buildEmptyState()
          : ResponsivePadding(
              child: ResponsiveList(
                children: _filtered
                    .map((product) => _buildProductCard(product))
                    .toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List<Product>.from(_products);
    } else {
      _filtered = _products
          .where((p) => p.name.toLowerCase().contains(q))
          .toList();
    }
  }

  void _showSearch() async {
    final controller = TextEditingController(text: _query);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.searchProductsTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.nameOrCode,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.searchTooltip),
          ),
        ],
      ),
    );
    if (ok == true) {
      final q = controller.text.trim();
      if (q.isEmpty) {
        setState(() {
          _query = '';
          _applyFilter();
        });
        return;
      }
      // Tenta remoto; fallback local
      try {
        final results = await _repo.searchRemote(q);
        if (results.isNotEmpty) {
          final list = results
              .map(
                (m) => Product(
                  id: m['id'] as int?,
                  name: m['name'] as String,
                  price: (m['price'] as num).toDouble(),
                  stockQuantity: (m['stock'] as num).toInt(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              )
              .toList();
          if (!mounted) return;
          setState(() {
            _query = q;
            _filtered = list;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _query = q;
        _applyFilter();
      });
    }
  }

  Widget _buildProductCard(Product product) {
    return ResponsiveCard(
      child: InkWell(
        onTap: () => _editProduct(product),
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
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppLocalizations.of(context)!.priceLabel}: ${Currency.fcfa(product.price)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.stockLabel}: ${product.stockQuantity} un',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (product.stockQuantity <= 3) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.lowShort,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editProduct(product);
                      } else if (value == 'delete') {
                        _deleteProduct(product);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.delete),
                          ],
                        ),
                      ),
                    ],
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noProducts,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tapPlusToAddProduct,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductFormScreen()),
    );

    if (result != null && result is Product) {
      await _repo.queueOp('create', {
        'name': result.name,
        'sku': result.sku,
        'price': result.price,
        'stock': result.stockQuantity,
        'low_stock_threshold': result.lowStockThreshold ?? 0,
      });
      await _repo.upsertLocal({
        'id': result.id,
        'name': result.name,
        'price': result.price,
        'stock': result.stockQuantity,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      await _loadProducts();
      SyncService().sync();
    }
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );

    if (result != null && result is Product && product.id != null) {
      await _repo.queueOp('update', {
        'id': product.id,
        'name': result.name,
        'sku': result.sku,
        'price': result.price,
        'stock': result.stockQuantity,
        'low_stock_threshold': result.lowStockThreshold ?? 0,
      });
      await _repo.upsertLocal({
        'id': product.id,
        'name': result.name,
        'price': result.price,
        'stock': result.stockQuantity,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      await _loadProducts();
      SyncService().sync();
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o produto "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (product.id != null) {
                await _repo.queueOp('delete', {'id': product.id});
                final db = await LocalDb.instance();
                await db.delete(
                  'products',
                  where: 'id = ?',
                  whereArgs: [product.id],
                );
                await _loadProducts();
                SyncService().sync();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produto excluído com sucesso!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
