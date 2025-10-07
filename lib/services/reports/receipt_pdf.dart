import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Tipos de recibo disponíveis
enum ReceiptType {
  sale, // Recibo de venda
  refund, // Recibo de devolução
  daily, // Resumo diário
  inventory, // Relatório de estoque
}

/// Configurações do recibo
class ReceiptConfig {
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? storeEmail;
  final String? logoUrl;
  final String currency;
  final bool showLogo;
  final bool showStoreInfo;
  final bool showFooter;
  final String? footerText;

  const ReceiptConfig({
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    this.storeEmail,
    this.logoUrl,
    this.currency = 'FCFA',
    this.showLogo = false,
    this.showStoreInfo = true,
    this.showFooter = true,
    this.footerText,
  });
}

/// Item do recibo
class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? description;
  final String? sku;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.description,
    this.sku,
  });
}

/// Cliente do recibo
class ReceiptClient {
  final String? name;
  final String? phone;
  final String? email;
  final String? address;

  const ReceiptClient({
    this.name,
    this.phone,
    this.email,
    this.address,
  });
}

/// Dados completos do recibo
class ReceiptData {
  final String receiptNumber;
  final DateTime date;
  final ReceiptType type;
  final ReceiptClient? client;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paid;
  final double change;
  final String? paymentMethod;
  final String? cashierName;
  final String? notes;

  const ReceiptData({
    required this.receiptNumber,
    required this.date,
    required this.type,
    this.client,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    required this.paid,
    this.change = 0.0,
    this.paymentMethod,
    this.cashierName,
    this.notes,
  });
}

/// Gera um recibo PDF completo
Future<Uint8List> buildReceiptPdf({
  required ReceiptData receiptData,
  required ReceiptConfig config,
}) async {
  final doc = pw.Document();
  final pageWidth = 300.0; // Largura padrão para recibo térmico
  
  doc.addPage(
    pw.Page(
      pageFormat: pw.PdfPageFormat(pageWidth, double.infinity),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _buildHeader(config),
          pw.SizedBox(height: 8),
          _buildReceiptInfo(receiptData, config),
          pw.SizedBox(height: 8),
          _buildClientInfo(receiptData.client, config),
          pw.SizedBox(height: 8),
          _buildItemsTable(receiptData.items, config),
          pw.SizedBox(height: 8),
          _buildTotals(receiptData, config),
          pw.SizedBox(height: 8),
          _buildPaymentInfo(receiptData, config),
          if (receiptData.notes != null) ...[
            pw.SizedBox(height: 8),
            _buildNotes(receiptData.notes!, config),
          ],
          pw.SizedBox(height: 16),
          _buildFooter(config),
        ],
      ),
    ),
  );
  
  return doc.save();
}

/// Gera recibo simples (compatibilidade com versão anterior)
Future<Uint8List> buildSimpleReceiptPdf({
  required String storeName,
  String? clientName,
  required DateTime date,
  required List<Map<String, dynamic>> items,
  required double total,
  required double paid,
  required double troco,
}) async {
  final receiptItems = items.map((item) => ReceiptItem(
    name: item['name'].toString(),
    quantity: item['qty'] as int,
    unitPrice: (item['price'] as num).toDouble(),
    total: (item['total'] as num).toDouble(),
  )).toList();

  final receiptData = ReceiptData(
    receiptNumber: '${DateTime.now().millisecondsSinceEpoch}',
    date: date,
    type: ReceiptType.sale,
    client: clientName != null && clientName.isNotEmpty 
        ? ReceiptClient(name: clientName) 
        : null,
    items: receiptItems,
    subtotal: total,
    total: total,
    paid: paid,
    change: troco,
  );

  final config = ReceiptConfig(
    storeName: storeName,
    currency: 'FCFA',
  );

  return buildReceiptPdf(receiptData: receiptData, config: config);
}

