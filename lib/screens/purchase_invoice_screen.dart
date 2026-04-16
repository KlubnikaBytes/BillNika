// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class PurchaseInvoiceScreen extends StatelessWidget {
//   final Map data;
//
//   const PurchaseInvoiceScreen({super.key, required this.data});
//
//   @override
//   Widget build(BuildContext context) {
//     final party = data["party"] ?? {};
//     final items = List<Map<String, dynamic>>.from(data["items"] ?? []);
//
//     double subtotal = (data["subtotal"] ?? 0).toDouble();
//     double totalTax = (data["total_tax"] ?? 0).toDouble();
//     double grandTotal = (data["grand_total"] ?? 0).toDouble();
//     double received = (data["received_amount"] ?? 0).toDouble();
//     double balance = (data["balance_amount"] ?? 0).toDouble();
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//
//       appBar: AppBar(
//         title: const Text("Purchase Invoice"),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0.5,
//       ),
//
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//
//           // ================= HEADER =================
//           Text(
//             "PURCHASE",
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.deepPurple,
//             ),
//           ),
//
//           const SizedBox(height: 10),
//
//           Text("Purchase No: ${data["purchase_number"] ?? ""}"),
//           Text("Date: ${_format(data["purchase_date"])}"),
//
//           const SizedBox(height: 16),
//           const Divider(),
//
//           // ================= PARTY =================
//           const Text("Bill To", style: TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 6),
//
//           Text(party["party_name"] ?? ""),
//           Text(party["contact_number"] ?? ""),
//
//           const SizedBox(height: 20),
//
//           // ================= ITEMS =================
//           const Text("Items", style: TextStyle(fontWeight: FontWeight.bold)),
//
//           const SizedBox(height: 8),
//
//           Table(
//             border: TableBorder.all(color: Colors.grey),
//             children: [
//
//               // HEADER
//               TableRow(
//                 children: [
//                   _cell("Item", bold: true),
//                   _cell("Qty", bold: true),
//                   _cell("Rate", bold: true),
//                   _cell("Tax", bold: true),
//                   _cell("Total", bold: true),
//                 ],
//               ),
//
//               // DATA
//               ...items.map((e) {
//                 return TableRow(
//                   children: [
//                     _cell(e["description"] ?? ""),
//                     _cell("${e["qty"] ?? 0}"),
//                     _cell("₹ ${e["price"] ?? 0}"),
//                     _cell("₹ ${(e["gst_amount"] ?? 0)}"),
//                     _cell("₹ ${(e["line_total"] ?? 0)}"),
//                   ],
//                 );
//               }).toList(),
//             ],
//           ),
//
//           const SizedBox(height: 20),
//           const Divider(),
//
//           // ================= TOTAL =================
//           Align(
//             alignment: Alignment.centerRight,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 _row("Subtotal", subtotal),
//                 _row("Tax", totalTax),
//                 _row("Total", grandTotal, bold: true),
//                 _row("Paid", received),
//                 _row("Balance", balance, bold: true),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 20),
//
//           // ================= STATUS =================
//           Text(
//             (data["status"] ?? "UNPAID").toString().toUpperCase(),
//             style: TextStyle(
//               color: balance == 0 ? Colors.green : Colors.red,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= HELPERS =================
//
//   static Widget _cell(String text, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.all(6),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontWeight: bold ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
//
//   static Widget _row(String label, double value, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Text(
//         "$label : ₹ ${value.toStringAsFixed(2)}",
//         style: TextStyle(
//           fontWeight: bold ? FontWeight.bold : FontWeight.w500,
//         ),
//       ),
//     );
//   }
//
//   static String _format(String? date) {
//     if (date == null) return "";
//     return DateFormat("dd/MM/yyyy").format(DateTime.parse(date));
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseInvoiceScreen extends StatelessWidget {
  final Map data;



  const PurchaseInvoiceScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final party = data["party"] ?? {};
    final business = data["business"] ?? {};
    final items = List<Map<String, dynamic>>.from(data["items"] ?? []);

    double subtotal = (data["subtotal"] ?? 0).toDouble();
    double totalTax = (data["total_tax"] ?? 0).toDouble();
    double grandTotal = (data["grand_total"] ?? 0).toDouble();
    double received = (data["received_amount"] ?? 0).toDouble();
    double balance = (data["balance_amount"] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Purchase"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [

          // ================= MAIN INVOICE BOX =================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // const Text(
                    //   "YOUR COMPANY NAME",
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    Text(
                      business["name"] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: const Text(
                        "PURCHASE",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 6),
                Text("GSTIN: ${business["gstin"] ?? ""}"),
                Text(business["address"] ?? ""),

                const Divider(height: 25),

                // ================= PURCHASE DETAILS =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Purchase No: ${data["id"]}"),
                    Text("Date: ${_format(data["purchase_date"])}"),
                  ],
                ),

                const SizedBox(height: 16),

                // ================= BILL TO =================
                const Text(
                  "BILL FROM",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(party["party_name"] ?? ""),
                Text("Mobile: ${party["contact_number"] ?? ""}"),
                Text("Place of Supply: ${data["place_of_supply"] ?? ""}"),

                const SizedBox(height: 16),

                // ================= TABLE =================
                Table(
                  border: TableBorder.all(color: Colors.grey),
                  columnWidths: const {
                    0: FixedColumnWidth(30),
                    1: FlexColumnWidth(),
                    2: FixedColumnWidth(60), // HSN
                    3: FixedColumnWidth(45),
                    4: FixedColumnWidth(55),
                    5: FixedColumnWidth(55),
                    6: FixedColumnWidth(60),
                  },
                  children: [

                    // HEADER
                    TableRow(
                      decoration:
                      BoxDecoration(color: Colors.grey.shade300),
                      children: [
                        _cell("No", bold: true),
                        _cell("Item", bold: true),
                        _cell("HSN", bold: true), // ✅ NEW
                        _cell("Qty", bold: true),
                        _cell("Rate", bold: true),
                        _cell("Tax", bold: true),
                        _cell("Total", bold: true),
                      ],
                    ),

                    // DATA
                    ...List.generate(items.length, (i) {
                      final e = items[i];
                      return TableRow(
                        children: [
                          _cell("${i + 1}"),
                          _cell(e["description"] ?? ""),
                          _cell(e["hsn"] ?? ""), // ✅ NEW
                          _cell("${e["qty"]}"),
                          _cell("₹ ${e["price"]}"),
                          _cell("₹ ${e["gst_amount"]}"),
                          _cell("₹ ${e["line_total"]}"),
                        ],
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // ================= TOTAL =================
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _row("Taxable Amount", subtotal),
                      _row("Tax", totalTax),
                      const SizedBox(height: 6),
                      _row("Total Amount", grandTotal, bold: true),
                      _row("Paid Amount", received),
                      _row("Balance", balance, bold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= FOOTER =================
                const Text(
                  "Terms & Conditions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text("1. Goods once sold will not be taken back."),
                const Text("2. Subject to local jurisdiction."),

              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= STATUS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                party["party_name"] ?? "",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "₹ $grandTotal",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            (data["status"] ?? "UNPAID").toString().toUpperCase(),
            style: TextStyle(
              color: balance == 0 ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ================= ACTION BUTTONS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _iconBtn(Icons.print, "Print"),
              _iconBtn(Icons.download, "Download"),
              _iconBtn(Icons.share, "Share"),
            ],
          )
        ],
      ),
    );
  }

  // ================= HELPERS =================

  static Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  static Widget _row(String label, double value, {bool bold = false}) {
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

  static Widget _iconBtn(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(text),
      ],
    );
  }

  static String _format(String? date) {
    if (date == null) return "";
    return DateFormat("dd/MM/yyyy").format(DateTime.parse(date));
  }
}