import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../../features/settings/data/settings_repository.dart';

class InvoiceHelper {
  static Future<Uint8List> generateInvoicePdf(
    SaleModel sale,
    SettingsRepository settings,
  ) async {
    final doc = pw.Document();

    final currency = settings.currency;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.shopName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (settings.shopAddress.isNotEmpty)
                      pw.Text(settings.shopAddress),
                    if (settings.shopPhone.isNotEmpty)
                      pw.Text(settings.shopPhone),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Receipt: ${sale.receiptNumber}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Date: ${sale.createdAt.toIso8601String().split('T').first}',
                    ),
                    pw.Text(
                      'Time: ${sale.createdAt.toIso8601String().split('T').last.split('.').first}',
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Item', 'Qty', 'Unit', 'Total'],
              data: sale.items
                  .map(
                    (i) => [
                      i.productName,
                      '${i.quantity}',
                      '${i.unitPrice.toStringAsFixed(2)} $currency',
                      '${i.totalPrice.toStringAsFixed(2)} $currency',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Subtotal: '),
                        pw.Text(
                          '${sale.subtotal.toStringAsFixed(2)} $currency',
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Discount: '),
                        pw.Text(
                          '${sale.discountAmount.toStringAsFixed(2)} $currency',
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Tax: '),
                        pw.Text(
                          '${sale.taxAmount.toStringAsFixed(2)} $currency',
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Total: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${sale.total.toStringAsFixed(2)} $currency',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Paid: '),
                        pw.Text(
                          '${sale.amountPaid.toStringAsFixed(2)} $currency',
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Change: '),
                        pw.Text('${sale.change.toStringAsFixed(2)} $currency'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(settings.receiptFooter, textAlign: pw.TextAlign.center),
          ];
        },
      ),
    );

    return doc.save();
  }
}
