import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/sale.dart';

class LocalStorageService {
  static const String _productsKey = 'products';
  static const String _salesKey = 'sales';

  // Salvar produtos
  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = products.map((p) => p.toMap()).toList();
    await prefs.setString(_productsKey, jsonEncode(productsJson));
  }

  // Carregar produtos
  static Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsString = prefs.getString(_productsKey);
    
    if (productsString == null) {
      // Dados iniciais de exemplo
      final initialProducts = [
        Product(
          id: 1,
          name: 'Café Expresso',
          price: 3.50,
          stockQuantity: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Product(
          id: 2,
          name: 'Pão de Açúcar',
          price: 0.80,
          stockQuantity: 100,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Product(
          id: 3,
          name: 'Leite Integral',
          price: 4.20,
          stockQuantity: 30,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
        ),
      ];
      await saveProducts(initialProducts);
      return initialProducts;
    }

    final List<dynamic> productsJson = jsonDecode(productsString);
    return productsJson.map((json) => Product.fromMap(json)).toList();
  }

  // Salvar vendas
  static Future<void> saveSales(List<Sale> sales) async {
    final prefs = await SharedPreferences.getInstance();
    final salesJson = sales.map((s) => s.toMap()).toList();
    await prefs.setString(_salesKey, jsonEncode(salesJson));
  }

  // Carregar vendas
  static Future<List<Sale>> loadSales() async {
    final prefs = await SharedPreferences.getInstance();
    final salesString = prefs.getString(_salesKey);
    
    if (salesString == null) {
      // Dados iniciais de exemplo
      final initialSales = [
        Sale(
          id: 1,
          productId: 1,
          productName: 'Café Expresso',
          quantity: 2,
          unitPrice: 3.50,
          totalPrice: 7.00,
          saleDate: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Sale(
          id: 2,
          productId: 2,
          productName: 'Pão de Açúcar',
          quantity: 5,
          unitPrice: 0.80,
          totalPrice: 4.00,
          saleDate: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Sale(
          id: 3,
          productId: 1,
          productName: 'Café Expresso',
          quantity: 1,
          unitPrice: 3.50,
          totalPrice: 3.50,
          saleDate: DateTime.now().subtract(const Duration(minutes: 30)),
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];
      await saveSales(initialSales);
      return initialSales;
    }

    final List<dynamic> salesJson = jsonDecode(salesString);
    return salesJson.map((json) => Sale.fromMap(json)).toList();
  }

  // Adicionar novo produto
  static Future<Product> addProduct(Product product) async {
    final products = await loadProducts();
    final newId = products.isNotEmpty ? products.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1 : 1;
    final newProduct = product.copyWith(id: newId);
    products.add(newProduct);
    await saveProducts(products);
    return newProduct;
  }

  // Atualizar produto
  static Future<void> updateProduct(Product product) async {
    final products = await loadProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await saveProducts(products);
    }
  }

  // Excluir produto
  static Future<void> deleteProduct(int productId) async {
    final products = await loadProducts();
    products.removeWhere((p) => p.id == productId);
    await saveProducts(products);
  }

  // Adicionar nova venda
  static Future<Sale> addSale(Sale sale) async {
    final sales = await loadSales();
    final newId = sales.isNotEmpty ? sales.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1 : 1;
    final newSale = sale.copyWith(id: newId);
    sales.add(newSale);
    await saveSales(sales);
    return newSale;
  }

  // Atualizar estoque após venda
  static Future<void> updateStockAfterSale(int productId, int quantitySold) async {
    final products = await loadProducts();
    final productIndex = products.indexWhere((p) => p.id == productId);
    if (productIndex != -1) {
      final product = products[productIndex];
      final newStock = product.stockQuantity - quantitySold;
      if (newStock >= 0) {
        products[productIndex] = product.copyWith(
          stockQuantity: newStock,
          updatedAt: DateTime.now(),
        );
        await saveProducts(products);
      }
    }
  }
}
