import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:catsy_pos/data/local/providers.dart';

/// Generates a PDF Uint8List for a given orderId.
/// All data sourced from local SQLite — 100% offline.
class ReceiptPdfService {
  const ReceiptPdfService();

  // ── PdfColor palette ──────────────────────────────────────────────────────
  static const _brown = PdfColor.fromInt(0xFF5C3317);
  static const _lightBrown = PdfColor.fromInt(0xFFF5ECD7);
  static const _grey = PdfColor.fromInt(0xFF6B6B6B);
  static const _black = PdfColor.fromInt(0xFF1A1A1A);

  Future<Uint8List> generatePdf(String orderId, Ref ref) async {
    final currency = NumberFormat('₱#,##0.00', 'en_PH');
    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');
    final orderDao = ref.read(orderDaoProvider);
    final txDao = ref.read(transactionDaoProvider);

    final detail = await orderDao.getOrderWithItems(orderId);
    final tx = await txDao.getTransactionForOrder(orderId);
    final order = detail.order;

    if (order == null) {
      throw Exception('Order $orderId not found');
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── Header ──────────────────────────────────────────────
              pw.Container(
                color: _brown,
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CUTSY CAFÉ',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Your Cozy Corner',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '123 Brew Street, Café City\nTel: (02) 555-CAFE',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),
              _dottedDivider(),
              pw.SizedBox(height: 4),

              // ── Receipt metadata ─────────────────────────────────────
              _metaRow('Date', dateFmt.format(order.createdAt)),
              _metaRow(
                'Order #',
                order.id.length > 8
                    ? order.id.substring(order.id.length - 8)
                    : order.id,
              ),
              _metaRow(
                'Type',
                order.orderType == 'dineIn' ? 'Dine-In' : 'Take-Out',
              ),
              if (order.tableId != null) _metaRow('Table', order.tableId!),

              pw.SizedBox(height: 4),
              _dottedDivider(),
              pw.SizedBox(height: 4),

              // ── Items ────────────────────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'ITEMS',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),

              ...detail.itemsWithAddons.map((pair) {
                final item = pair.$1;
                final addons = pair.$2;
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          '${item.quantity}×  ${item.productName}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Spacer(),
                        pw.Text(
                          currency.format(item.totalPrice),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    if (item.specialInstructions != null &&
                        item.specialInstructions!.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14),
                        child: pw.Text(
                          '* ${item.specialInstructions}',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: _grey,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    ...addons.map(
                      (a) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14),
                        child: pw.Text(
                          '+ ${a.addonName}  ${currency.format(a.price)}',
                          style: const pw.TextStyle(fontSize: 7.5, color: _grey),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                  ],
                );
              }),

              _dottedDivider(),
              pw.SizedBox(height: 4),

              // ── Totals ───────────────────────────────────────────────
              _totalRow(
                'Subtotal',
                currency.format(order.subtotal),
                bold: false,
              ),
              if (order.discount > 0)
                _totalRow(
                  'Discount',
                  '- ${currency.format(order.discount)}',
                  bold: false,
                ),
              _totalRow('Tax', currency.format(order.tax), bold: false),
              pw.SizedBox(height: 2),
              _dottedDivider(),
              _totalRow('TOTAL', currency.format(order.total), bold: true),
              _dottedDivider(),

              pw.SizedBox(height: 4),

              // ── Payment ──────────────────────────────────────────────
              if (tx != null) ...[
                _metaRow('Payment', tx.paymentMethod.toUpperCase()),
                _metaRow('Tendered', currency.format(tx.amount)),
                if (tx.change != null && tx.change! > 0)
                  _metaRow('Change', currency.format(tx.change!)),
              ],

              pw.SizedBox(height: 6),
              _dottedDivider(),
              pw.SizedBox(height: 8),

              // ── Footer ───────────────────────────────────────────────
              pw.Container(
                color: _lightBrown,
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for visiting Cutsy Café!',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Collect loyalty stamps with every\npurchase and earn FREE drinks! ☕',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7.5, color: _brown),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  pw.Widget _dottedDivider() =>
      pw.Text('- ' * 38, style: const pw.TextStyle(fontSize: 6, color: _grey));

  pw.Widget _metaRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 60,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 8)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _black,
            ),
          ),
        ),
      ],
    ),
  );

  pw.Widget _totalRow(String label, String value, {required bool bold}) {
    final style = pw.TextStyle(
      fontSize: bold ? 11 : 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: _black,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.Text(label, style: style),
          pw.Spacer(),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}

final receiptPdfServiceProvider = Provider((_) => const ReceiptPdfService());