/// Cabeçalho do recibo
pw.Widget _buildHeader(ReceiptConfig config) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (config.showLogo && config.logoUrl != null)
        pw.Image(pw.MemoryImage(Uint8List(0)), width: 60, height: 60),
      pw.Text(
        config.storeName,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
      if (config.showStoreInfo) ...[
        if (config.storeAddress != null)
          pw.Text(
            config.storeAddress!,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        if (config.storePhone != null)
          pw.Text(
            config.storePhone!,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        if (config.storeEmail != null)
          pw.Text(
            config.storeEmail!,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
      ],
      pw.Divider(),
    ],
  );
}

/// Informações do recibo
pw.Widget _buildReceiptInfo(ReceiptData data, ReceiptConfig config) {
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final receiptTypeText = {
    ReceiptType.sale: 'VENDA',
    ReceiptType.refund: 'DEVOLUÇÃO',
    ReceiptType.daily: 'RESUMO DIÁRIO',
    ReceiptType.inventory: 'ESTOQUE',
  }[data.type] ?? 'RECIBO';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Recibo: ${data.receiptNumber}'),
          pw.Text(receiptTypeText),
        ],
      ),
      pw.Text('Data: ${dateFormat.format(data.date)}'),
      if (data.cashierName != null)
        pw.Text('Vendedor: ${data.cashierName}'),
      pw.Divider(),
    ],
  );
}

/// Informações do cliente
pw.Widget _buildClientInfo(ReceiptClient? client, ReceiptConfig config) {
  if (client == null || client.name == null) {
    return pw.Container();
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('CLIENTE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text('Nome: ${client.name}'),
      if (client.phone != null) pw.Text('Telefone: ${client.phone}'),
      if (client.email != null) pw.Text('Email: ${client.email}'),
      if (client.address != null) pw.Text('Endereço: ${client.address}'),
      pw.Divider(),
    ],
  );
}

/// Tabela de itens
pw.Widget _buildItemsTable(List<ReceiptItem> items, ReceiptConfig config) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('ITENS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FixedColumnWidth(30),
          2: const pw.FixedColumnWidth(60),
          3: const pw.FixedColumnWidth(60),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: pw.PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Produto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Qtd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Preço', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...items.map((item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.name),
                    if (item.sku != null) pw.Text(item.sku!, style: const pw.TextStyle(fontSize: 8)),
                    if (item.description != null) pw.Text(item.description!, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item.quantity.toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('${item.unitPrice.toStringAsFixed(0)} ${config.currency}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('${item.total.toStringAsFixed(0)} ${config.currency}'),
              ),
            ],
          )),
        ],
      ),
    ],
  );
}

/// Totais do recibo
pw.Widget _buildTotals(ReceiptData data, ReceiptConfig config) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Subtotal:'),
          pw.Text('${data.subtotal.toStringAsFixed(0)} ${config.currency}'),
        ],
      ),
      if (data.discount > 0) ...[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Desconto:'),
            pw.Text('-${data.discount.toStringAsFixed(0)} ${config.currency}'),
          ],
        ),
      ],
      if (data.tax > 0) ...[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Taxa:'),
            pw.Text('${data.tax.toStringAsFixed(0)} ${config.currency}'),
          ],
        ),
      ],
      pw.Divider(),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('${data.total.toStringAsFixed(0)} ${config.currency}', 
                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ],
  );
}

/// Informações de pagamento
pw.Widget _buildPaymentInfo(ReceiptData data, ReceiptConfig config) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('PAGAMENTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Pago:'),
          pw.Text('${data.paid.toStringAsFixed(0)} ${config.currency}'),
        ],
      ),
      if (data.change > 0) ...[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Troco:'),
            pw.Text('${data.change.toStringAsFixed(0)} ${config.currency}'),
          ],
        ),
      ],
      if (data.paymentMethod != null) ...[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Método:'),
            pw.Text(data.paymentMethod!),
          ],
        ),
      ],
    ],
  );
}

/// Notas do recibo
pw.Widget _buildNotes(String notes, ReceiptConfig config) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('OBSERVAÇÕES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(notes),
    ],
  );
}

/// Rodapé do recibo
pw.Widget _buildFooter(ReceiptConfig config) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Divider(),
      if (config.showFooter) ...[
        pw.Text(
          'Obrigado pela sua preferência!',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        if (config.footerText != null)
          pw.Text(
            config.footerText!,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
      ],
    ],
  );
}
