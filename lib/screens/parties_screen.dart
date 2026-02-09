import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'party_detail_screen.dart';
import 'party_flow_screens.dart';
import 'items_screen.dart';
import 'home_screen.dart';
import 'for_you_screen.dart';
import 'more_screen.dart';
import 'package:flutter_project/widgets/app_background.dart';



//
const String baseUrl = "http://127.0.0.1:8000/api";
// const String baseUrl = "http://10.0.2.2:8000/api";


class PartiesScreen extends StatefulWidget {
  final String? initialFilter; // 'pay' | 'receive'

  const PartiesScreen({super.key, this.initialFilter});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  bool loading = true;
  List parties = [];

  // ✅ ADD THESE TWO LINES
  List filteredParties = [];
  String? activeFilter; // 'pay' | 'receive' | null

  String? selectedSort;       // 'az' | 'za' | 'high' | 'low'
  String? selectedPartyType;  // 'customer' | 'supplier'


  // ✅ ADD THIS LINE HERE
  bool hasSortOrFilter = false;


  int navIndex = 1; // Parties selected


  @override
  void initState() {
    super.initState();
    fetchParties();
  }

  // Future<void> fetchParties() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token') ?? "";
  //
  //     final res = await http.get(
  //       Uri.parse("$baseUrl/parties"),
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Accept": "application/json",
  //       },
  //     );
  //
  //     final decoded = jsonDecode(res.body);
  //
  //     // setState(() {
  //     //   parties = decoded['data'] ?? [];
  //     //   loading = false;
  //     // });
  //     setState(() {
  //       parties = decoded['data'] ?? [];
  //       filteredParties = parties; // ✅ default = show all
  //       loading = false;
  //     });
  //
  //   } catch (e) {
  //     loading = false;
  //   }
  // }

