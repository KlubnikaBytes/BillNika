import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_project/widgets/app_background.dart';

const String baseUrl = "http://127.0.0.1:8000/api";
// const String baseUrl = "http://10.0.2.2:8000/api";






class SalesSummaryScreen extends StatefulWidget {
  const SalesSummaryScreen({super.key});

  @override
  State<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}
class _SalesSummaryScreenState extends State<SalesSummaryScreen> {
  String selectedRange = 'this_week';

  DateTime? customStart;
  DateTime? customEnd;


  String selectedLabel = 'This week';
  String selectedDateText = '19 Jan 2026 - 25 Jan 2026';

  String selectedStatus = 'all'; // all | paid | unpaid | partial


  bool loading = true;

  double totalSales = 0;
  List invoices = [];

  int? selectedPartyId; // null = all parties
  String selectedPartyName = "All Parties";

  List parties = [];

  // 🔽 ADD THESE TWO LINES HERE
  TextEditingController partySearchCtrl = TextEditingController();
  List filteredParties = [];


  // ================= DATE HELPERS =================

  DateTime get today => DateTime.now();

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} "
        "${_monthName(date.month)} ${date.year}";
  }

  String _monthName(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }

  String formatRange(DateTime start, DateTime end) {
    return "${formatDate(start)} - ${formatDate(end)}";
  }

  Map<String, Map<String, dynamic>> getDateRanges() {
    final now = today;
    final todayDate = DateTime(now.year, now.month, now.day);

    final yesterday = todayDate.subtract(const Duration(days: 1));

    final weekStart =
    todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(days: 1));

    final last7Start = todayDate.subtract(const Duration(days: 6));

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    int quarter = ((now.month - 1) ~/ 3) + 1;
    final quarterStartMonth = (quarter - 1) * 3 + 1;
    final quarterStart = DateTime(now.year, quarterStartMonth, 1);
    final quarterEnd = DateTime(now.year, quarterStartMonth + 3, 0);

    final lastQuarterEnd = quarterStart.subtract(const Duration(days: 1));
    final lastQuarterStart =
    DateTime(lastQuarterEnd.year, lastQuarterEnd.month - 2, 1);

    final fyStart = now.month >= 4
        ? DateTime(now.year, 4, 1)
        : DateTime(now.year - 1, 4, 1);
    final fyEnd = DateTime(fyStart.year + 1, 3, 31);

    // Previous fiscal year
    final prevFyStart = DateTime(fyStart.year - 1, 4, 1);
    final prevFyEnd = DateTime(fyStart.year, 3, 31);

