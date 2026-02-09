import 'package:flutter/material.dart';
import 'create_invoice_screen.dart'; // ⬅️ add this import
import 'record_payment_screen.dart'; // ⬅️ add this import
import 'parties_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'items_screen.dart';
import 'stock_summary_screen.dart';
import 'sales_summary_screen.dart';
import 'cash_bank_screen.dart';
import 'reports_screen.dart';
import 'for_you_screen.dart';
import 'more_screen.dart';
import 'package:flutter_project/widgets/app_background.dart';



const String baseUrl = "http://127.0.0.1:8000/api";

// const String baseUrl = "http://10.0.2.2:8000/api";




class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int navIndex = 0;

  final Color primary = const Color(0xFF4C3FF0);

  // 🔴 ADD BELOW
  double toCollect = 0.0;
  double toPay = 0.0;

  double thisWeekSales = 0.0;   // ✅ ADD THIS

  List transactions = [];
  bool loadingTx = true;

  DateTime? fromDate;
  DateTime? toDate;

  String selectedRangeLabel = "LAST 365 DAYS";

  String businessName = "Loading...";





  // ===============================
// DATE HELPERS (ADD HERE)
// ===============================

  String _fmt(DateTime d) {
    const m = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return "${d.day} ${m[d.month - 1]} ${d.year}";
  }

  Map<String, Map<String, DateTime>> _dateRanges() {
    final now = DateTime.now();

    DateTime startOfWeek(DateTime d) =>
        d.subtract(Duration(days: d.weekday - 1));
    DateTime endOfWeek(DateTime d) =>
        startOfWeek(d).add(const Duration(days: 6));

    return {
      "Today": {
        "from": DateTime(now.year, now.month, now.day),
        "to": DateTime(now.year, now.month, now.day),
      },
      "Yesterday": {
        "from": DateTime(now.year, now.month, now.day - 1),
        "to": DateTime(now.year, now.month, now.day - 1),
      },
      "This week": {
        "from": startOfWeek(now),
        "to": endOfWeek(now),
      },
      "Last Week": {
        "from": startOfWeek(now.subtract(const Duration(days: 7))),
        "to": endOfWeek(now.subtract(const Duration(days: 7))),
      },
      "Last 7 days": {
        "from": DateTime(now.year, now.month, now.day - 6),
        "to": now,
      },
      "This month": {
        "from": DateTime(now.year, now.month, 1),
        "to": DateTime(now.year, now.month + 1, 0),
      },
      "Last Month": {
        "from": DateTime(now.year, now.month - 1, 1),
        "to": DateTime(now.year, now.month, 0),
      },
      "This quarter": {
        "from": DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1),
        "to": DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 4, 0),
      },
      "Last quarter": {
        "from": DateTime(now.year, ((now.month - 1) ~/ 3) * 3 - 2, 1),
        "to": DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 0),
      },
      "Current fiscal year": {
        "from": DateTime(now.month >= 4 ? now.year : now.year - 1, 4, 1),
        "to": DateTime(now.month >= 4 ? now.year + 1 : now.year, 3, 31),
      },
      "Previous fiscal year": {
        "from": DateTime(now.month >= 4 ? now.year - 1 : now.year - 2, 4, 1),
        "to": DateTime(now.month >= 4 ? now.year : now.year - 1, 3, 31),
      },
      "Last 365 Days": {
        "from": now.subtract(const Duration(days: 364)),
        "to": now,
      },
    };
  }






  bool loadingTotals = true;
  

  Future<void> fetchBusinessInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final res = await http.get(
        Uri.parse("$baseUrl/business-info"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final decoded = jsonDecode(res.body);

      setState(() {
        businessName = decoded['data']['business_name'] ?? "My Business";
      });
    } catch (e) {
      businessName = "My Business";
    }
  }


  Future<void> fetchHomeTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      String url = "$baseUrl/dashboard/transactions";

      if (fromDate != null && toDate != null) {
        url +=
        "?from=${fromDate!.toIso8601String()}&to=${toDate!.toIso8601String()}";
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
        transactions = decoded['transactions'] ?? [];
        loadingTx = false;
      });
    } catch (e) {
      loadingTx = false;
    }
  }

  Future<void> _openCustomRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
      helpText: "SELECT RANGE",
      confirmText: "OK",
      cancelText: "CANCEL",
    );

    if (picked != null) {
      final label =
          "${_fmt(picked.start)} - ${_fmt(picked.end)}";

      _applyRange(
        picked.start,
        picked.end,
        label.toUpperCase(),
      );
    }
  }




  Future<void> fetchDashboardTotals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final res = await http.get(
        Uri.parse("$baseUrl/dashboard/totals"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final decoded = jsonDecode(res.body);

      setState(() {
        toCollect = (decoded['data']['to_collect'] ?? 0).toDouble();
        toPay = (decoded['data']['to_pay'] ?? 0).toDouble();
        thisWeekSales = (decoded['data']['this_week_sales'] ?? 0).toDouble(); // ✅ ADD
        loadingTotals = false;
      });
    } catch (e) {
      loadingTotals = false;
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
  //   }else if (index == 3) {
  //     // ✅ FOR YOU
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const ForYouScreen()),
  //     );
  //   }else if (index == 4) {
  //     // ✅ MORE
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const MoreScreen()),
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
          (route) => false, // ⛔ clears stack (IMPORTANT)
    );
  }






  @override
  void initState() {
    super.initState();
    fetchDashboardTotals(); // 🔥 CALL HERE
    fetchHomeTransactions(); // ✅ ADD THIS
    fetchBusinessInfo(); // ✅ ADD THIS
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===============================
      // APP BAR
      // ===============================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),

            const Icon(Icons.keyboard_arrow_down, color: Colors.black),
            const Spacer(),
            Icon(Icons.calculate_outlined, color: primary, size: 26),
            const SizedBox(width: 10),
            Icon(Icons.card_giftcard, color: Colors.orange, size: 26),
            const SizedBox(width: 10),
            Icon(Icons.document_scanner_outlined, color: Colors.red, size: 26),
            const SizedBox(width: 12),
          ],
        ),
      ),

      // ===============================
