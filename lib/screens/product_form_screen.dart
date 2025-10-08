import 'package:flutter/material.dart';
import 'package:nova/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../widgets/responsive_widgets.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _lowStockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _skuController.text = widget.product!.sku ?? '';
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stockQuantity.toString();
      _lowStockController.text = (widget.product!.lowStockThreshold ?? 0)
          .toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null
              ? AppLocalizations.of(context)!.newProduct
              : AppLocalizations.of(context)!.products,
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: ResponsivePadding(
        child: ResponsiveForm(
          formKey: _formKey,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.productInfo,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.productNameField,
                        prefixIcon: const Icon(Icons.inventory_2),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome do produto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.skuManualField,
                        prefixIcon: const Icon(Icons.qr_code_2),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.priceFcfaField,
                        prefixIcon: const Icon(Icons.attach_money),
                        border: const OutlineInputBorder(),
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
                          return 'Por favor, insira o preço';
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.stockQtyField,
                        prefixIcon: const Icon(Icons.inventory),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a quantidade em estoque';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor, insira um número válido';
                        }
                        if (int.parse(value) < 0) {
                          return 'A quantidade não pode ser negativa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lowStockController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.lowStockAlertField,
                        prefixIcon: const Icon(Icons.warning_amber_rounded),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ResponsiveButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.product == null
                    ? AppLocalizations.of(context)!.registerProductBtn
                    : AppLocalizations.of(context)!.updateProductBtn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        cost: null,
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        lowStockThreshold: _lowStockController.text.trim().isEmpty
            ? null
            : int.parse(_lowStockController.text),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? AppLocalizations.of(context)!.productCreatedMsg
                : AppLocalizations.of(context)!.productUpdatedMsg,
          ),
          backgroundColor: Colors.green[600],
        ),
      );

      Navigator.pop(context, product);
    }
  }
}
