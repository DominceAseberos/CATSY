import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:drift/drift.dart' show Value;
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/providers.dart';
import 'package:catsy_pos/services/receipt_pdf_service.dart';
import 'package:catsy_pos/services/thermal_printer_service.dart';
import 'package:uuid/uuid.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ReceiptState {
  final AsyncValue<String> receiptNumber;
  final bool isSharingPdf;
  final bool isPrinting;
  final Uint8List? pdfBytes;

  const ReceiptState({
    this.receiptNumber = const AsyncValue.loading(),
    this.isSharingPdf = false,
    this.isPrinting = false,
    this.pdfBytes,
  });

  ReceiptState copyWith({
    AsyncValue<String>? receiptNumber,
    bool? isSharingPdf,
    bool? isPrinting,
    Uint8List? pdfBytes,
  }) => ReceiptState(
    receiptNumber: receiptNumber ?? this.receiptNumber,
    isSharingPdf: isSharingPdf ?? this.isSharingPdf,
    isPrinting: isPrinting ?? this.isPrinting,
    pdfBytes: pdfBytes ?? this.pdfBytes,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Riverpod 3.x family notifier.
///
/// In Riverpod 3 (without codegen), the family arg is passed via constructor.
/// The [build] method is parameterless; the [ref] and [state] properties
/// are provided by the [Notifier] base class.
class ReceiptNotifier extends Notifier<ReceiptState> {
  final String _orderId;

  ReceiptNotifier(this._orderId);

  @override
  ReceiptState build() {
    Future.microtask(_generateAndSave);
    return const ReceiptState();
  }

  Future<void> _generateAndSave() async {
    final dao = ref.read(receiptDaoProvider);
    try {
      final existing = await dao.getReceiptByOrderId(_orderId);
      if (existing != null && state.pdfBytes != null) {
        state = state.copyWith(
          receiptNumber: AsyncValue.data(existing.receiptNumber),
        );
        return;
      }

      final pdfService = ref.read(receiptPdfServiceProvider);
      final pdfBytes = await pdfService.generatePdf(_orderId, ref);

      final receiptNumber =
          existing?.receiptNumber ?? await dao.generateReceiptNumber();

      if (existing == null) {
        await dao.insertReceipt(
          ReceiptsTableCompanion(
            id: Value(const Uuid().v4()),
            orderId: Value(_orderId),
            receiptNumber: Value(receiptNumber),
            content: Value(receiptNumber),
            generatedAt: Value(DateTime.now()),
          ),
        );
      }

      state = state.copyWith(
        receiptNumber: AsyncValue.data(receiptNumber),
        pdfBytes: pdfBytes,
      );
    } catch (e, st) {
      state = state.copyWith(receiptNumber: AsyncValue.error(e, st));
    }
  }

  /// Share PDF via system share sheet.
  Future<void> sharePdf({required String receiptNumber}) async {
    state = state.copyWith(isSharingPdf: true);
    try {
      var bytes = state.pdfBytes;
      if (bytes == null) {
        bytes = await ref
            .read(receiptPdfServiceProvider)
            .generatePdf(_orderId, ref);
        state = state.copyWith(pdfBytes: bytes);
      }
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'receipt-$receiptNumber.pdf',
      );
    } finally {
      state = state.copyWith(isSharingPdf: false);
    }
  }

  /// Print to Sunmi built-in thermal printer.
  Future<bool> printSunmi() async {
    state = state.copyWith(isPrinting: true);
    try {
      return await ref
          .read(thermalPrinterServiceProvider)
          .printReceipt(_orderId, ref);
    } finally {
      state = state.copyWith(isPrinting: false);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// `receiptNotifierProvider(orderId)` — one instance per order.
///
/// In Riverpod 3, the family factory receives the arg and passes it
/// to the notifier's constructor.
///
/// Usage:
/// ```dart
/// final state  = ref.watch(receiptNotifierProvider(orderId));
/// final notifier = ref.read(receiptNotifierProvider(orderId).notifier);
/// ```
final receiptNotifierProvider =
    NotifierProvider.family<ReceiptNotifier, ReceiptState, String>(
      (orderId) => ReceiptNotifier(orderId),
    );
