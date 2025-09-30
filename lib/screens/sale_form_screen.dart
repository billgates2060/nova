import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../repositories/products_repository.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  double _totalPrice = 0.0;

  final _repo = ProductsRepository();
  List<Product> _products = [];
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotal);
    _unitPriceController.addListener(_calculateTotal);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
    });
    // Tenta sincronizar com backend; se falhar, ignora e usa cache
    try {
      await _repo.syncFromRemote();
    } catch (_) {}

    final rows = await _repo.getAllLocal();
    final products = rows
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
      _products = products;
      _loadingProducts = false;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    setState(() {
      _totalPrice = quantity * unitPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Venda'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadingProducts ? null : _loadProducts,
            tooltip: 'Atualizar produtos',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dados da Venda',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Seletor de produto
                      DropdownButtonFormField<Product>(
                        value: _selectedProduct,
                        decoration: const InputDecoration(
                          labelText: 'Produto',
                          prefixIcon: Icon(Icons.inventory_2),
                          border: OutlineInputBorder(),
                        ),
                        items: _products.map((Product product) {
                          return DropdownMenuItem<Product>(
                            value: product,
                            child: Text(product.name),
                          );
                        }).toList(),
                        onChanged: (Product? newValue) {
                          setState(() {
                            _selectedProduct = newValue;
                            if (newValue != null) {
                              _unitPriceController.text = newValue.price
                                  .toString();
                              _calculateTotal();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, selecione um produto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_loadingProducts)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      const SizedBox(height: 16),
                      // Quantidade
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a quantidade';
                          }
                          final quantity = int.tryParse(value);
                          if (quantity == null || quantity <= 0) {
                            return 'A quantidade deve ser maior que zero';
                          }
                          if (_selectedProduct != null &&
                              quantity > _selectedProduct!.stockQuantity) {
                            return 'Quantidade maior que o estoque disponível (${_selectedProduct!.stockQuantity})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Preço unitário
                      TextFormField(
                        controller: _unitPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço Unitário (FCFA)',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o preço unitário';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor, insira um preço válido';
                          }
                          if (double.parse(value) <= 0) {
                            return 'O preço deve ser maior que zero';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Resumo da venda
              Card(
                elevation: 4,
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Resumo da Venda',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_totalPrice.toStringAsFixed(2)} FCFA',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botão de salvar
              ElevatedButton(
                onPressed: _saveSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Registrar Venda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSale() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      final quantity = int.parse(_quantityController.text);
      final unitPrice = double.parse(_unitPriceController.text);
      final totalPrice = quantity * unitPrice;

      final sale = Sale(
        productId: _selectedProduct!.id!,
        productName: _selectedProduct!.name,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        saleDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venda registrada com sucesso! Total: ${totalPrice.toStringAsFixed(2)} FCFA',
          ),
          backgroundColor: Colors.green[600],
        ),
      );

      Navigator.pop(context, sale);
    }
  }
}
