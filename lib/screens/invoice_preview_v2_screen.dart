import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoicePreviewV2Screen extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const InvoicePreviewV2Screen({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final party = invoice['party'];
    final items = List<Map<String, dynamic>>.from(invoice['items']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Created"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.6,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _header(),

            const SizedBox(height: 16),

            _billTo(party),

            const SizedBox(height: 16),

            _itemsTable(items),

            const SizedBox(height: 16),

            _totals(),

          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "TAX INVOICE",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("Invoice No: ${invoice['invoice_number']}"),
            Text("Date: ${invoice['invoice_date']}"),
            Text("Due: ${invoice['due_date']}"),
          ],
        )
      ],
    );
  }

  // ---------------- BILL TO ----------------

  Widget _billTo(Map<String, dynamic> party) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bill To", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(party['party_name'] ?? ''),
        Text(party['address'] ?? ''),
        Text("Mobile: ${party['contact_number'] ?? ''}"),
      ],
    );
  }

  // ---------------- ITEMS TABLE ----------------

  Widget _itemsTable(List<Map<String, dynamic>> items) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade400),
      columnWidths: const {
        0: FixedColumnWidth(30),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(50),
        3: FixedColumnWidth(60),
        4: FixedColumnWidth(60),
        5: FixedColumnWidth(70),
      },
      children: [
        _tableHeader(),
        ...items.asMap().entries.map((e) {
          final i = e.key + 1;
          final item = e.value;
          return _itemRow(i, item);
        }),
      ],
    );
  }

  TableRow _tableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFEFEFEF)),
      children: [
        _th("No"),
        _th("Item"),
        _th("Qty"),
        _th("Rate"),
        _th("Tax"),
        _th("Total"),
      ],
    );
  }

  TableRow _itemRow(int no, Map<String, dynamic> item) {
    return TableRow(
      children: [
        _td(no.toString()),
        _td(item['description']),
        _td("${item['qty']} ${item['unit']}"),
        _td("₹${item['price']}"),
        _td("₹${item['gst_amount']}"),
        _td("₹${item['line_total']}"),
      ],
    );
  }

  // ---------------- TOTALS ----------------

  Widget _totals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _totalRow("Taxable Amount", invoice['subtotal']),
        _totalRow("CGST", invoice['cgst']),
        _totalRow("SGST", invoice['sgst']),
        const Divider(),
        _totalRow(
          "Total Amount",
          invoice['grand_total'],
          bold: true,
        ),
        const SizedBox(height: 6),
        _totalRow("Received", invoice['received_amount']),
        _totalRow("Balance", invoice['balance_amount'], bold: true),
      ],
    );
  }

  Widget _totalRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          const SizedBox(width: 12),
          Text("₹ ${value ?? 0}",
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  // ---------------- CELL HELPERS ----------------

  static Widget _th(String text) =>
      Padding(
        padding: EdgeInsets.all(6),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      );

  static Widget _td(String text) =>
      Padding(
        padding: EdgeInsets.all(6),
        child: Text(text),
      );
}
