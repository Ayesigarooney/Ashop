import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_theme.dart';
import '../../features/notes/data/models/note_model.dart';

/// Shared utilities for Notes feature - colors, export, etc.
class NoteUtils {
  NoteUtils._();

  // Get note-specific styling based on colorIndex
  static Map<String, Color> getNoteColors(int colorIndex, bool isDark) {
    switch (colorIndex) {
      case 0: // Purple / General
        return {
          'bg': isDark ? const Color(0xFF1E1C38) : const Color(0xFFF7F6FF),
          'border': isDark ? const Color(0xFF4C44CC) : const Color(0xFFD6D3FF),
          'accent': AppTheme.primaryColor,
        };
      case 1: // Teal / Customer
        return {
          'bg': isDark ? const Color(0xFF0F2620) : const Color(0xFFE6FFF7),
          'border': isDark ? const Color(0xFF009966) : const Color(0xFF99FFDD),
          'accent': AppTheme.accentColor,
        };
      case 2: // Amber / Todo
        return {
          'bg': isDark ? const Color(0xFF2C2210) : const Color(0xFFFFFBF0),
          'border': isDark ? const Color(0xFF996600) : const Color(0xFFFFEBAA),
          'accent': AppTheme.warningColor,
        };
      case 3: // Red / Idea
        return {
          'bg': isDark ? const Color(0xFF2C1418) : const Color(0xFFFFF0F2),
          'border': isDark ? const Color(0xFF992233) : const Color(0xFFFFCCD4),
          'accent': AppTheme.dangerColor,
        };
      case 4: // Slate / Supplier
      default:
        return {
          'bg': isDark ? const Color(0xFF1B1D2E) : const Color(0xFFF2F4F8),
          'border': isDark ? const Color(0xFF3F4666) : const Color(0xFFD1D5DB),
          'accent': const Color(0xFF7F8C8D),
        };
    }
  }

  // Text Export Implementation
  static Future<void> exportAsTxt(BuildContext context, NoteModel note) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final titleSafe = note.title.isNotEmpty
          ? note.title.replaceAll(RegExp(r'[^\w\s\-]'), '_')
          : 'untitled_note';
      final file = File('${tempDir.path}/$titleSafe.txt');

      final content = '${note.title.isNotEmpty ? note.title.toUpperCase() : 'UNTITLED NOTE'}\n'
          'Category: ${note.category}\n'
          'Last Updated: ${DateFormat('yyyy-MM-dd HH:mm').format(note.updatedAt)}\n'
          '--------------------------------------------------------\n\n'
          '${note.content}';

      await file.writeAsString(content, flush: true);

      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: note.title.isNotEmpty ? note.title : 'Business Note',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting txt: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  // PDF Export Implementation
  static Future<void> exportAsPdf(BuildContext context, NoteModel note) async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context pwCtx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            note.title.isNotEmpty ? note.title : 'UNTITLED NOTE',
                            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Category: ${note.category}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                    pw.Text(
                      'Last Updated: ${DateFormat('yyyy-MM-dd HH:mm').format(note.updatedAt)}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 16),
                pw.Text(
                  note.content,
                  style: const pw.TextStyle(fontSize: 11, height: 1.5),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      final tempDir = await getTemporaryDirectory();
      final titleSafe = note.title.isNotEmpty
          ? note.title.replaceAll(RegExp(r'[^\w\s\-]'), '_')
          : 'untitled_note';
      final file = File('${tempDir.path}/$titleSafe.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);

      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_rounded, color: AppTheme.primaryColor),
                title: const Text('Share PDF File'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Share.shareXFiles([XFile(file.path)], subject: note.title);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print_rounded, color: Colors.blue),
                title: const Text('Print Note / Save as PDF'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdfBytes,
                    name: '$titleSafe.pdf',
                  );
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }
}

// Extension to darken colors for light theme accent text
extension NoteColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
