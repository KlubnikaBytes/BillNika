import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'item_detail_screen.dart';

import 'package:flutter_project/widgets/app_background.dart';


const String baseUrl = "http://127.0.0.1:8000/api";
// const String baseUrl = "http://10.0.2.2:8000/api";


class StockSummaryScreen extends StatefulWidget {
  const StockSummaryScreen({super.key});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends State<StockSummaryScreen> {
  double totalValue = 0;
  List items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStockSummary();
  }

  Future<void> fetchStockSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/stock-summary"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    setState(() {
      totalValue =
          (decoded['data']['total_stock_value'] ?? 0).toDouble();
      items = decoded['data']['items'] ?? [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.deepPurple),
        title: const Text("Stock Summary",
            style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.grid_on, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),

      // ================= BODY =================
        body: AppBackground(
          child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          // ================= ALL CATEGORIES =================
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.deepPurple, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "All Categories",
                      style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.deepPurple),
                  ],
                ),
              ),
            ),
          ),

          // ================= TOTAL STOCK VALUE =================
          Container(
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE + VIEW REPORT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Stock Value",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: const [
                        Text(
                          "VIEW FULL REPORT",
                          style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.picture_as_pdf,
                            size: 18, color: Colors.deepPurple),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "₹ ${totalValue.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ================= HEADER =================
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text("Item Name",
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Quantity",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Value",
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ================= ITEM LIST =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            // ItemDetailScreen(item: item),
                        ItemDetailScreen(itemId: item['id']),

                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // NAME + BARCODE
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              if ((item['barcode'] ?? "")
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  item['barcode'],
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                item['name'],
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        // QUANTITY
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${item['quantity']} ${item['unit']}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),

                        // VALUE
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₹ ${item['value']}",
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
        ),
    );
  }
}
