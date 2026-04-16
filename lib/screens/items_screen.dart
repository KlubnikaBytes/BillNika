import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'item_detail_screen.dart';
import 'create_new_item_screen.dart';
import 'home_screen.dart';
import 'parties_screen.dart';
import 'for_you_screen.dart';
import 'more_screen.dart';

import 'package:flutter_project/widgets/app_background.dart';



const String baseUrl = 'http://192.168.1.11:8000/api';
// const String baseUrl = "http://10.0.2.2:8000/api";


class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  bool loading = true;
  List items = [];
  int navIndex = 2; // Items selected

  bool lowStockOnly = false;

  // ===== SORT STATE =====
  String? sortBy;
// values: az, za, qty_low, qty_high

// ===== FILTER STATE =====
  bool filterLowStock = false;
  bool filterInStock = false;
  bool filterNotInStock = false;

// 🔴 Used to show red mark on "Filter By" chip
  bool filterApplied = false;

  bool isSearching = false;
  TextEditingController searchController = TextEditingController();



  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems({String? search}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    String url = "$baseUrl/items";

    if (search != null && search.isNotEmpty) {
      url += "?search=$search"; // 🔥 API SEARCH
    }

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    setState(() {
      items = decoded['data'] ?? [];
      loading = false;
    });
  }

  // Future<void> fetchItems() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token') ?? "";
  //
  //   final res = await http.get(
  //     Uri.parse("$baseUrl/items"),
  //     headers: {
  //       "Authorization": "Bearer $token",
  //       "Accept": "application/json",
  //     },
  //   );
  //
  //   final decoded = jsonDecode(res.body);
  //
  //   setState(() {
  //     items = decoded['data'] ?? [];
  //     loading = false;
  //   });
  // }

  // void handleBottomNavTap(BuildContext context, int index) {
  //   if (index == 0) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //     );
  //   } else if (index == 1) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const PartiesScreen()),
  //     );
  //   } else if (index == 2) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const ItemsScreen()),
  //     );
  //   }
  // }

  void handleBottomNavTap(BuildContext context, int index) {
    Widget target;

    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const PartiesScreen();
        break;
      case 2:
        target = const ItemsScreen();
        break;
      case 3:
        target = const ForYouScreen();
        break;
      case 4:
        target = const MoreScreen();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => target),
          (route) => false, // 🔥 prevents stack piling
    );
  }



  void _openSortFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String? tempSort = sortBy;
        bool tempLow = filterLowStock;
        bool tempInStock = filterInStock;
        bool tempNotInStock = filterNotInStock;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              // padding: const EdgeInsets.all(16),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16, // ✅ FIX
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sort & Filter",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===== SORT BY =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sort By",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempSort = null;
                            tempLow = false;
                            tempInStock = false;
                            tempNotInStock = false;
                          });
                        },
                        child: const Text(
                          "CLEAR",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  RadioListTile(
                    title: const Text("Item name - A to Z"),
                    value: "az",
                    groupValue: tempSort,
                    onChanged: (v) => setModalState(() => tempSort = v),
                  ),
                  RadioListTile(
                    title: const Text("Item name - Z to A"),
                    value: "za",
                    groupValue: tempSort,
                    onChanged: (v) => setModalState(() => tempSort = v),
                  ),
                  RadioListTile(
                    title: const Text("Quantity - Low to High"),
                    value: "qty_low",
                    groupValue: tempSort,
                    onChanged: (v) => setModalState(() => tempSort = v),
                  ),
                  RadioListTile(
                    title: const Text("Quantity - High to Low"),
                    value: "qty_high",
                    groupValue: tempSort,
                    onChanged: (v) => setModalState(() => tempSort = v),
                  ),

                  const SizedBox(height: 12),

                  // ===== FILTER BY =====
                  const Text("Filter By", style: TextStyle(fontWeight: FontWeight.w600)),

                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text("Low Stock"),
                        selected: tempLow,
                        onSelected: (v) => setModalState(() => tempLow = v),
                      ),
                      FilterChip(
                        label: const Text("In Stock"),
                        selected: tempInStock,
                        onSelected: (v) => setModalState(() => tempInStock = v),
                      ),
                      FilterChip(
                        label: const Text("Not in Stock"),
                        selected: tempNotInStock,
                        onSelected: (v) => setModalState(() => tempNotInStock = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // APPLY BUTTON
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 48,
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       setState(() {
                  //         sortBy = tempSort;
                  //         filterLowStock = tempLow;
                  //         filterInStock = tempInStock;
                  //         filterNotInStock = tempNotInStock;
                  //
                  //         filterApplied =
                  //             sortBy != null ||
                  //                 filterLowStock ||
                  //                 filterInStock ||
                  //                 filterNotInStock;
                  //       });
                  //
                  //       Navigator.pop(context);
                  //     },
                  //     child: const Text("Apply"),
                  //   ),
                  // ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white, // ✅ FIX: makes text white
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          sortBy = tempSort;
                          filterLowStock = tempLow;
                          filterInStock = tempInStock;
                          filterNotInStock = tempNotInStock;

                          filterApplied =
                              sortBy != null ||
                                  filterLowStock ||
                                  filterInStock ||
                                  filterNotInStock;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Apply",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {

    // ================= APPLY SORT & FILTER =================
    List filteredItems = List.from(items);

    // -------- SORTING --------
    if (sortBy == "az") {
      filteredItems.sort(
            (a, b) => a['name']
            .toString()
            .toLowerCase()
            .compareTo(b['name'].toString().toLowerCase()),
      );
    }

    if (sortBy == "za") {
      filteredItems.sort(
            (a, b) => b['name']
            .toString()
            .toLowerCase()
            .compareTo(a['name'].toString().toLowerCase()),
      );
    }

    if (sortBy == "qty_low") {
      filteredItems.sort(
            (a, b) =>
            (a['opening_stock'] ?? 0).compareTo(b['opening_stock'] ?? 0),
      );
    }

    if (sortBy == "qty_high") {
      filteredItems.sort(
            (a, b) =>
            (b['opening_stock'] ?? 0).compareTo(a['opening_stock'] ?? 0),
      );
    }

    return Scaffold(

      // backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   title: const Text("Items", style: TextStyle(color: Colors.black)),
      //   actions: const [
      //     Icon(Icons.search, color: Colors.deepPurple),
      //     SizedBox(width: 16),
      //     Icon(Icons.settings, color: Colors.deepPurple),
      //     SizedBox(width: 12),
      //   ],
      // ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search items...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            fetchItems(search: value); // 🔥 LIVE API SEARCH
          },
        )
            : const Text("Items", style: TextStyle(color: Colors.black)),

        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.deepPurple,
            ),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
              });

              fetchItems(); // 🔥 reset list
            },
          ),
          const SizedBox(width: 8),
          const Icon(Icons.settings, color: Colors.deepPurple),
          const SizedBox(width: 12),
        ],
      ),

      // ================= BODY =================
        body: AppBackground(
          child: Column(
            children: [
          // ---------- FILTER CHIPS ----------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _GlowChip(
                  text: "Low Stock",
                  selected: lowStockOnly,
                  onTap: () {
                    setState(() {
                      lowStockOnly = !lowStockOnly;
                    });
                  },
                ),
                _Chip(text: "Select Category", icon: Icons.keyboard_arrow_down),
                // _Chip(text: "Filter By", icon: Icons.filter_list),
                _GlowChip(
                  text: "Filter By",
                  selected: filterApplied, // 🔴 red mark when active
                  onTap: _openSortFilterSheet,
                ),

              ],
            ),
          ),




          // ---------- ITEM LIST ----------
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];


                final openingStock = (item['opening_stock'] ?? 0).toDouble();
                final lowQty = (item['low_stock_quantity'] ?? 0).toDouble();
                final lowAlert = item['low_stock_alert'] == true;

                final isLowStock = lowAlert && openingStock <= lowQty;

