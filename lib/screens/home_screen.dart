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
import 'phone_login_screen.dart';
import 'calculator_screen.dart';
import 'invite_earn_screen.dart';
import 'package:flutter_project/widgets/app_background.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'invoice_preview_screen.dart';
import 'create_purchase_screen.dart'; // ✅ ADD THIS



const String baseUrl = 'http://192.168.1.11:8000/api';

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

  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasMore = true;
  ScrollController scrollController = ScrollController();

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


  // Future<void> fetchHomeTransactions() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token') ?? "";
  //
  //     String url = "$baseUrl/dashboard/transactions";
  //
  //     if (fromDate != null && toDate != null) {
  //       url +=
  //       "?from=${fromDate!.toIso8601String()}&to=${toDate!.toIso8601String()}";
  //     }
  //
  //     final res = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Accept": "application/json",
  //       },
  //     );
  //
  //     final decoded = jsonDecode(res.body);
  //
  //     setState(() {
  //       transactions = decoded['transactions'] ?? [];
  //       loadingTx = false;
  //     });
  //   } catch (e) {
  //     loadingTx = false;
  //   }
  // }

  Future<void> fetchHomeTransactions({bool loadMore = false}) async {
    if (isLoadingMore) return;

    if (loadMore) {
      isLoadingMore = true;
      currentPage++;
    } else {
      currentPage = 1;
      transactions.clear();
      loadingTx = true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      String url = "$baseUrl/dashboard/transactions?page=$currentPage";

      if (fromDate != null && toDate != null) {
        url +=
        "&from=${fromDate!.toIso8601String()}&to=${toDate!.toIso8601String()}";
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final decoded = jsonDecode(res.body);

      List newData = decoded['data'] ?? [];

      setState(() {
        transactions.addAll(newData);
        hasMore = currentPage < (decoded['last_page'] ?? 1);
        loadingTx = false;
        isLoadingMore = false;
      });
    } catch (e) {
      isLoadingMore = false;
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    try {
      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
    } catch (e) {
      debugPrint("Logout API error: $e");
    }

    await prefs.remove('token');

    await prefs.clear();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      PhoneLoginScreen.routeName,
          (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (ok == true) {
      _logout();
    }
  }

  Future<void> _shareOnWhatsApp(Map tx) async {
    try {
      final String name = tx['party_name'] ?? '';
      final String invoiceNo = tx['number'] ?? '';
      final String amount = tx['balance_amount']?.toString() ?? '0';

      // ✅ SAFE ID FIX
      final int? invoiceId = tx['invoice_id'] is int
          ? tx['invoice_id']
          : int.tryParse(tx['invoice_id']?.toString() ?? '');

      if (invoiceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid invoice ID")),
        );
        return;
      }

      final String? link = await _getPaymentLink(invoiceId);

      if (link == null || link.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment link not available")),
        );
        return;
      }

      final String message = Uri.encodeComponent(
          "Hello $name,\n"
              "Invoice #$invoiceNo\n"
              "Amount Due: ₹$amount\n\n"
              "Pay here:\n$link\n\n"
              "Thank you!");

      final Uri url = Uri.parse("https://wa.me/?text=$message");

      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  Future<String?> _getPaymentLink(int invoiceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final res = await http.get(
        Uri.parse("$baseUrl/invoices/$invoiceId"), // ✅ adjust if needed
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      return data['invoice']?['payment_link']; // ✅ same as preview screen
    } catch (e) {
      return null;
    }
  }


  Future<void> _shareReceiptOnWhatsApp(Map tx) async {
    try {
      final String name = tx['party_name'] ?? '';
      final String receiptNo = tx['number'] ?? '';
      final String amount = tx['amount']?.toString() ?? '0';

      final String message = Uri.encodeComponent(
          "Hello $name,\n\n"
              "Payment Received ✔\n"
              "Receipt #$receiptNo\n"
              "Amount: ₹$amount\n\n"
              "Thank you!"
      );

      final Uri url = Uri.parse("https://wa.me/?text=$message");

      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _openAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= HEADER =================
                Row(
                  children: [
                    const Text(
                      "Sales Transactions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                // ================= SALES =================
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [

                    _menuItem(Icons.receipt_long, "Bill / Invoice", () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                      );
                    }),

                    _menuItem(Icons.payments, "Received\nPayment", () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecordPaymentScreen()),
                      );
                    }),

                    _menuItem(Icons.assignment_return, "Sales Return", () {}),

                    _menuItem(Icons.note_add, "Credit Note", () {}),

                    _menuItem(Icons.description, "Quotation/\nEstimate", () {}),

                    _menuItem(Icons.local_shipping, "Delivery\nChallan", () {}),

                    _menuItem(Icons.request_quote, "Proforma\nInvoice", () {}),

                    _menuItem(Icons.calendar_today, "Automated\nBill", () {}),
                  ],
                ),

                const SizedBox(height: 12),

                // ================= COUNTER =================
                _menuItem(Icons.flash_on, "Counter", () {}),

                const SizedBox(height: 16),
                const Divider(),

                // ================= PURCHASE =================
                const SizedBox(height: 10),
                const Text(
                  "Purchase Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [

                    _menuItem(Icons.shopping_cart, "Purchase", () {
                      Navigator.pop(context); // close bottom sheet

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatePurchaseScreen(),
                        ),
                      );
                    }),

                    _menuItem(Icons.currency_rupee, "Payment Out", () {}),

                    _menuItem(Icons.undo, "Purchase\nReturn", () {}),

                    _menuItem(Icons.note, "Debit Note", () {}),

                    _menuItem(Icons.list_alt, "Purchase\nOrder", () {}),

                    _menuItem(Icons.qr_code_scanner, "Scan &\nRecord Bills", () {}),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),

                // ================= OTHER =================
                const SizedBox(height: 10),
                const Text(
                  "Other Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                _menuItem(Icons.account_balance_wallet, "Expense", () {}),

                const SizedBox(height: 20),

                // ================= BOTTOM CLOSE =================
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

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

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (hasMore && !isLoadingMore) {
          fetchHomeTransactions(loadMore: true);
        }
      }
    });
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
        title:
        Row(
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
            // // Icon(Icons.calculate_outlined, color: primary, size: 26),
            // GestureDetector(
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const CalculatorScreen()),
            //     );
            //   },
            //   child: Icon(Icons.calculate_outlined, color: primary, size: 26),
            // ),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalculatorScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBFF), // light purple bg
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: Color(0xFF4C3FF0), // primary purple
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InviteEarnScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0), // light orange bg
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.desktop_windows_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 12),


            GestureDetector(
              onTap: _confirmLogout,
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),
          ],
        ),
      ),

      // ===============================
