import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_project/widgets/app_background.dart';


const String baseUrl = "http://127.0.0.1:8000/api";
// const String baseUrl = "http://10.0.2.2:8000/api";


// class CashBankDetailsScreen extends StatefulWidget {
//   const CashBankDetailsScreen({super.key});
//
//   @override
//   State<CashBankDetailsScreen> createState() =>
//       _CashBankDetailsScreenState();
// }

class CashBankDetailsScreen extends StatefulWidget {
  final String title;
  final double? currentBalance;
  final String type; // cash | bank | all

  const CashBankDetailsScreen({
    super.key,
    required this.title,
    required this.type,
    this.currentBalance,
  });

  @override
  State<CashBankDetailsScreen> createState() =>
      _CashBankDetailsScreenState();
}


class _CashBankDetailsScreenState extends State<CashBankDetailsScreen> {
  bool loading = true;
  List transactions = [];

  String selectedRange = 'last_7_days';
  String rangeLabel = 'Last 7 days';
  String rangeText = '';

  DateTime? customStart;
  DateTime? customEnd;

  double runningBalance = 0;



  @override
  void initState() {
    super.initState();

    final ranges = _getLocalRanges();
    rangeText = ranges[selectedRange]!; // ✅ dynamic default

    fetchDetails();
  }


  Future<void> fetchDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    // String url = "$baseUrl/cash-bank-details?range=$selectedRange";
    String url =
        "$baseUrl/cash-bank-details?range=$selectedRange&type=${widget.type}";


    if (selectedRange == 'custom' &&
        customStart != null &&
        customEnd != null) {
      url +=
      "&start=${customStart!.toIso8601String()}&end=${customEnd!.toIso8601String()}";
    }

    final res = await http.get(
      Uri.parse(url),

      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    // setState(() {
    //   transactions = decoded['data'] ?? [];
    //   loading = false;
    // });

    setState(() {
      transactions = decoded['data'] ?? [];

      // NEWEST → OLDEST
      transactions.sort((a, b) {
        final da = DateTime.parse(a['date'].split('-').reversed.join());
        final db = DateTime.parse(b['date'].split('-').reversed.join());
        return db.compareTo(da);
      });

      double balance;

      if (widget.type == 'cash') {
        balance = widget.currentBalance ?? 0;
      } else {
        balance = (decoded['current_balance'] ?? 0).toDouble();
      }

      for (var t in transactions) {
        t['running_balance'] = balance;
        balance -= (t['received_amount'] as num).toDouble();
      }

      loading = false;
    });




  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: const [
          Icon(Icons.picture_as_pdf, color: Colors.red),
          SizedBox(width: 12),
          Icon(Icons.table_chart, color: Colors.green),
          SizedBox(width: 12),
        ],
      ),


