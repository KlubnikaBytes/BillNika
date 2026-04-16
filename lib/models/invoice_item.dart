class InvoiceItem {
  final int itemId;
  final String description;
  final double qty;
  final String unit;
  final double price;
  final double gstPercent;
  final double gstAmount;
  final double lineTotal;

  InvoiceItem({
    required this.itemId,
    required this.description,
    required this.qty,
    required this.unit,
    required this.price,
    required this.gstPercent,
    required this.gstAmount,
    required this.lineTotal,
  });

  // ✅ FOR API (SAVE PURCHASE)
  Map<String, dynamic> toApiJson() {
    return {
      "item_id": itemId,
      "description": description,
      "qty": qty,
      "unit": unit,
      "price": price,
      "gst_percent": gstPercent,
    };
  }

  // ✅ FOR SCAN AUTO-FILL (IMPORTANT)
  factory InvoiceItem.fromApi(Map json) {
    return InvoiceItem(
      itemId: json['item_id'] ?? 0,
      description: json['description'] ?? "",
      qty: (json['qty'] ?? 0).toDouble(),
      unit: json['unit'] ?? "PCS",
      price: (json['price'] ?? 0).toDouble(),
      gstPercent: (json['gst_percent'] ?? 0).toDouble(),
      gstAmount: (json['gst_amount'] ?? 0).toDouble(),
      lineTotal: (json['line_total'] ?? 0).toDouble(),
    );
  }
}