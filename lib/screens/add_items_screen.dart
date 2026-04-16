import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'create_new_item_screen.dart';
import 'create_invoice_screen.dart';
import 'package:flutter_project/widgets/app_background.dart';


const String baseUrl = 'http://192.168.1.11:8000/api';
// const String baseUrl = 'static const String baseUrl = 'http://192.168.1.11:8000/api';';
// const String baseUrl = "http://10.0.2.2:8000/api";


class AddItemsScreen extends StatefulWidget {
  final List<InvoiceItem> existingItems;
  final bool isPurchase; // ✅ NEW

  const AddItemsScreen({super.key,
    required this.existingItems,
    this.isPurchase = false, // default = sales
  });

  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  final Color primary = const Color(0xFF4C3FF0);

  List<ItemModel> allItems = [];
  // Map<int, double> selectedQty = {}; // item_id → qty
  List<InvoiceItem> selectedItems = []; // ✅ SINGLE SOURCE OF TRUTH


  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }


  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/items"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);

      setState(() {
        allItems = (json['data'] as List)
            .map((e) => ItemModel.fromJson(e))
            .toList();


        selectedItems = List.from(widget.existingItems);




        loading = false;
      });
    } else {
      loading = false;
    }
  }


  void _finishSelection() {
    Navigator.pop(context, selectedItems);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: _searchBox(),
      ),



      body: AppBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _topButtons(),
            const SizedBox(height: 12),
            ...allItems.map(_buildItemTile).toList(),
          ],
        ),
      ),


      bottomNavigationBar: _bottomBar(),
    );
  }

  // ---------------------------------------------
  // Search Bar UI
  // ---------------------------------------------
  Widget _searchBox() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.black54),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Search by name or code",
              style: TextStyle(color: Colors.black54),
            ),
          ),
          Icon(Icons.qr_code_scanner, color: Colors.black54),
          SizedBox(width: 8),
          Icon(Icons.mic_none, color: Colors.black54),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // Create Item + Category
  // ---------------------------------------------
  Widget _topButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "All Categories",
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              // final created = await Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => CreateNewItemScreen(primary: primary),
              //
              //   ),
              // );
              //
              // if (created == true) _loadItems();

              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateNewItemScreen(primary: primary),
                ),
              );

              // ✅ FIX: check for returned item instead of true
              if (created != null) {
                await _loadItems();
              }


            },
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "+ Create New Item",
                style: TextStyle(
                  color: Color(0xFF4C3FF0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  // ---------------------------------------------
  // Item tile
  // ---------------------------------------------
  Widget _buildItemTile(ItemModel item) {
    // final qty = selectedQty[item.id] ?? 0;
    final index =
    selectedItems.indexWhere((e) => e.itemId == item.id);
    final qty = index >= 0 ? selectedItems[index].qty : 0;


    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Avatar letter
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              item.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.black87, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  "₹ ${widget.isPurchase ? item.purchasePrice : item.salesPrice}/${item.unit}",
                  style: const TextStyle(color: Colors.black87),
                ),
                Text(
                  "STOCK: ${item.openingStock}${item.unit}",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),

          // ADD / +/- UI
          qty == 0
              ? GestureDetector(
            // onTap: () => _increaseQty(item.id),
            onTap: () {
              setState(() {
                if (index >= 0) {
                  selectedItems[index] =
                      selectedItems[index].copyWith(qty: qty + 1);
                } else {
                  selectedItems.add(
                    InvoiceItem(
                      itemId: item.id,
                      description: item.name,
                      qty: 1,
                      unit: item.unit ?? "PCS",
                      price: widget.isPurchase
                          ? item.purchasePrice
                          : item.salesPrice,
                      gstPercent: item.gstPercent ?? 0,
                    ),
                  );
                }
              });
            },

            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: primary),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "ADD +",
                style: TextStyle(color: primary),
              ),
            ),
          )
              : Row(
            children: [
              GestureDetector(
                // onTap: () => _decreaseQty(item.id),
                onTap: () {
                  setState(() {
                    if (qty <= 1) {
                      selectedItems.removeAt(index);
                    } else {
                      selectedItems[index] =
                          selectedItems[index].copyWith(qty: qty - 1);
                    }
                  });
                },

                child: _roundButton(Icons.remove),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  qty.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                // onTap: () => _increaseQty(item.id),
                onTap: () {
                  setState(() {
                    if (index >= 0) {
                      selectedItems[index] =
                          selectedItems[index].copyWith(qty: qty + 1);
                    } else {
                      selectedItems.add(
                        InvoiceItem(
                          itemId: item.id,
                          description: item.name,
                          qty: 1,
                          unit: item.unit ?? "PCS",
                          price: item.salesPrice,
                          gstPercent: item.gstPercent ?? 0,
                        ),
                      );
                    }
                  });
                },

                child: _roundButton(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18),
    );
  }

  // ---------------------------------------------
  // Bottom bar summary
  // ---------------------------------------------
  Widget _bottomBar() {
    double totalQty = 0;
    double totalAmount = 0;

    // selectedQty.forEach((id, qty) {
    //   if (qty > 0) {
    //     final item = allItems.firstWhere((e) => e.id == id);
    //     totalQty += qty;
    //     totalAmount += (item.salesPrice * qty);
    //   }
    // });

    for (final item in selectedItems) {
      totalQty += item.qty;
      totalAmount += item.lineTotal;
    }


    // 🚫 Hide completely if no items
    if (totalQty == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12, // ✅ FIX HERE
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ================= ROW 1 =================
          Row(
            children: [
              Text(
                "${totalQty.toStringAsFixed(1)} ITEMS",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                "₹ ${totalAmount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ================= ROW 2 =================
          Row(
            children: [
              // LEFT TEXT (CLICKABLE)
              Expanded(
                child: GestureDetector(
                  onTap: _finishSelection, // 👈 SAME AS Generate Bill
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Add more details",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Additional charges, Round off...",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              // GENERATE BILL BUTTON
              ElevatedButton(
                onPressed: _finishSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white, // ✅ ADD THIS
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Generate Bill",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

// ============================================================
// ITEM MODEL
// ============================================================
class ItemModel {
  final int id;
  final String name;
  final String? unit;
  final double salesPrice;
  final double purchasePrice;
  final double? gstPercent;
  final double openingStock;

  ItemModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.salesPrice,
    required this.purchasePrice, // ✅ ADD
    required this.openingStock,
    this.gstPercent,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      unit: json['unit'] ?? 'PCS',
      salesPrice: (json['sales_price'] ?? 0).toDouble(),
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      openingStock: (json['opening_stock'] ?? 0).toDouble(),
      gstPercent: json['gst_percent'] != null
          ? (json['gst_percent']).toDouble()
          : 0,
    );
  }
}
