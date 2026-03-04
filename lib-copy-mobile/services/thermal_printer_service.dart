import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import '../data/local/providers.dart';

/// Prints a text receipt to the Sunmi built-in thermal printer.
/// Gracefully degrades (returns false) on non-Sunmi devices.
class ThermalPrinterService {
  const ThermalPrinterService();

  static final _currency = NumberFormat('₱#,##0.00', 'en_PH');
  static final _dateFmt = DateFormat('MMM d, yyyy  h:mm a');

  /// Returns `true` if printing succeeded, `false` on non-Sunmi device.
  Future<bool> printReceipt(String orderId, Ref ref) async {
    final orderDao = ref.read(orderDaoProvider);
    final txDao = ref.read(transactionDaoProvider);

    final detail = await orderDao.getOrderWithItems(orderId);
    final tx = await txDao.getTransactionForOrder(orderId);
    final order = detail.order;

    if (order == null) return false;

    try {
      // ── Header ───────────────────────────────────────────────────────
      await SunmiPrinter.printText('CUTSY CAFÉ\n');
      await SunmiPrinter.printText('Your Cozy Corner\n');
      await SunmiPrinter.printText('123 Brew Street, Café City\n');
      await SunmiPrinter.printText('Tel: (02) 555-CAFE\n');
      await SunmiPrinter.printText('--------------------------------\n');

      // ── Metadata ─────────────────────────────────────────────────────
      await SunmiPrinter.printText(
        'Date: ${_dateFmt.format(order.createdAt)}\n',
      );
      final shortId = order.id.length > 8
          ? order.id.substring(order.id.length - 8)
          : order.id;
      await SunmiPrinter.printText('Order #: $shortId\n');
      await SunmiPrinter.printText(
        'Type: ${order.orderType == 'dineIn' ? 'Dine-In' : 'Take-Out'}\n',
      );
      if (order.tableId != null) {
        await SunmiPrinter.printText('Table: ${order.tableId}\n');
      }
      await SunmiPrinter.printText('================================\n');

      // ── Items ─────────────────────────────────────────────────────────
      for (final pair in detail.itemsWithAddons) {
        final item = pair.$1;
        final addons = pair.$2;
        final name = item.productName.length > 16
            ? '${item.productName.substring(0, 14)}..'
            : item.productName;
        final lineTotal = _currency.format(item.totalPrice);
        await SunmiPrinter.printText('${item.quantity}x $name  $lineTotal\n');
        for (final a in addons) {
          await SunmiPrinter.printText(
            '  + ${a.addonName} ${_currency.format(a.price)}\n',
          );
        }
        if (item.specialInstructions != null &&
            item.specialInstructions!.isNotEmpty) {
          await SunmiPrinter.printText('  * ${item.specialInstructions}\n');
        }
      }
      await SunmiPrinter.printText('================================\n');

      // ── Totals ────────────────────────────────────────────────────────
      await SunmiPrinter.printText(
        '${'Subtotal'.padRight(16)} ${_currency.format(order.subtotal)}\n',
      );
      if (order.discount > 0) {
        await SunmiPrinter.printText(
          '${'Discount'.padRight(16)}-${_currency.format(order.discount)}\n',
        );
      }
      await SunmiPrinter.printText(
        '${'Tax'.padRight(16)} ${_currency.format(order.tax)}\n',
      );
      await SunmiPrinter.printText('--------------------------------\n');
      await SunmiPrinter.printText('TOTAL  ${_currency.format(order.total)}\n');
      await SunmiPrinter.printText('================================\n');

      // ── Payment ───────────────────────────────────────────────────────
      if (tx != null) {
        await SunmiPrinter.printText(
          '${'Payment'.padRight(16)} ${tx.paymentMethod.toUpperCase()}\n',
        );
        await SunmiPrinter.printText(
          '${'Tendered'.padRight(16)} ${_currency.format(tx.amount)}\n',
        );
        if (tx.change != null && tx.change! > 0) {
          await SunmiPrinter.printText(
            '${'Change'.padRight(16)} ${_currency.format(tx.change!)}\n',
          );
        }
      }

      // ── Footer ────────────────────────────────────────────────────────
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Thank you for visiting Cutsy Cafe!\n');
      await SunmiPrinter.printText('Collect stamps & earn FREE drinks!\n');
      await SunmiPrinter.lineWrap(3);

      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final thermalPrinterServiceProvider = Provider(
  (_) => const ThermalPrinterService(),
);