  Future<void> fetchParties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final res = await http.get(
        Uri.parse("$baseUrl/parties"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final decoded = jsonDecode(res.body);

      parties = decoded['data'] ?? [];

      // 👇 APPLY INITIAL FILTER (FROM HOME)
      if (widget.initialFilter != null) {
        activeFilter = widget.initialFilter;
        filteredParties = parties.where((p) {
          return p['opening_balance_type'] == widget.initialFilter;
        }).toList();
      } else {
        filteredParties = parties;
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

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




  void applyFilter(String? type) {
    setState(() {
      activeFilter = type;

      if (type == null) {
        filteredParties = parties;
      } else {
        filteredParties = parties.where((p) {
          return p['opening_balance_type'] == type;
        }).toList();
      }
    });
  }


  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   backgroundColor: const Color(0xFFF6F7FB),
    //   resizeToAvoidBottomInset: false,
    return Scaffold(
      resizeToAvoidBottomInset: false,



      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Parties",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.link, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      // ================= BODY =================
      // ================= BODY =================
      body: AppBackground(
        child: Column(
          children: [
            // ---------- FILTER CHIPS ----------
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _filterChip(
                          label: "To Pay",
                          isActive: activeFilter == 'pay',
                          onTap: () =>
                              applyFilter(activeFilter == 'pay' ? null : 'pay'),
                        ),
                        _filterChip(
                          label: "To Collect",
                          isActive: activeFilter == 'receive',
                          onTap: () => applyFilter(
                              activeFilter == 'receive' ? null : 'receive'),
                        ),
                      ],
                    ),
                  ),
                  _chip("Category"),
                  _filterChip(
                    label: "Filter By",
                    isActive: hasSortOrFilter,
                    onTap: () {
                      if (hasSortOrFilter) {
                        setState(() {
                          selectedSort = null;
                          selectedPartyType = null;
                          filteredParties = parties;
                          hasSortOrFilter = false;
                        });
                      } else {
                        _openSortFilterSheet();
                      }
                    },
                  ),
                ],
              ),
            ),

            // ---------- BANNER ----------
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Now take Notes & Appointments on mybillbook",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Try Now",
                      style: TextStyle(color: Colors.blue),
                    ),
                  )
                ],
              ),
            ),

            // ---------- PARTY LIST ----------
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredParties.length,
                itemBuilder: (context, index) {
                  final party = filteredParties[index];
                  final bool isPay =
                      party['opening_balance_type'] == 'pay';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final deleted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartyDetailScreen(
                              partyId: party['id'],
                            ),
                          ),
                        );
                        if (deleted == true) {
                          fetchParties();
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            party['party_name'][0].toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          party['party_name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text("Customer"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹ ${double.parse(party['opening_balance'].toString()).toStringAsFixed(0)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                isPay ? Colors.red : Colors.green,
                              ),
                            ),
                            Icon(
                              isPay
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 18,
                              color:
                              isPay ? Colors.red : Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),


      // ================= FLOATING BUTTON =================

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // ===== Shared Ledgers =====
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Shared Ledgers action
              },
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text("Shared Ledgers"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            // ===== Middle Small Button =====
            FloatingActionButton(
              mini: true,
              backgroundColor: Colors.grey.shade800,
              onPressed: () {
                // TODO: Import / Upload action
              },
              child: const Icon(Icons.upload, size: 18),
            ),

            // ===== Create Party =====
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // TODO: Navigate to Create Party screen
            //   },
            //   icon: const Icon(Icons.add, size: 18),
            //   label: const Text("Create Party"),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.deepPurple,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(30),
            //     ),
            //   ),
            // ),
            // ===== Create Party =====
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateNewPartyScreen(
                      primary: Colors.deepPurple,
                    ),
                  ),
                );

                // ✅ AFTER CREATE PARTY → REFRESH LIST
                if (result != null) {
                  await fetchParties();
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Create Party"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

          ],
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

  // ================= CHIP =================
  Widget _chip(String text, {IconData? icon}) {
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
            const SizedBox(width: 4),
            Icon(icon, size: 16),
          ]
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF3F1FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.deepPurple : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 16, color: Colors.deepPurple),
            ],
          ],
        ),
      ),
    );
  }

  void _openSortFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // HEADER
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Sort & Filter",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // SORT BY
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Sort By",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  _sortTile("Party name - A to Z", "az", modalSetState),
                  _sortTile("Party name - Z to A", "za", modalSetState),
                  _sortTile("Amount - High to Low", "high", modalSetState),
                  _sortTile("Amount - Low to High", "low", modalSetState),

                  const SizedBox(height: 16),

                  // FILTER BY
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Filter By",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  Wrap(
                    spacing: 8,
                    children: [
                      _filterOption("Customer", "customer", modalSetState),
                      _filterOption("Supplier", "supplier", modalSetState),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // APPLY BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        _applySortAndFilter();
                        Navigator.pop(context);
                      },
                      child: const Text("Apply", style: TextStyle(fontSize: 16)),
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


  void _applySortAndFilter() {
    List temp = List.from(parties);

    if (selectedPartyType != null) {
      temp = temp
          .where((p) => p['party_type'] == selectedPartyType)
          .toList();
    }

    switch (selectedSort) {
      case 'az':
        temp.sort((a, b) => a['party_name'].compareTo(b['party_name']));
        break;
      case 'za':
        temp.sort((a, b) => b['party_name'].compareTo(a['party_name']));
        break;
      case 'high':
        temp.sort(
              (a, b) => (b['opening_balance'] as num)
              .compareTo(a['opening_balance']),
        );
        break;
      case 'low':
        temp.sort(
              (a, b) => (a['opening_balance'] as num)
              .compareTo(b['opening_balance']),
        );
        break;
    }

    setState(() {
      filteredParties = temp;
      hasSortOrFilter = selectedSort != null || selectedPartyType != null;
    });
  }



  Widget _sortTile(
      String label,
      String value,
      void Function(void Function()) modalSetState,
      ) {
    return ListTile(
      leading: const Icon(Icons.sort, color: Colors.deepPurple),
      title: Text(label),
      trailing: Radio<String>(
        value: value,
        groupValue: selectedSort,
        onChanged: (val) {
          modalSetState(() {
            selectedSort = val;
          });
        },
      ),
      onTap: () {
        modalSetState(() {
          selectedSort = value;
        });
      },
    );
  }


  Widget _filterOption(
      String label,
      String value,
      void Function(void Function()) modalSetState,
      ) {
    final bool isSelected = selectedPartyType == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFF3F1FF),
      onSelected: (_) {
        modalSetState(() {
          selectedPartyType = isSelected ? null : value;
        });
      },
    );
  }







}
