import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/api_client.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../services/reports/receipt_pdf.dart';
import '../services/print_service.dart';
import 'sale_form_screen.dart';
import '../services/sync_service.dart';
import '../repositories/sales_repository.dart';
import '../services/retry_service.dart';
import 'receipts_history_screen.dart';
import '../widgets/responsive_widgets.dart';
import '../services/currency.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;
  final _salesRepo = SalesRepository();

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Primeiro: carregar dados locais (sempre funciona)
    try {
      final localSales = await _salesRepo.getLocalSales();
      
      if (!mounted) return;
      setState(() {
        _sales = localSales;
        _isLoading = false;
      });
      
      // Mostrar aviso de modo offline se não há dados locais
      if (localSales.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Nenhuma venda encontrada localmente'),
              ],
            ),
            backgroundColor: Colors.blue[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (localError) {
      if (kDebugMode) {
        print('❌ Erro ao carregar vendas locais: $localError');
      }
      
      if (!mounted) return;
      setState(() {
        _sales = [];
        _isLoading = false;
      });
    }

    // Segundo: tentar sincronizar com backend em background
    try {
      final remoteSales = await RetryService.networkRetry(
        () => _salesRepo.getRemoteSales(),
        operationName: 'carregar_vendas_backend',
      );
      
      if (!mounted) return;
      
      // Se conseguiu carregar do backend, atualizar a lista
      if (remoteSales.isNotEmpty) {
        setState(() {
          _sales = remoteSales;
        });
        
        // Sincronizar dados locais
        _salesRepo.syncFromRemote();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.sync, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Dados sincronizados com sucesso'),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao sincronizar com backend: $e');
      }
      
      // Não mostrar erro se já temos dados locais
      if (_sales.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modo offline - dados locais',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: () => _loadSales(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaySales = _sales
        .where(
          (sale) =>
              sale.saleDate.year == DateTime.now().year &&
              sale.saleDate.month == DateTime.now().month &&
              sale.saleDate.day == DateTime.now().day,
        )
        .toList();

    final todayTotal = todaySales.fold(
      0.0,
      (sum, sale) => sum + sale.totalPrice,
    );

    return Scaffold(
      appBar: ResponsiveAppBar(
        title: AppLocalizations.of(context)!.sales,
        backgroundColor: Colors.green[600],
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
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReceiptsHistoryScreen(),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.receiptsHistory,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implementar filtros
            },
            tooltip: AppLocalizations.of(context)!.filters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumo do dia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.today,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      Currency.fcfa(todayTotal),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${todaySales.length} ${AppLocalizations.of(context)!.sales.toLowerCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.green[600]),
                ),
              ],
            ),
          ),
          // Lista de vendas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.green[700],
                            ),
                          ),
                          title: Text(
                            sale.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantidade: ${sale.quantity} x ${Currency.fcfa(sale.unitPrice)}',
                              ),
                              if (sale.clientName != null &&
                                  sale.clientName!.isNotEmpty)
                                Text(
                                  'Cliente: ${sale.clientName}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              Text(
                                '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year} às ${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                Currency.fcfa(sale.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: AppLocalizations.of(context)!.receipts,
                                onSelected: (value) async {
                                  await _handleReceiptAction(value, sale);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'preview',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.visibility,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.preview,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'print',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.print,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.printLabel,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.share,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.share,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'save',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.save,
                                          color: Colors.purple,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.saveLabel,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSale,
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma venda registrada',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para registrar sua primeira venda',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _addSale() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaleFormScreen()),
    );

    if (!mounted) return;
    if (result != null && result is Sale) {
      try {
        // Salvar localmente primeiro (sempre funciona)
        await _salesRepo.saveSaleLocally(result);
        await _salesRepo.queueSaleForSync(result);
        
        // Tentar enviar para o backend
        try {
          await RetryService.networkRetry(
            () async {
              await ApiClient.post('/sales', {
                'product_id': result.productId,
                'product_name': result.productName,
                'quantity': result.quantity,
                'unit_price': result.unitPrice,
                'total_price': result.totalPrice,
                'sale_date': result.saleDate.toIso8601String(),
                if (result.clientId != null) 'client_id': result.clientId,
              }, auth: true);
            },
            operationName: 'enviar_venda_backend',
          );
          
          // Se chegou aqui, a venda foi enviada com sucesso
          await _loadSales();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Venda registrada com sucesso!'),
                  ],
                ),
                backgroundColor: Colors.green[600],
                duration: Duration(seconds: 2),
              ),
            );
          }
          
        } catch (e) {
          // Falha no envio para o backend, mas dados estão salvos localmente
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Venda salva localmente. Será sincronizada quando a conexão voltar.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[600],
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Sincronizar',
                  textColor: Colors.white,
                  onPressed: () => SyncService().syncSales(),
                ),
              ),
            );
          }
          
          // Recarregar dados locais
          await _loadSales();
        }

        // Gerar, compartilhar e salvar recibo automaticamente
        await _generateAndShareAndSaveReceipt(result);
        
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erro ao salvar venda: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Erro ao salvar venda: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _generateAndShareAndSaveReceipt(Sale sale) async {
    try {
      final config = await PrintService.getDefaultConfig();
      final originalSubtotal = sale.quantity * sale.unitPrice;
      final discountAmount = ((originalSubtotal - sale.totalPrice).clamp(0, double.infinity)) as double;
      final receiptData = PrintService.createSaleReceipt(
        receiptNumber: '${sale.id ?? DateTime.now().millisecondsSinceEpoch}',
        date: sale.saleDate,
        items: [
          ReceiptItem(
            name: sale.productName,
            quantity: sale.quantity,
            unitPrice: sale.unitPrice,
            total: sale.totalPrice,
          ),
        ],
        total: sale.totalPrice,
        paid: sale.totalPrice,
        client: sale.clientName != null
            ? ReceiptClient(name: sale.clientName)
            : null,
        discount: discountAmount,
      );
      await PrintService.shareReceipt(receiptData: receiptData, config: config);
      await PrintService.saveReceipt(receiptData: receiptData, config: config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.receiptGeneratedSharedSuccess,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorGeneratingReceipt} $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReceiptAction(String action, Sale sale) async {
    try {
      final config = await PrintService.getDefaultConfig();
      final originalSubtotal = sale.quantity * sale.unitPrice;
      final discountAmount = ((originalSubtotal - sale.totalPrice).clamp(0, double.infinity)) as double;
      final receiptData = PrintService.createSaleReceipt(
        receiptNumber: '${sale.id ?? DateTime.now().millisecondsSinceEpoch}',
        date: sale.saleDate,
        items: [
          ReceiptItem(
            name: sale.productName,
            quantity: sale.quantity,
            unitPrice: sale.unitPrice,
            total: sale.totalPrice,
          ),
        ],
        total: sale.totalPrice,
        paid: sale.totalPrice,
        client: sale.clientName != null
            ? ReceiptClient(name: sale.clientName)
            : null,
        discount: discountAmount,
      );

      switch (action) {
        case 'preview':
          await PrintService.previewReceipt(
            receiptData: receiptData,
            config: config,
            context: context,
          );
          break;
        case 'print':
          await PrintService.printReceipt(
            receiptData: receiptData,
            config: config,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.receiptPrintSent),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        case 'share':
          await PrintService.shareReceipt(
            receiptData: receiptData,
            config: config,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.receiptSharedSuccess,
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        case 'save':
          await PrintService.saveReceipt(
            receiptData: receiptData,
            config: config,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.receiptSavedSuccess,
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorProcessingReceipt} $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
