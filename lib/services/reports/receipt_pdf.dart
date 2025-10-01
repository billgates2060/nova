import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildReceiptPdf({
  required String storeName,
  required DateTime date,
  required List<Map<String, dynamic>> items, // {name, qty, price, total}
  required double total,
  required double paid,
  required double troco,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            storeName,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Data: $date'),
          pw.Divider(),
          pw.Table(
            border: null,
            children: [
              pw.TableRow(
                children: [
                  pw.Text('Produto'),
                  pw.Text('Qtd'),
                  pw.Text('Preço'),
                  pw.Text('Total'),
                ],
              ),
              ...items.map(
                (i) => pw.TableRow(
                  children: [
                    pw.Text(i['name'].toString()),
                    pw.Text(i['qty'].toString()),
                    pw.Text('${i['price']} CFA'),
                    pw.Text('${i['total']} CFA'),
                  ],
                ),
              ),
            ],
          ),
          pw.Divider(),
          pw.Text('Total: ${total.toStringAsFixed(2)} CFA'),
          pw.Text('Pago: ${paid.toStringAsFixed(2)} CFA'),
          pw.Text('Troco: ${troco.toStringAsFixed(2)} CFA'),
        ],
      ),
    ),
  );
  return doc.save();
}
