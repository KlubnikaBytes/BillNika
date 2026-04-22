import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_new_item_screen.dart';
import 'package:flutter_project/widgets/app_background.dart';


const String baseUrl = 'http://192.168.1.12:8000/api';
// const String baseUrl = "http://10.0.2.2:8000/api";


class ItemDetailScreen extends StatefulWidget {
  final int itemId;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
  });


  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // late Map<String, dynamic> item;
  Map<String, dynamic>? item;


  // ✅ ADD THESE TWO LINES HERE
  bool loadingTimeline = true;
  List timeline = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    fetchItemDetail(); // 🔥 LOAD FULL ITEM FROM API
  }


  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

    backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.deepPurple),
        // actions: const [
        //   Icon(Icons.share, color: Colors.deepPurple),
        //   SizedBox(width: 16),
        //   Icon(Icons.edit, color: Colors.deepPurple),
        //   SizedBox(width: 16),
        //   Icon(Icons.delete, color: Colors.red),
        //   SizedBox(width: 12),
        // ],
        actions: [
          const Icon(Icons.share, color: Colors.deepPurple),
          const SizedBox(width: 16),

          IconButton(
            icon: const Icon(Icons.edit, color: Colors.deepPurple),
            onPressed: () async {
              final updatedItem = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateNewItemScreen(
                    primary: Colors.deepPurple,
                    item: item!,

                  ),
                ),
              );

              if (updatedItem != null) {
                setState(() {
                  item = Map<String, dynamic>.from(updatedItem); // 🔥 AUTO REFRESH
                });

                fetchTimeline();
              }


            },
          ),

          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteItemSheet,
          ),

          const SizedBox(width: 12),
        ],

      ),

      // ================= BODY =================
        body: AppBackground(
          child: Column(
            children: [

          // ---------- HEADER ----------
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item!['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "View Item Report ›",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    item!['name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- SUMMARY ----------
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summary("Sales Price", "₹ ${item!['sales_price'] ?? 0}"),

                _summary("Purchase Price", "₹ ${item!['purchase_price'] ?? 0}"),

                _summary(
                  "Stock Quantity",
                  "${item!['opening_stock'] ?? 0} ${item!['unit'] ?? 'PCS'}",

                ),
              ],
            ),
          ),

          // ---------- STOCK VALUE ----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: Text(
              "Stock Value  ₹ ${item!['stock_value'] ?? 0}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ---------- TABS ----------
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: "Item Timeline"),
              Tab(text: "Details"),
              Tab(text: "Party Wise Prices"),
            ],
          ),

          // ---------- TAB CONTENT ----------
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _timelineTab(),
                _detailsTab(item!),
                _partyWiseTab(),
              ],
            ),
          ),
        ],
      ),
        ),

      // ================= BOTTOM BUTTON =================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: SizedBox(
      //   height: 52,
      //   width: 220,
      //   child: ElevatedButton(
      //     onPressed: () {},
      //     style: ElevatedButton.styleFrom(
      //       backgroundColor: Colors.deepPurple,
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(30),
      //       ),
      //       elevation: 6,
      //     ),
      //     child: const Text(
      //       "Adjust Stock",
      //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      //     ),
      //   ),
      // ),

      floatingActionButton: SafeArea(
        child: SizedBox(
          height: 52,
          width: 220,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.tune, size: 20), // optional icon
            label: const Text(
              "Adjust Stock",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple, // ✅ WHITE BG
              foregroundColor: Colors.white, // ✅ TEXT COLOR
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> fetchTimeline() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/items/${widget.itemId}/timeline"),

      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    setState(() {
      timeline = decoded['data'] ?? [];
      loadingTimeline = false;
    });
  }

  void _showDeleteItemSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Delete Item",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                "Are you sure you want to delete this Item? Deleted Item cannot be retrieved",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 20),

              // NO, KEEP
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "No, Keep",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // YES, DELETE
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _deleteItem,
                  child: const Text(
                    "Yes, Delete",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItem() async {
    Navigator.pop(context); // close bottom sheet

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.delete(
      Uri.parse("$baseUrl/items/${item!['id']}"),

      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      // 🔁 go back to item list & refresh
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete item")),
      );
    }
  }




  Future<void> fetchItemDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/items/${widget.itemId}"),

      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      setState(() {
        item = Map<String, dynamic>.from(decoded['data']); // ✅ CORRECT
      });


      // also refresh timeline
      fetchTimeline();
    }
  }



  // ================= WIDGETS =================

  Widget _summary(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }


  Widget _timelineTab() {
    if (loadingTimeline) {
      return const Center(child: CircularProgressIndicator());
    }

    if (timeline.isEmpty) {
      return const Center(child: Text("No stock movement"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final row = timeline[index];

        return _timelineCard(
          title: row['title'] ?? '',
          date: row['date'] ?? '',
          change: (row['change'] ?? 0) as num,
          balance: (row['balance'] ?? 0) as num,
        );
      },
    );
  }



  Widget _detailsTab(Map item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 40,
        runSpacing: 20,
        children: [
          _detail("Item Code", item['item_code'] ?? "-"),
          _detail("Measuring Unit", item['unit'] ?? "PCS"),
          _detail("Low Stock At", "${item['low_stock_quantity'] ?? '-'} PCS"),
          _detail("Tax Rate", "GST @ ${item['gst_percent'] ?? 0}%"),
          _detail("HSN Code", item['hsn_code'] ?? "-"),
          _detail("Item Type", item['item_type'] ?? "Product"),
        ],
      ),
    );
  }

  Widget _partyWiseTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text("Party Wise Item Price"),
          SizedBox(height: 6),
          Text(
            "Enable Party Wise Item Prices",
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String title, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}

class _timelineCard extends StatelessWidget {
  final String title;
  final String date;
  final num change;
  final num balance;

  const _timelineCard({
    required this.title,
    required this.date,
    required this.change,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              if (date.isNotEmpty)
                Text(
                  date.substring(0, 10), // yyyy-mm-dd
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          // RIGHT
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${change > 0 ? '+' : ''}$change PCS",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "$balance PCS",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

