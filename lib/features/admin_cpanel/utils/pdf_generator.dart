import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/currency_formatter.dart';
import '../../../models/order_model.dart';

class PdfGenerator {
  static Future<Uint8List> generateReceipt(Order order) async {
    final pdf = pw.Document();

    // Cargar el logo desde los assets
    final logoData = await rootBundle.load('assets/images/logo_icon.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5, // Tamaño Media Carta (A5)
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── ENCABEZADO ──
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Image(logoImage, height: 40),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'TIENDA VERTEX',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── FECHA Y UBICACIÓN ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Luque, Paraguay', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    DateFormat('dd/MM/yy').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // ── TÍTULO ──
              pw.Center(
                child: pw.Text(
                  'COMPROBANTE DE COMPRA',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // ── DATOS DEL CLIENTE ──
              pw.Text('Nombre: ${order.customerName}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text('Teléfono: ${order.phone}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text(
                'Dirección: ${order.neighborhood}, ${order.street1} ${order.street2 ?? ""}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              if (order.reference != null && order.reference!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Referencia: ${order.reference}', style: const pw.TextStyle(fontSize: 11)),
              ],
              pw.SizedBox(height: 20),

              // ── TABLA DE PRODUCTOS ──
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 1, color: PdfColors.black),
                  top: pw.BorderSide(width: 1, color: PdfColors.black),
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(40), // Cant
                  1: pw.FlexColumnWidth(3),   // Prod
                  2: pw.FlexColumnWidth(2),   // Precio
                },
                children: [
                  // Cabecera
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Cant.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Producto', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Precio', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Filas de productos
                  ...order.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.title, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            CurrencyFormatter.format(item.lineTotal),
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── TOTALES ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: ${CurrencyFormatter.format(order.subtotal)}', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text('Envío: ${order.shippingCost == 0 ? "Gratis" : CurrencyFormatter.format(order.shippingCost)}', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Total pagado: ${CurrencyFormatter.format(order.total)}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // ── FOOTER LEGAL ──
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Este documento es un comprobante de compra y no constituye una factura legal.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}