

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ✅ ADD THIS IMPORT
import 'home_screen.dart';


class InvoicePreviewScreen extends StatelessWidget {
  final Map invoiceData;
  const InvoicePreviewScreen({super.key, required this.invoiceData});

  @override
  Widget build(BuildContext context) {

    final String status =
    (invoiceData["status"] ?? "unpaid").toString().toLowerCase();


    final party = invoiceData["party"] ?? {};

    final List<Map<String, dynamic>> items =
    List<Map<String, dynamic>>.from(invoiceData["items"] ?? []);

    final double taxableAmount =
    (invoiceData["subtotal"] as num).toDouble();

    final double totalTax =
    (invoiceData["total_tax"] as num).toDouble();

    final double cgst = totalTax / 2;
    final double sgst = totalTax / 2;

    final business = invoiceData["business"] ?? {};





    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Invoice Created"),
        // ✅ UPDATED BACK BUTTON
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
            );
          },
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ⭐ Invoice Box Frame
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // BUSINESS NAME
                // Text(
                //   "CENTRAL WARE HOUSING CORP. LTD.",
                //   style: const TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),

                Text(
                  business["industry"] ?? "",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if ((business["gstin"] ?? "").toString().isNotEmpty)
                  Text("GSTIN ${business["gstin"]}"),


                Text("GSTIN ${party["gst_number"] ?? ""}"),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Invoice No: ${invoiceData["invoice_number"]}"),
                        Text("Invoice Date: ${_format(invoiceData["invoice_date"])}"),
                        Text("Due Date: ${_format(invoiceData["due_date"])}"),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),

                // BILL TO
                Text("Bill To", style: title),
                Text(party["party_name"] ?? ""),
                Text("${party["billing_city"]}, ${party["billing_state"]} - ${party["billing_pincode"]}"),
                Text("Mobile: ${party["contact_number"] ?? ""}"),
                const SizedBox(height: 20),

                // ITEMS TABLE
                const Text("Items", style: title),
                const SizedBox(height: 8),


                Table(
                  border: TableBorder.all(color: Colors.black38),
                  columnWidths: const {
                    0: FixedColumnWidth(30),
                    1: FlexColumnWidth(),
                    2: FixedColumnWidth(50),
                    3: FixedColumnWidth(40),
                    4: FixedColumnWidth(55),
                    5: FixedColumnWidth(60),
                    6: FixedColumnWidth(65),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade300),
                      children: [
                        cell("No", bold: true),
                        cell("Item", bold: true),
                        cell("HSN", bold: true),
                        cell("Qty", bold: true),
                        cell("Rate", bold: true),
                        cell("Tax", bold: true),
                        cell("Total", bold: true),
                      ],
                    ),

                    ...List.generate(items.length, (i) {
                      final it = items[i];
                      return TableRow(
                        children: [
                          cell("${i + 1}"),
                          cell(it["description"]),
                          cell(it["hsn"] ?? ""),
                          cell("${it["qty"]}"),
                          cell("₹ ${it["price"]}"),
                          cell(
                            "₹ ${it["gst_amount"]}\n(${it["gst_percent"]}%)",
                          ),
                          cell("₹ ${it["line_total"]}"),
                        ],
                      );
                    }),
                  ],
                ),




                const SizedBox(height: 22),



                const Divider(),

                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      rowText("Taxable Amount", taxableAmount),
                      rowText("CGST", cgst),
                      rowText("SGST", sgst),
                      const SizedBox(height: 6),
                      rowText(
                        "Total Amount",
                        invoiceData["grand_total"],
                        bold: true,
                      ),
                      rowText(
                        "Received Amount",
                        invoiceData["received_amount"] ?? 0,
                      ),
                      rowText(
                        "Balance",
                        invoiceData["balance_amount"] ?? 0,
                        bold: true,
                      ),
                    ],
                  ),
                ),




              ],
            ),
          ),

          const SizedBox(height: 25),

          // PAYMENT STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                party["party_name"] ?? "",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "₹ ${invoiceData["grand_total"]}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 6),
          // const Text("Unpaid", style: TextStyle(color: Colors.red, fontSize: 16)),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: status == "paid"
                  ? Colors.green
                  : status == "partial"
                  ? Colors.orange
                  : Colors.red,
            ),
          ),

          const SizedBox(height: 20),

          // SHARE PAYMENT LINK BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.share),
              label: const Text("Share Payment Link"),
              onPressed: () {
                final link = invoiceData["payment_link"];

                if (link == null || link.toString().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment link not available")),
                  );
                  return;
                }

                Share.share(
                  "Please pay ₹${invoiceData["balance_amount"]}\n$link",
                );
              },

            ),
          ),
        ],
      ),

      // FOOTER BUTTONS
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            bottomBtn(
              Icons.print,
              "Print",
              onTap: () => _printInvoice(context),
            ),
            bottomBtn(
              Icons.download,
              "Download",
              onTap: () => _downloadInvoice(context),
            ),
            bottomBtn(
              Icons.share,
              "Share",
              onTap: () => _shareInvoice(context),
            ),
            // ✅ UPDATED DONE BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                );
              },
              child: const Text("Done"),
            ),
          ],

        ),
      ),


    );
  }

  // ===============================
// PDF GENERATOR (ADD HERE)
// ===============================

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "INVOICE",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Text("Party: ${invoiceData["party"]["party_name"]}"),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Item", "Qty", "Price", "Total"],
                data: (invoiceData["items"] as List).map((item) {
                  return [
                    item["description"],
                    item["qty"].toString(),
                    item["price"].toString(),
                    item["line_total"].toString(),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                "Grand Total: ₹ ${invoiceData["grand_total"]}",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }


  void _printInvoice(BuildContext context) async {
    final pdfData = await _generatePdf();
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }


  void _downloadInvoice(BuildContext context) async {
    final pdfData = await _generatePdf();
    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      "${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    await file.writeAsBytes(pdfData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved to ${file.path}")),
    );
  }

  void _shareInvoice(BuildContext context) async {
    final pdfData = await _generatePdf();
    final dir = await getTemporaryDirectory();

    final file = File("${dir.path}/invoice.pdf");
    await file.writeAsBytes(pdfData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Invoice",
    );
  }


  static String _format(String? dt) {
    if (dt == null) return "";
    return DateFormat("dd/MM/yyyy").format(DateTime.parse(dt));
  }
}

// ---------------------------
// BELOW CLASS (REQUIRED)
// ---------------------------

const title = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
const summary = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

// Cell widget for table
Widget cell(String text, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.all(6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}


// Bottom icon button (CLICKABLE)
Widget bottomBtn(
    IconData icon,
    String text, {
      required VoidCallback onTap,
    }) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    ),
  );
}

Widget rowText(String label, num value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(
      "$label  ₹ ${value.toStringAsFixed(2)}",
      style: TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
      ),
    ),
  );
}