// BODY CONTENT
// ===============================


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
                      :
                  // Column(
                  //   children: transactions
                  //       .map((tx) => _buildTransactionCard(tx))
                  //       .toList(),
                  // ),
                  SizedBox(
                    height: 400, // or adjust
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: transactions.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < transactions.length) {
                          return _buildTransactionCard(transactions[index]);
                        } else {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                    ),
                  )
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
                          () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecordPaymentScreen(),
                          ),
                        );

                        // 🔥 MAIN FIX (ADD THIS)
                        if (result == true) {
                          fetchHomeTransactions();   // refresh list
                          fetchDashboardTotals();    // optional (update totals also)
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: const BoxDecoration(
                    //     color: Colors.green,
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child:
                    //   const Icon(Icons.add, color: Colors.white, size: 28),
                    // ),

                    GestureDetector(
                      onTap: _openAddMenu, // ✅ IMPORTANT
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
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
                // const SizedBox(height: 10),
                // if (isInvoice)
                //   Row(
                //     children: const [
                //       Text("₹ Record Manually",
                //           style: TextStyle(color: Colors.blue)),
                //       SizedBox(width: 6),
                //       Icon(Icons.arrow_forward_ios,
                //           size: 14, color: Colors.blue),
                //     ],
                //   ),

                const SizedBox(height: 10),

// ================= ACTION BUTTONS =================
                if (!isInvoice)
                  GestureDetector(
                    onTap: () {
                      _shareReceiptOnWhatsApp(tx);
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.reply, size: 16, color: Colors.deepPurple),
                        SizedBox(width: 6),
                        Text(
                          "Send Receipt",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isInvoice)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 👉 Record Manually
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecordPaymentScreen(),
                            ),
                          );

                          if (result == true) {
                            fetchHomeTransactions();
                            fetchDashboardTotals();
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "₹ Record Manually",
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.deepPurple),
                          ],
                        ),
                      ),

                      // 👉 WhatsApp Share Button
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            _shareOnWhatsApp(tx);
                          },
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                FaIcon(
                                  FontAwesomeIcons.whatsapp, // ✅ FIXED
                                  size: 14,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "Share Payment Link",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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


