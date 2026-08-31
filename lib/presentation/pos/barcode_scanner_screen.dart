import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Scan Barcode',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (_, state, __) => Icon(
                state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final value = barcodes.first.rawValue;
                if (value != null) {
                  _scanned = true;
                  Navigator.pop(context, value);
                }
              }
            },
          ),
          // Overlay
          CustomPaint(painter: _ScannerOverlayPainter(), child: Container()),
          // Bottom Instructions
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 80),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Point camera at a barcode to scan',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Manual Entry
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextButton(
                onPressed: () => _showManualEntry(context),
                child: Text(
                  'Enter barcode manually',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntry(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _ManualEntryDialog(),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      Navigator.pop(context, result);
    }
  }
}

class _ManualEntryDialog extends StatefulWidget {
  const _ManualEntryDialog();

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Manual Entry',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(hintText: 'Enter barcode number'),
        autofocus: true,
        keyboardType: TextInputType.text,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_ctrl.text.isNotEmpty) {
              Navigator.pop(context, _ctrl.text.trim());
            }
          },
          child: const Text('Search'),
        ),
      ],
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final cutoutWidth = size.width * 0.75;
    final cutoutHeight = cutoutWidth * 0.6;
    final left = (size.width - cutoutWidth) / 2;
    final top = (size.height - cutoutHeight) / 2;
    final cutout = Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(cutout, const Radius.circular(12)),
        ),
      ),
      paint,
    );

    // Corner lines
    final linePaint = Paint()
      ..color = AppTheme.accentColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    // Top-left
    canvas.drawLine(
      Offset(left, top + cornerLen),
      Offset(left, top),
      linePaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLen, top),
      linePaint,
    );
    // Top-right
    canvas.drawLine(
      Offset(left + cutoutWidth - cornerLen, top),
      Offset(left + cutoutWidth, top),
      linePaint,
    );
    canvas.drawLine(
      Offset(left + cutoutWidth, top),
      Offset(left + cutoutWidth, top + cornerLen),
      linePaint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(left, top + cutoutHeight - cornerLen),
      Offset(left, top + cutoutHeight),
      linePaint,
    );
    canvas.drawLine(
      Offset(left, top + cutoutHeight),
      Offset(left + cornerLen, top + cutoutHeight),
      linePaint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(left + cutoutWidth, top + cutoutHeight - cornerLen),
      Offset(left + cutoutWidth, top + cutoutHeight),
      linePaint,
    );
    canvas.drawLine(
      Offset(left + cutoutWidth, top + cutoutHeight),
      Offset(left + cutoutWidth - cornerLen, top + cutoutHeight),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