// Last 365 days
    final last365Start = todayDate.subtract(const Duration(days: 364));


    return {
      'today': {
        'label': 'Today',
        'range': formatRange(todayDate, todayDate),
      },
      'yesterday': {
        'label': 'Yesterday',
        'range': formatRange(yesterday, yesterday),
      },
      'this_week': {
        'label': 'This week',
        'range': formatRange(weekStart, weekEnd),
      },
      'last_week': {
        'label': 'Last week',
        'range': formatRange(lastWeekStart, lastWeekEnd),
      },
      'last_7_days': {
        'label': 'Last 7 days',
        'range': formatRange(last7Start, todayDate),
      },
      'this_month': {
        'label': 'This month',
        'range': formatRange(monthStart, monthEnd),
      },
      'last_month': {
        'label': 'Last month',
        'range': formatRange(lastMonthStart, lastMonthEnd),
      },
      'this_quarter': {
        'label': 'This quarter',
        'range': formatRange(quarterStart, quarterEnd),
      },
      'last_quarter': {
        'label': 'Last quarter',
        'range': formatRange(lastQuarterStart, lastQuarterEnd),
      },
      'current_fy': {
        'label': 'Current fiscal year',
        'range': formatRange(fyStart, fyEnd),
      },

      'previous_fy': {
        'label': 'Previous fiscal year',
        'range': formatRange(prevFyStart, prevFyEnd),
      },

      'last_365_days': {
        'label': 'Last 365 Days',
        'range': formatRange(last365Start, todayDate),
      },

      'custom': {
        'label': 'Custom',
        'range': customStart != null && customEnd != null
            ? formatRange(customStart!, customEnd!)
            : 'Select date range',
      },
    };


  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customStart != null && customEnd != null
          ? DateTimeRange(start: customStart!, end: customEnd!)
          : null,
    );

    if (picked != null) {
      setState(() {
        customStart = picked.start;
        customEnd = picked.end;
      });
    }
  }



  @override
  void initState() {
    super.initState();
    final ranges = getDateRanges();
    selectedLabel = ranges[selectedRange]!['label'];
    selectedDateText = ranges[selectedRange]!['range'];


    fetchParties();   // ✅ ADD
    fetchSales(); // default → this_week
  }


  Future<void> fetchSales() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    // String url =
    //     "$baseUrl/sales-summary?range=$selectedRange&status=$selectedStatus";

    String url =
        "$baseUrl/sales-summary?range=$selectedRange&status=$selectedStatus";

    if (selectedPartyId != null) {
      url += "&party_id=$selectedPartyId";
    }


    // ✅ custom range needs start & end
    if (selectedRange == 'custom') {
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

    setState(() {
      totalSales = (decoded['data']['total_sales'] ?? 0).toDouble();
      invoices = decoded['data']['invoices'] ?? [];
      loading = false;
    });
  }

  Future<void> fetchParties() async {
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

    setState(() {
      parties = decoded['data'] ?? [];
      filteredParties = parties; // ✅ IMPORTANT
    });

  }

  Widget _partyBalance(dynamic p) {
    final amount = (p['opening_balance'] ?? 0).toDouble();
    final type = p['opening_balance_type']; // receive | pay

    if (amount == 0) {
      return const Text(
        "₹ 0.0",
        style: TextStyle(color: Colors.grey),
      );
    }

    final isReceive = type == 'receive';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "₹ ${amount.toStringAsFixed(0)}",
          style: TextStyle(
            color: isReceive ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isReceive
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          size: 16,
          color: isReceive ? Colors.green : Colors.red,
        ),
      ],
    );
  }


  void _openInvoiceStatus() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        const Text(
                          "Invoice Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  _statusTile("All", "all"),
                  _statusTile("Paid", "paid"),
                  _statusTile("Unpaid", "unpaid"),
                  _statusTile("Partial", "partial"),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Widget _statusTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Radio<String>(
        value: value,
        groupValue: selectedStatus,
        onChanged: (_) {
          Navigator.pop(context);
          setState(() {
            selectedStatus = value;
          });
          fetchSales();
        },
      ),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedStatus = value;
        });
        fetchSales();
      },
    );
  }


  void _openDateFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Text(
                  "Select Date",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: getDateRanges().entries.map((entry) {
                final key = entry.key;
                final label = entry.value['label'];
                final range = entry.value['range'];

                return _rangeTile(label, key, range);
              }).toList(),
            ),
          ),

        ],
      ),
    );
  }

  // void _openPartySelector() {
  //   // ✅ RESET SEARCH EVERY TIME
  //   partySearchCtrl.clear();
  //   filteredParties = List.from(parties);
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //       builder: (_) {
  //         return StatefulBuilder(
  //             builder: (context, modalSetState) {
  //               return SafeArea(
  //
  //               child: Column(
  //         children: [
  //           // HEADER
  //           Padding(
  //             padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
  //             child: Row(
  //               children: [
  //                 const Text(
  //                   "Select Party",
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  //                 ),
  //                 const Spacer(),
  //                 IconButton(
  //                   icon: const Icon(Icons.close),
  //                   onPressed: () => Navigator.pop(context),
  //                 ),
  //               ],
  //             ),
  //           ),
  //
  //           // SEARCH (optional – UI only)
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16),
  //             child:
  //             TextField(
  //               controller: partySearchCtrl,
  //               onChanged: (value) {
  //                 modalSetState(() {
  //                   filteredParties = parties.where((p) {
  //                     final name =
  //                     p['party_name'].toString().toLowerCase();
  //                     final phone =
  //                     (p['contact_number'] ?? '').toString();
  //
  //                     return name.contains(value.toLowerCase()) ||
  //                         phone.contains(value);
  //                   }).toList();
  //                 });
  //               },
  //
  //               decoration: InputDecoration(
  //                 hintText: "Search party by name or number",
  //                 prefixIcon: const Icon(Icons.search),
  //                 filled: true,
  //                 fillColor: Colors.grey.shade100,
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   borderSide: BorderSide.none,
  //                 ),
  //               ),
  //             ),
  //
  //           ),
  //
  //           const SizedBox(height: 12),
  //
  //           Expanded(
  //             child: ListView(
  //               children: [
  //                 // ALL PARTIES
  //                 ListTile(
  //                   title: const Text("All Parties"),
  //                   trailing: Radio<int?>(
  //                     value: null,
  //                     groupValue: selectedPartyId,
  //                     onChanged: (_) {
  //                       Navigator.pop(context);
  //                       setState(() {
  //                         selectedPartyId = null;
  //                         selectedPartyName = "All Parties";
  //                       });
  //                       fetchSales();
  //                     },
  //                   ),
  //                 ),
  //
  //                 const Divider(),
  //
  //                 ...filteredParties.map((p) => InkWell(
  //                   onTap: () {
  //                     Navigator.pop(context);
  //                     setState(() {
  //                       selectedPartyId = p['id'];
  //                       selectedPartyName = p['party_name'];
  //                     });
  //                     fetchSales();
  //                   },
  //                   child: Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //                     child: Row(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         // LEFT SIDE (NAME + PHONE)
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 p['party_name'],
  //                                 style: const TextStyle(
  //                                   fontSize: 15,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 4),
  //                               Text(
  //                                 p['contact_number'] ?? "",
  //                                 style: const TextStyle(
  //                                   fontSize: 13,
  //                                   color: Colors.grey,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //
  //                         // RIGHT SIDE (AMOUNT + ARROW + RADIO)
  //                         Row(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             _partyBalance(p),
  //                             const SizedBox(width: 10),
  //                             Radio<int?>(
  //                               value: p['id'],
  //                               groupValue: selectedPartyId,
  //                               onChanged: (_) {
  //                                 Navigator.pop(context);
  //                                 setState(() {
  //                                   selectedPartyId = p['id'];
  //                                   selectedPartyName = p['party_name'];
  //                                 });
  //                                 fetchSales();
  //                               },
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 )),
  //
  //
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _openPartySelector() {
    // ✅ RESET SEARCH EVERY TIME
    partySearchCtrl.clear();
    filteredParties = List.from(parties);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        const Text(
                          "Select Party",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // SEARCH
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: partySearchCtrl,
                      onChanged: (value) {
                        modalSetState(() {
                          filteredParties = parties.where((p) {
                            final name =
                            p['party_name'].toString().toLowerCase();
                            final phone =
                            (p['contact_number'] ?? '').toString();

                            return name.contains(value.toLowerCase()) ||
                                phone.contains(value);
                          }).toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search party by name or number",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: [
                        // ALL PARTIES
                        ListTile(
                          title: const Text("All Parties"),
                          trailing: Radio<int?>(
                            value: null,
                            groupValue: selectedPartyId,
                            onChanged: (_) {
                              Navigator.pop(context);
                              setState(() {
                                selectedPartyId = null;
                                selectedPartyName = "All Parties";
                              });
                              fetchSales();
                            },
                          ),
                        ),

                        const Divider(),

                        // PARTY LIST
                        ...filteredParties.map((p) => InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              selectedPartyId = p['id'];
                              selectedPartyName = p['party_name'];
                            });
                            fetchSales();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT (NAME + PHONE)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['party_name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p['contact_number'] ?? "",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // RIGHT (AMOUNT + ARROW + RADIO)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _partyBalance(p), // ✅ AMOUNT RESTORED
                                    const SizedBox(width: 10),
                                    Radio<int?>(
                                      value: p['id'],
                                      groupValue: selectedPartyId,
                                      onChanged: (_) {
                                        Navigator.pop(context);
                                        setState(() {
                                          selectedPartyId = p['id'];
                                          selectedPartyName =
                                          p['party_name'];
                                        });
                                        fetchSales();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
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




  Widget _rangeTile(String label, String value, String dateText) {
    return ListTile(
      onTap: () async {
        if (value == 'custom') {
          await _pickCustomRange();
          if (customStart == null || customEnd == null) return;
        }

        Navigator.pop(context);
        setState(() {
          selectedRange = value;
          selectedLabel = label;
          selectedDateText = value == 'custom'
              ? formatRange(customStart!, customEnd!)
              : dateText;
        });
        fetchSales();
      },

      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        dateText,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: selectedRange,
        activeColor: Colors.deepPurple,
        onChanged: (_) {
          Navigator.pop(context);
          setState(() {
            selectedRange = value;
            selectedLabel = label;
            selectedDateText = dateText;
          });
          fetchSales();
        },
      ),
    );
  }

  Widget _totalSalesCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Sales Amount",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  "₹ ${totalSales.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              TextButton(
                onPressed: () {
                  // TODO: Open full report / PDF
                },
                child: const Text(
                  "VIEW FULL REPORT",
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
              const Icon(Icons.picture_as_pdf, color: Colors.red),
            ],
          )
        ],
      ),
    );
  }


  Widget _invoiceCard(dynamic inv) {
    final isPaid = inv['status'] == 'paid';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
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
                  inv['party_name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Invoice #${inv['invoice_number']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  inv['invoice_date'],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹ ${inv['amount']}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  inv['status'].toUpperCase(),
                  style: TextStyle(
                    color: isPaid ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.deepPurple),
        title: const Text(
          "Sales Summary",
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          Icon(Icons.picture_as_pdf, color: Colors.red),
          SizedBox(width: 16),
          Icon(Icons.grid_on, color: Colors.green),
          SizedBox(width: 12),
        ],
      ),

        body: AppBackground(
          child: Column(
        children: [
          // HEADER FILTER BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.grey),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          selectedDateText,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: _openDateFilter,
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

                const SizedBox(height: 12),
                Row(
                  children: [
                    // _chip("Invoice Status"),
                    GestureDetector(
                      onTap: _openInvoiceStatus,
                      child: _chip(
                        selectedStatus == 'all'
                            ? "Invoice Status"
                            : selectedStatus.toUpperCase(),
                        active: selectedStatus != 'all',
                      ),
                    ),

                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _openPartySelector,
                      child: _chip(
                        selectedPartyName,
                        active: selectedPartyId != null,
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : invoices.isEmpty
                ? const Center(child: Text("No Data Found"))

                : ListView(
              children: [
                _totalSalesCard(),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          "Invoice",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Text(
                        "Amount",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                ...invoices.map((inv) => _invoiceCard(inv)).toList(),
              ],
            ),

          ),

        ],
      ),
        ),
    );
  }

  static Widget _chip(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? Colors.deepPurple : Colors.grey.shade400,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.deepPurple : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