// 🔥 FILTER WHEN LOW STOCK CHIP IS ON
                if (lowStockOnly && !isLowStock) {
                  return const SizedBox.shrink();
                }

                if ((lowStockOnly || filterLowStock) && !isLowStock) {
                  return const SizedBox.shrink();
                }

                if (filterInStock && openingStock <= 0) {
                  return const SizedBox.shrink();
                }

                if (filterNotInStock && openingStock > 0) {
                  return const SizedBox.shrink();
                }



                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (_) => ItemDetailScreen(item: item),
                  //     ),
                  //   );
                  // },
                  onTap: () async {
                    final deleted = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(itemId: item['id']),

                      ),
                    );

                    if (deleted == true) {
                      fetchItems(); // 🔁 reload item list from API
                    }
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

                        // ICON
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            item['name'][0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Sales Price",
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        "₹ ${item['sales_price'] ?? 0}",
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Purchase Price",
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        "₹ ${item['purchase_price'] ?? 0}",
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // STOCK
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Text(
                            //   "${item['opening_stock'] ?? 0}",
                            //   style: const TextStyle(
                            //     fontSize: 16,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            Text(
                              "${item['opening_stock'] ?? 0}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? Colors.red : Colors.black,
                              ),
                            ),

                            Text(
                              item['unit'] ?? "PCS",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
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

      // ================= FLOATING BUTTONS =================

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ===== CREATE NEW ITEM =====
              Expanded(
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.only(right: 8),
                  child:
                  ElevatedButton.icon(
                    onPressed: () async {
                      final newItem = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateNewItemScreen(
                            primary: Colors.deepPurple,
                          ),
                        ),
                      );

                      // 🔁 AFTER SAVE → REFRESH ITEM LIST
                      if (newItem != null) {
                        fetchItems();
                      }
                    },

                    icon: const Icon(Icons.add, size: 22), // ✅ REQUIRED
                    label: const Text(
                      "Create New Item",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ), // ✅ REQUIRED

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),


              // ===== BULK ACTION =====
              Expanded(
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.only(left: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file, size: 22),
                    label: const Text(
                      "Bulk Action",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2E), // dark gray like screenshot
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // 🔥 pill shape
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),


      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          handleBottomNavTap(context, index);
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Parties",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: "Items",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            activeIcon: Icon(Icons.star),
            label: "For You",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "More",
          ),
        ],
      ),

    );
  }
}

// ================= CHIP WIDGET =================
class _Chip extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _Chip({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(text),
          if (icon != null) ...[
            const SizedBox(width: 6),
            Icon(icon, size: 16),
          ]
        ],
      ),
    );
  }
}

class _GlowChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _GlowChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.red; // 🔴 RED MARK

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.1) // light red bg
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: selected ? activeColor : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.close, size: 16, color: activeColor),
            ]
          ],
        ),
      ),
    );
  }
}