        body: AppBackground(
          child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          // ================= CURRENT BALANCE (ONLY FOR CASH) =================
          if (widget.type == 'cash' && widget.currentBalance != null) ...[
            const SizedBox(height: 16),
            Text(
              "Current Balance",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              "₹ ${widget.currentBalance!.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],


          // ================= DATE FILTER =================
          Container(
            color: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.grey),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rangeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rangeText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const Spacer(),
                GestureDetector(
                  onTap: _openDateRangeSheet,
                  child: const Text(
                    "CHANGE",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 12),

          // ================= FILTER CHIPS =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip("All Transactions"),
                const SizedBox(width: 12),
                _filterChip("All Staff"),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ================= TRANSACTION LIST =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                // final t = transactions[transactions.length - 1 - index];
                final t = transactions[index];


                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ================= LEFT SIDE =================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Date | Invoice ID
                            Text(
                              "${t['date']} | ${t['invoice_id']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Invoice
                            const Text(
                              "Invoice",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Party name
                            Text(
                              t['party_name'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // ================= RIGHT SIDE =================
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [

                          // Received Amount (ONLY ONCE)
                          Text(
                            "₹ ${t['received_amount']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Balance
                          Text(
                            "Balance: ₹ ${t['running_balance'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );


              },
            ),
          ),

          // ================= ADJUST BALANCE BUTTON =================
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SizedBox(
              height: 44,
              width: 220,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Adjust Balance",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }

  Map<String, String> _getLocalRanges() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String f(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')} "
            "${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][d.month - 1]} "
            "${d.year}";

    // 🔹 Quarter helpers
    int quarter = ((today.month - 1) ~/ 3) + 1;
    DateTime qStart(int q, int y) => DateTime(y, (q - 1) * 3 + 1, 1);
    DateTime qEnd(int q, int y) =>
        DateTime(y, q * 3 + 1, 0);

    // 🔹 FY helpers (India: Apr–Mar)
    DateTime fyStart =
    today.month >= 4 ? DateTime(today.year, 4, 1) : DateTime(today.year - 1, 4, 1);
    DateTime fyEnd =
    today.month >= 4 ? DateTime(today.year + 1, 3, 31) : DateTime(today.year, 3, 31);

    return {
      'today': "${f(today)} - ${f(today)}",

      'yesterday':
      "${f(today.subtract(const Duration(days: 1)))} - ${f(today.subtract(const Duration(days: 1)))}",

      'this_week':
      "${f(today.subtract(Duration(days: today.weekday - 1)))} - ${f(today.add(Duration(days: 7 - today.weekday)))}",

      'last_week':
      "${f(today.subtract(Duration(days: 7 + today.weekday - 1)))} - ${f(today.subtract(Duration(days: today.weekday)))}",

      'last_7_days':
      "${f(today.subtract(const Duration(days: 6)))} - ${f(today)}",

      'this_month':
      "${f(DateTime(today.year, today.month, 1))} - ${f(DateTime(today.year, today.month + 1, 0))}",

      'last_month':
      "${f(DateTime(today.year, today.month - 1, 1))} - ${f(DateTime(today.year, today.month, 0))}",

      // ✅ THIS QUARTER
      'this_quarter':
      "${f(qStart(quarter, today.year))} - ${f(qEnd(quarter, today.year))}",

      // ✅ LAST QUARTER
      'last_quarter': (() {
        int q = quarter == 1 ? 4 : quarter - 1;
        int y = quarter == 1 ? today.year - 1 : today.year;
        return "${f(qStart(q, y))} - ${f(qEnd(q, y))}";
      })(),

      // ✅ CURRENT FY
      'current_fy': "${f(fyStart)} - ${f(fyEnd)}",

      // ✅ PREVIOUS FY
      'previous_fy':
      "${f(DateTime(fyStart.year - 1, 4, 1))} - ${f(DateTime(fyEnd.year - 1, 3, 31))}",

      // ✅ LAST 365 DAYS
      'last_365_days':
      "${f(today.subtract(const Duration(days: 364)))} - ${f(today)}",
    };
  }



  void _openDateRangeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                _sheetHeader(),

                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    children: [
                      _rangeTile("Today", "today"),
                      _rangeTile("Yesterday", "yesterday"),
                      _rangeTile("This week", "this_week"),
                      _rangeTile("Last week", "last_week"),
                      _rangeTile("Last 7 days", "last_7_days"),
                      _rangeTile("This month", "this_month"),
                      _rangeTile("Last month", "last_month"),
                      _rangeTile("This quarter", "this_quarter"),
                      _rangeTile("Last quarter", "last_quarter"),
                      _rangeTile("Current fiscal year", "current_fy"),
                      _rangeTile("Previous fiscal year", "previous_fy"),
                      _rangeTile("Last 365 days", "last_365_days"),
                      _rangeTile("Custom", "custom"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      },
    );
  }

  Widget _rangeTile(String label, String value) {
    final ranges = _getLocalRanges();

    return ListTile(
      onTap: () async {
        if (value == 'custom') {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked == null) return;

          customStart = picked.start;
          customEnd = picked.end;

          rangeText =
          "${picked.start.day.toString().padLeft(2, '0')} "
              "${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][picked.start.month - 1]} "
              "${picked.start.year} - "
              "${picked.end.day.toString().padLeft(2, '0')} "
              "${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][picked.end.month - 1]} "
              "${picked.end.year}";
        }

        setState(() {
          selectedRange = value;
          rangeLabel = label;
          rangeText = value == 'custom'
              ? rangeText
              : (ranges[value] ?? rangeText); // ✅ SAFE
        });

        Navigator.pop(context);
        fetchDetails();
      },

      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),

      // ✅ SHOW DATE BELOW (LIKE SCREENSHOT 2)
      subtitle: value != 'custom' && ranges.containsKey(value)
          ? Text(
        ranges[value]!,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      )
          : null,

      trailing: Radio<String>(
        value: value,
        groupValue: selectedRange,
        onChanged: (_) {},
      ),
    );
  }



  Widget _sheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          const Text(
            "Select Date Range",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

}



// ================= FILTER CHIP WIDGET =================
Widget _filterChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.keyboard_arrow_down, size: 18),
      ],
    ),
  );
}
