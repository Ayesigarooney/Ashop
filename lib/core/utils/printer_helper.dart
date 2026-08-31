// ignore_for_file: depend_on_referenced_packages
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/sale/data/models/sale_model.dart';
import '../../features/settings/data/settings_repository.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';
import '../../core/config/constants.dart';

class PrinterHelper {
  static Future<Uint8List> generateReceiptPdf(
    SaleModel sale,
    SettingsRepository settings,
  ) async {
    final pdf = pw.Document();
    final currency = settings.currency;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                settings.shopName,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (settings.shopAddress.isNotEmpty)
                pw.Text(
                  settings.shopAddress,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              if (settings.shopPhone.isNotEmpty)
                pw.Text(
                  settings.shopPhone,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt #', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    sale.receiptNumber,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    DateFormatter.formatReceiptDate(sale.createdAt),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.Divider(),
              // Items
              ...sale.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.productName,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${item.quantity}x ${CurrencyFormatter.format(item.unitPrice, currency: currency)}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            CurrencyFormatter.format(
                              item.totalPrice,
                              currency: currency,
                            ),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              if (sale.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Discount:',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '- ${CurrencyFormatter.format(sale.discountAmount, currency: currency)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(sale.total, currency: currency),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Paid (${sale.paymentMethod}):',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(
                      sale.amountPaid,
                      currency: currency,
                    ),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              if (sale.change > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Change:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      CurrencyFormatter.format(sale.change, currency: currency),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Text(
                settings.receiptFooter.isNotEmpty
                    ? settings.receiptFooter
                    : AppConstants.defaultReceiptFooter,
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Powered by Ashop',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
