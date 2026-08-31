import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../../features/settings/data/settings_repository.dart';

class ReceiptScreen extends StatefulWidget {
  final SaleModel sale;

  const ReceiptScreen({super.key, required this.sale});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    final currency = settings.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () => _shareReceipt(context, settings),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print',
            onPressed: () => _printReceipt(context, settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Receipt Card
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Shop Header
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: settings.shopLogo != null && File(settings.shopLogo!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(settings.shopLogo!),
                              fit: BoxFit.cover,
                              width: 56,
                              height: 56,
                            ),
                          )
                        : Center(
                            child: Text(
                              settings.shopName.isNotEmpty ? settings.shopName[0].toUpperCase() : 'A',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    settings.shopName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (settings.shopAddress.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      settings.shopAddress,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (settings.shopPhone.isNotEmpty)
                    Text(
                      settings.shopPhone,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (settings.receiptHeader.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      settings.receiptHeader,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 14),
                  _DashedLine(),
                  const SizedBox(height: 12),

                  // Receipt Info
                  _ReceiptInfoRow(label: 'Receipt #', value: widget.sale.receiptNumber),
                  const SizedBox(height: 4),
                  _ReceiptInfoRow(
                    label: 'Date',
                    value: DateFormatter.formatReceiptDate(widget.sale.createdAt),
                  ),
                  if (widget.sale.customerName != null) ...[
                    const SizedBox(height: 4),
                    _ReceiptInfoRow(label: 'Customer', value: widget.sale.customerName!),
                  ],

                  const SizedBox(height: 12),
                  _DashedLine(),
                  const SizedBox(height: 12),

                  // Items Header
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Item',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      Text(
                        'Qty',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Items
                  ...widget.sale.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@ ${CurrencyFormatter.format(item.unitPrice, currency: currency)}',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: Text(
                                CurrencyFormatter.format(item.totalPrice, currency: currency),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 8),
                  _DashedLine(),
                  const SizedBox(height: 12),

                  // Totals
                  if (widget.sale.discountAmount > 0)
                    _ReceiptRow(
                      label: 'Discount',
                      value: '- ${CurrencyFormatter.format(widget.sale.discountAmount, currency: currency)}',
                      valueColor: Colors.red,
                    ),
                  if (widget.sale.taxAmount > 0)
                    _ReceiptRow(
                      label: 'Tax',
                      value: CurrencyFormatter.format(widget.sale.taxAmount, currency: currency),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.sale.total, currency: currency),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ReceiptRow(
                    label: 'Paid (${widget.sale.paymentMethod})',
                    value: CurrencyFormatter.format(widget.sale.amountPaid, currency: currency),
                  ),
                  if (widget.sale.change > 0)
                    _ReceiptRow(
                      label: 'Change',
                      value: CurrencyFormatter.format(widget.sale.change, currency: currency),
                      valueColor: AppTheme.successColor,
                    ),

                  const SizedBox(height: 14),
                  _DashedLine(),
                  const SizedBox(height: 12),

                  // Footer
                  Text(
                    settings.receiptFooter.isNotEmpty
                        ? settings.receiptFooter
                        : AppConstants.defaultReceiptFooter,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Powered by Ashop',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printReceipt(context, settings),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Print'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                    label: const Text('New Sale'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<pw.Document> _generatePdf(SettingsRepository settings) async {
    final doc = pw.Document();
    final currency = settings.currency;

    pw.Widget? logoWidget;
    if (settings.shopLogo != null && File(settings.shopLogo!).existsSync()) {
      try {
        final logoBytes = File(settings.shopLogo!).readAsBytesSync();
        final logoImage = pw.MemoryImage(logoBytes);
        logoWidget = pw.Container(
          width: 48,
          height: 48,
          margin: const pw.EdgeInsets.only(bottom: 6),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(logoImage, fit: pw.BoxFit.cover),
          ),
        );
      } catch (_) {}
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoWidget != null) logoWidget,
              pw.Text(
                settings.shopName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              if (settings.shopAddress.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(settings.shopAddress, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
              ],
              if (settings.shopPhone.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text('Tel: ${settings.shopPhone}', style: const pw.TextStyle(fontSize: 9)),
              ],
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Receipt #: ${widget.sale.receiptNumber}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Date: ${DateFormatter.formatReceiptDate(widget.sale.createdAt)}', style: const pw.TextStyle(fontSize: 9)),
                    if (widget.sale.customerName != null) pw.Text('Customer: ${widget.sale.customerName}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              // Items Table
              ...widget.sale.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.productName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.Text(
                              '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice, currency: currency)}',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        CurrencyFormatter.format(item.totalPrice, currency: currency),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(CurrencyFormatter.format(widget.sale.subtotal, currency: currency), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (widget.sale.discountAmount > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('-${CurrencyFormatter.format(widget.sale.discountAmount, currency: currency)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              if (widget.sale.taxAmount > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(CurrencyFormatter.format(widget.sale.taxAmount, currency: currency), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    CurrencyFormatter.format(widget.sale.total, currency: currency),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paid (${widget.sale.paymentMethod})', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(CurrencyFormatter.format(widget.sale.amountPaid, currency: currency), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (widget.sale.change > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Change', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(CurrencyFormatter.format(widget.sale.change, currency: currency), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Text(
                settings.receiptFooter.isNotEmpty ? settings.receiptFooter : AppConstants.defaultReceiptFooter,
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text('Powered by Ashop', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );
    return doc;
  }

  Future<void> _shareReceipt(BuildContext context, SettingsRepository settings) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating Receipt PDF...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );

    try {
      final doc = await _generatePdf(settings);
      final pdfBytes = await doc.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${widget.sale.receiptNumber}.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);

      if (!context.mounted) return;
      await Share.shareXFiles([XFile(file.path)], subject: 'Receipt ${widget.sale.receiptNumber}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing receipt: $e'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _printReceipt(BuildContext context, SettingsRepository settings) async {
    try {
      final doc = await _generatePdf(settings);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'receipt_${widget.sale.receiptNumber}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing receipt: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    double x = 0;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
