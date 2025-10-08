// removed unused: dart:typed_data
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/reports/receipt_pdf.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../services/auth_service.dart';

/// Serviço de impressão e compartilhamento de recibos
class PrintService {
  static const String _receiptsFolder = 'receipts';

  /// Imprime um recibo diretamente
  static Future<void> printReceipt({
    required ReceiptData receiptData,
    required ReceiptConfig config,
    String? jobName,
  }) async {
    try {
      final pdfBytes = await buildReceiptPdf(
        receiptData: receiptData,
        config: config,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: jobName ?? 'Recibo_${receiptData.receiptNumber}',
      );
    } catch (e) {
      throw Exception('Erro ao imprimir recibo: $e');
    }
  }

  /// Compartilha um recibo (WhatsApp, Email, etc.)
  static Future<void> shareReceipt({
    required ReceiptData receiptData,
    required ReceiptConfig config,
    String? filename,
  }) async {
    try {
      final pdfBytes = await buildReceiptPdf(
        receiptData: receiptData,
        config: config,
      );

      final fileName = filename ?? 'Recibo_${receiptData.receiptNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')],
        text: 'Recibo da venda #${receiptData.receiptNumber}',
      );
    } catch (e) {
      throw Exception('Erro ao compartilhar recibo: $e');
    }
  }

  /// Salva um recibo localmente
  static Future<String> saveReceipt({
    required ReceiptData receiptData,
    required ReceiptConfig config,
    String? filename,
  }) async {
    try {
      final pdfBytes = await buildReceiptPdf(
        receiptData: receiptData,
        config: config,
      );

      final directory = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${directory.path}/$_receiptsFolder');
      
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = filename ?? 'Recibo_${receiptData.receiptNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${receiptsDir.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Erro ao salvar recibo: $e');
    }
  }

  /// Visualiza um recibo em PDF
  static Future<void> previewReceipt({
    required ReceiptData receiptData,
    required ReceiptConfig config,
    required BuildContext context,
  }) async {
    try {
      final pdfBytes = await buildReceiptPdf(
        receiptData: receiptData,
        config: config,
      );

      final prefix = AppLocalizations.of(context)!.receiptPrefix;
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: '${prefix}_${receiptData.receiptNumber}',
        usePrinterSettings: false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao visualizar recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Lista recibos salvos localmente
  static Future<List<File>> getSavedReceipts() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${directory.path}/$_receiptsFolder');
      
      if (!await receiptsDir.exists()) {
        return [];
      }

      final files = await receiptsDir.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Remove um recibo salvo
  static Future<void> deleteReceipt(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Erro ao deletar recibo: $e');
    }
  }

  /// Gera configuração padrão do recibo baseada no usuário logado
  static Future<ReceiptConfig> getDefaultConfig() async {
    final user = await AuthService.getCurrentUser();
    final storeName = user?['name'] ?? 'NOVA - Loja';
    
    return ReceiptConfig(
      storeName: storeName,
      currency: 'FCFA',
      showStoreInfo: true,
      showFooter: true,
      footerText: 'Sistema NOVA - Gestão de Vendas',
    );
  }

  /// Cria um recibo de venda
  static ReceiptData createSaleReceipt({
    required String receiptNumber,
    required DateTime date,
    required List<ReceiptItem> items,
    required double total,
    required double paid,
    ReceiptClient? client,
    double discount = 0.0,
    double tax = 0.0,
    String? paymentMethod,
    String? cashierName,
    String? notes,
  }) {
    return ReceiptData(
      receiptNumber: receiptNumber,
      date: date,
      type: ReceiptType.sale,
      client: client,
      items: items,
      subtotal: total + discount - tax,
      discount: discount,
      tax: tax,
      total: total,
      paid: paid,
      change: paid - total,
      paymentMethod: paymentMethod,
      cashierName: cashierName,
      notes: notes,
    );
  }

  /// Cria um recibo de devolução
  static ReceiptData createRefundReceipt({
    required String receiptNumber,
    required DateTime date,
    required List<ReceiptItem> items,
    required double total,
    ReceiptClient? client,
    String? cashierName,
    String? notes,
  }) {
    return ReceiptData(
      receiptNumber: receiptNumber,
      date: date,
      type: ReceiptType.refund,
      client: client,
      items: items,
      subtotal: total,
      total: total,
      paid: 0.0,
      change: 0.0,
      cashierName: cashierName,
      notes: notes,
    );
  }

  /// Cria um resumo diário
  static ReceiptData createDailySummaryReceipt({
    required String receiptNumber,
    required DateTime date,
    required List<ReceiptItem> items,
    required double total,
    String? cashierName,
  }) {
    return ReceiptData(
      receiptNumber: receiptNumber,
      date: date,
      type: ReceiptType.daily,
      items: items,
      subtotal: total,
      total: total,
      paid: total,
      change: 0.0,
      cashierName: cashierName,
    );
  }

  /// Cria um relatório de estoque
  static ReceiptData createInventoryReceipt({
    required String receiptNumber,
    required DateTime date,
    required List<ReceiptItem> items,
    String? cashierName,
  }) {
    return ReceiptData(
      receiptNumber: receiptNumber,
      date: date,
      type: ReceiptType.inventory,
      items: items,
      subtotal: 0.0,
      total: 0.0,
      paid: 0.0,
      change: 0.0,
      cashierName: cashierName,
    );
  }
}

/// Widget para exibir opções de impressão
class ReceiptPrintOptions extends StatelessWidget {
  final ReceiptData receiptData;
  final ReceiptConfig config;
  final VoidCallback? onSaved;

  const ReceiptPrintOptions({
    super.key,
    required this.receiptData,
    required this.config,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Opções de Recibo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Botão de Visualizar
            ElevatedButton.icon(
              onPressed: () => _previewReceipt(context),
              icon: const Icon(Icons.visibility),
              label: const Text('Visualizar Recibo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Botão de Imprimir
            ElevatedButton.icon(
              onPressed: () => _printReceipt(context),
              icon: const Icon(Icons.print),
              label: const Text('Imprimir Recibo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Botão de Compartilhar
            ElevatedButton.icon(
              onPressed: () => _shareReceipt(context),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar Recibo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Botão de Salvar
            ElevatedButton.icon(
              onPressed: () => _saveReceipt(context),
              icon: const Icon(Icons.save),
              label: const Text('Salvar Localmente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previewReceipt(BuildContext context) async {
    try {
      await PrintService.previewReceipt(
        receiptData: receiptData,
        config: config,
        context: context,
      );
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erro ao visualizar recibo: $e');
      }
    }
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      await PrintService.printReceipt(
        receiptData: receiptData,
        config: config,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo enviado para impressão!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erro ao imprimir recibo: $e');
      }
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      await PrintService.shareReceipt(
        receiptData: receiptData,
        config: config,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo compartilhado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erro ao compartilhar recibo: $e');
      }
    }
  }

  Future<void> _saveReceipt(BuildContext context) async {
    try {
      await PrintService.saveReceipt(
        receiptData: receiptData,
        config: config,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        onSaved?.call();
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erro ao salvar recibo: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
