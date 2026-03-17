import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../domain/entities/order.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../data/local/providers.dart';
import 'customer_search_screen.dart';
import 'stamp_result_screen.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_audio.dart';
import '../../common_widgets/error_snackbar.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final Order? order;

  const QrScannerScreen({super.key, this.order});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    // Provide feedback a code was successfully read
    AppAudio.playBeep();
    AppHaptics.lightImpact();

    try {
      final result = await ref
          .read(customerRepositoryProvider)
          .getCustomerByQr(code);

      if (!mounted) return;

      result.fold(
        (failure) {
          if (!mounted) return;
          ErrorSnackBar.show(context, 'Error: ${failure.message}');
          setState(() => _isProcessing = false);
        },
        (customer) {
          if (customer == null) {
            if (!mounted) return;
            ErrorSnackBar.show(context, 'Customer not found');
            setState(() => _isProcessing = false);
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    StampResultScreen(customer: customer, order: widget.order),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _onManualSearch() async {
    controller.stop();
    final customer = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
    );

    if (customer != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              StampResultScreen(customer: customer, order: widget.order),
        ),
      );
    } else {
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Customer QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),

          // Overlay (Simple Border)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Manual Search Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ElevatedButton.icon(
                onPressed: _onManualSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search by Name / Phone'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
