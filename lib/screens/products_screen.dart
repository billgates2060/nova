import 'package:flutter/material.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../models/product.dart';
import '../services/currency.dart';
import 'product_form_screen.dart';
import '../repositories/products_repository.dart';
import '../services/local_db.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/sync_service.dart';

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.products),
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
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearch();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final product = _filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.inventory_2, color: Colors.blue[700]),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preço: ${Currency.fcfa(product.price)}'),
                        Row(
                          children: [
                            Text('Estoque: ${product.stockQuantity} unidades'),
                            if (product.stockQuantity <= 3)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Baixo',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editProduct(product);
                        } else if (value == 'delete') {
                          _deleteProduct(product);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Excluir'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _editProduct(product),
                  ),
                );
              },
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
        title: const Text('Buscar produtos'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome ou código',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buscar'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum produto cadastrado',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar seu primeiro produto',
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