// BODY CONTENT
// ===============================
//       body: Stack(
//         children: [
//           // 🍓 + 🔴 BACKGROUND (single painter)
//           Positioned.fill(
//             child: CustomPaint(
//               painter: StrawberryPatternPainter(),
//             ),
//           ),
//
//           // 🍓 2️⃣ YOUR EXISTING CONTENT (UNCHANGED)
//           SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Banner (NORMAL — no CustomPaint here)
//                 Container(
//                   height: 130,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0066CC),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       const Expanded(
//                         child: Text(
//                           "Now generate GST e-Invoice & e-Way Bills on Mobile easily!\n\nTRY NOW ➜",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       Image.asset(
//                         "assets/invoice_sample.png",
//                         height: 90,
//                       ),
//                     ],
//                   ),
//                 ),
//             const SizedBox(height: 16),
//
//             Row(
//               children: [
//                 _buildAmountCard(
//                   loadingTotals ? "₹ --" : "₹ ${toCollect.toStringAsFixed(0)}",
//                   "To Collect",
//                   Colors.green,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const PartiesScreen(initialFilter: 'receive'),
//                       ),
//                     );
//                   },
//                 ),
//                 const SizedBox(width: 12),
//                 _buildAmountCard(
//                   loadingTotals ? "₹ --" : "₹ ${toPay.toStringAsFixed(0)}",
//                   "To Pay",
//                   Colors.red,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const PartiesScreen(initialFilter: 'pay'),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//
//
//
//             const SizedBox(height: 12),
//
//             // Row: Stock Value + Week Sale
//             Row(
//               children: [
//                 // _buildSimpleCard("Stock Value", "Value of Items"),
//                 _buildSimpleCard(
//                   "Stock Value",
//                   "Value of Items",
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const StockSummaryScreen(),
//                       ),
//                     );
//                   },
//                 ),
//
//                 const SizedBox(width: 12),
//
//                 _buildSimpleCard(
//                   loadingTotals
//                       ? "₹ --"
//                       : "₹ ${thisWeekSales.toStringAsFixed(0)}",
//                   "This week's sale",
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const SalesSummaryScreen(),
//                       ),
//                     );
//                   },
//                 ),
//
//
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // Row: Total Balance + Reports
//             Row(
//               children: [
//                 _buildSimpleCard(
//                   "Total Balance",
//                   "Cash + Bank Balance",
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const CashBankScreen(),
//                       ),
//                     );
//                   },
//                 ),
//
//                 const SizedBox(width: 12),
//                 _buildSimpleCard(
//                   "Reports",
//                   "Sales, Party, GST...",
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const ReportsScreen()),
//                     );
//                   },
//                 ),
//
//               ],
//             ),
//
//             const SizedBox(height: 24),
//
//             // Subscription
//             ListTile(
//               minLeadingWidth: 0,
//               contentPadding: EdgeInsets.zero,
//               leading: const Icon(Icons.workspace_premium, color: Colors.orange),
//               title: const Text(
//                 "myBillBook Subscription Plan",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//             ),
//
//             const SizedBox(height: 10),
//
//             const Text(
//               "Transactions",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 4),
//
//             Row(
//               children: [
//                 const Spacer(),
//                 GestureDetector(
//                   onTap: _openDateFilterSheet,
//                   child: Text(
//                     selectedRangeLabel,
//                     style: const TextStyle(
//                       color: Colors.blue,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//
//             const SizedBox(height: 12),
//
//             // Transaction Card
//
//             loadingTx
//                 ? const Center(child: CircularProgressIndicator())
//                 : transactions.isEmpty
//                 ? const Center(
//               child: Text(
//                 "No transactions yet",
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             )
//                 : Column(
//               children: transactions.map((tx) {
//                 return _buildTransactionCard(tx);
//               }).toList(),
//             ),
//
//           ],
//         ),
//       ),
//
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 20, // ✅ closer to bottom navigation
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _roundAction(
//                       "Received Payment",
//                       Colors.black,
//                           () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const RecordPaymentScreen(),
//                           ),
//                         );
//                       },
//                     ),
//
//                     const SizedBox(width: 12), // ✅ small gap
//
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: const BoxDecoration(
//                         color: Colors.green,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             blurRadius: 10,
//                             color: Colors.black26,
//                           ),
//                         ],
//                       ),
//                       child: const Icon(Icons.add, color: Colors.white, size: 28),
//                     ),
//
//                     const SizedBox(width: 12), // ✅ small gap
//
//                     _roundAction(
//                       "+ Bill / Invoice",
//                       primary,
//                           () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const CreateInvoiceScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//           ],
//       ),

      body: AppBackground(
        child: Stack(
          children: [
            // 🔝 MAIN SCROLL CONTENT
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Now generate GST e-Invoice & e-Way Bills on Mobile easily!\n\nTRY NOW ➜",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Image.asset(
                          "assets/invoice_sample.png",
                          height: 90,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildAmountCard(
                        loadingTotals ? "₹ --" : "₹ ${toCollect.toStringAsFixed(0)}",
                        "To Collect",
                        Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const PartiesScreen(initialFilter: 'receive'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildAmountCard(
                        loadingTotals ? "₹ --" : "₹ ${toPay.toStringAsFixed(0)}",
                        "To Pay",
                        Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const PartiesScreen(initialFilter: 'pay'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildSimpleCard(
                        "Stock Value",
                        "Value of Items",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StockSummaryScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildSimpleCard(
                        loadingTotals
                            ? "₹ --"
                            : "₹ ${thisWeekSales.toStringAsFixed(0)}",
                        "This week's sale",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SalesSummaryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildSimpleCard(
                        "Total Balance",
                        "Cash + Bank Balance",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CashBankScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildSimpleCard(
                        "Reports",
                        "Sales, Party, GST...",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  loadingTx
                      ? const Center(child: CircularProgressIndicator())
                      : transactions.isEmpty
                      ? const Center(
                    child: Text(
                      "No transactions yet",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : Column(
                    children: transactions
                        .map((tx) => _buildTransactionCard(tx))
                        .toList(),
                  ),
                ],
              ),
            ),

            // 🔻 FIXED BOTTOM ACTION BUTTONS
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _roundAction(
                      "Received Payment",
                      Colors.black,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecordPaymentScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child:
                      const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    _roundAction(
                      "+ Bill / Invoice",
                      primary,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateInvoiceScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),





      // ===============================
      // BOTTOM NAVIGATION
      // ===============================


      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: navIndex,
      //   onTap: (index) {
      //     setState(() => navIndex = index);
      //
      //     if (index == 1) {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (_) => const PartiesScreen()),
      //       );
      //     }
      //
      //     if (index == 2) {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (_) => const ItemsScreen()),
      //       );
      //     }
      //   },
      //   selectedItemColor: primary,
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
      //     BottomNavigationBarItem(icon: Icon(Icons.people), label: "Parties"),
      //     BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Items"),
      //     BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "For You"),
      //     BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
      //   ],
      // ),


    bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navIndex,
        selectedItemColor: primary,
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

  // ===============================
  //  Widgets
  // ===============================


  Widget _buildAmountCard(
      String amount,
      String label,
      Color color, {
        VoidCallback? onTap,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          // decoration: BoxDecoration(
          //   color: color.withOpacity(0.1),
          //   borderRadius: BorderRadius.circular(12),
          // ),
          decoration: BoxDecoration(
            color: Colors.white, // ⛔ blocks 🍓 completely
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(color: color)),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),

        ),
      ),
    );
  }


  // Widget _buildSimpleCard(String title, String subtitle) {
  Widget _buildSimpleCard(
      String title,
      String subtitle, {
        VoidCallback? onTap,
      }) {

    return Expanded(
        child: GestureDetector(
          onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, // ⛔ solid background

          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black45,
            ),
          ],
        ),

      ),
        ),
    );
  }


  String formatDate(String iso) {
    final d = DateTime.parse(iso);
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return "${d.day} ${months[d.month - 1]}";
  }

  String dueText(String? dueDate) {
    if (dueDate == null) return "";

    final due = DateTime.parse(dueDate);
    final now = DateTime.now();
    final diff = due.difference(now).inDays;

    if (diff > 0) return "Due in $diff day(s)";
    if (diff == 0) return "Due today";
    return "Overdue by ${diff.abs()} day(s)";
  }


  Widget _buildTransactionCard(Map tx) {
    final bool isInvoice = tx['type'] == 'invoice';

    final String title = tx['party_name'];
    final String subTitle = isInvoice
        ? "Invoice #${tx['number']}"
        : "Received Payment #${tx['number']}";

    final String dateLine = isInvoice
        ? "${formatDate(tx['date'])} • ${dueText(tx['due_date'])}"
        : formatDate(tx['date']);

    final double grandTotal =
        double.tryParse(tx['grand_total']?.toString() ?? '0') ?? 0;

    final double balance =
        double.tryParse(tx['balance_amount']?.toString() ?? '0') ?? 0;

    final double rightAmount = isInvoice
        ? grandTotal
        : double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;

    final String status = isInvoice
        ? (tx['status'] ?? 'unpaid').toString().toLowerCase()
        : 'received';

    // ---------------- STATUS LOGIC ----------------
    Color badgeColor;
    String badgeText;
    bool showBalance = false;

    if (!isInvoice) {
      badgeColor = Colors.green.shade100;
      badgeText = "RECEIVED";
    } else if (status == 'paid') {
      badgeColor = Colors.green.shade100;
      badgeText = "PAID";
    } else if (status == 'partial') {
      badgeColor = Colors.orange.shade100;
      badgeText = "PARTIAL";
      showBalance = balance != grandTotal;
    } else {
      badgeColor = Colors.red.shade100;
      badgeText = "UNPAID";
      showBalance = balance != grandTotal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(subTitle, style: const TextStyle(color: Colors.blue)),
                const SizedBox(height: 2),
                Text(dateLine, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                if (isInvoice)
                  Row(
                    children: const [
                      Text("₹ Record Manually",
                          style: TextStyle(color: Colors.blue)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.blue),
                    ],
                  ),
              ],
            ),
          ),

          // RIGHT SIDE (CENTERED)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Text(
                "₹ ${rightAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (showBalance) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "₹ ${balance.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  void _openDateFilterSheet() {
    final ranges = _dateRanges();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text(
                          "Select Date",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  ...ranges.entries.map((e) {
                    final label = e.key;
                    final from = e.value["from"]!;
                    final to = e.value["to"]!;

                    final rangeText = "${_fmt(from)} - ${_fmt(to)}";
                    final isSelected =
                        selectedRangeLabel == label.toUpperCase();

                    return ListTile(
                      title: Text(label, style: const TextStyle(fontSize: 16)),
                      subtitle: Text(
                        rangeText,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? primary : Colors.grey,
                      ),
                      // onTap: () {
                      //   // ✅ update bottom sheet UI immediately
                      //   setModalState(() {
                      //     selectedRangeLabel = label.toUpperCase();
                      //   });
                      //
                      //   // ✅ update main screen + fetch data
                      //   _applyRange(from, to, label.toUpperCase());
                      // },

                      onTap: () {
                        // update bottom sheet UI instantly
                        setModalState(() {
                          selectedRangeLabel = label.toUpperCase();
                        });

                        // apply filter + fetch data
                        _applyRange(from, to, label.toUpperCase());

                        // ✅ AUTO CLOSE SHEET (THIS WAS MISSING)
                        Navigator.pop(context);
                      },


                    );
                  }).toList(),

                  ListTile(
                    title: const Text("Custom",
                        style: TextStyle(fontSize: 16)),
                    trailing: const Icon(Icons.radio_button_unchecked),
                    onTap: () async {
                      Navigator.pop(context);
                      _openCustomRangePicker();
                    },
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }






  Widget _dateOption({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }

  void _applyRange(DateTime from, DateTime to, String label) {
    setState(() {
      fromDate = from;
      toDate = to;
      selectedRangeLabel = label;
      loadingTx = true;
    });

    fetchHomeTransactions();
  }




  Widget _roundAction(String text, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _roundPlus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}


// class StrawberryPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     // 🍓 1️⃣ Soft strawberry-tinted background
//     final bgPaint = Paint()
//       ..color = const Color(0xFFFFF3F3); // warmer & richer than FFF5F5
//
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       bgPaint,
//     );
//
//     // 🍓 2️⃣ Strawberry watermark pattern
//     const double gap = 64; // more breathing space
//     final textPainter = TextPainter(
//       textDirection: TextDirection.ltr,
//     );
//
//     for (double x = -20; x < size.width + gap; x += gap) {
//       for (double y = -20; y < size.height + gap; y += gap) {
//         textPainter.text = const TextSpan(
//           text: '🍓',
//           style: TextStyle(
//             fontSize: 16,                 // 👈 more visible
//             color: Color(0x33E53935),     // 👈 soft strawberry red
//           ),
//         );
//
//         textPainter.layout();
//
//         // Slight diagonal offset for premium look
//         textPainter.paint(
//           canvas,
//           Offset(
//             x + (y % (gap * 2) == 0 ? 10 : 0),
//             y,
//           ),
//         );
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }


