import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';



const String baseUrl = 'http://192.168.1.12:8000/api';

class SalesReportScreen extends StatefulWidget {
  final String range;
  final String status;
  final int? partyId;
  final DateTime? start;
  final DateTime? end;

  const SalesReportScreen({
    super.key,
    required this.range,
    required this.status,
    this.partyId,
    this.start,
    this.end,
  });

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  bool loading = true;
  List invoices = [];
  double total = 0;

  String selectedRange = "";
  String selectedStatus = "";
  int? selectedPartyId;
  String selectedPartyName = "All Parties";

  DateTime? customStart;
  DateTime? customEnd;

  String dateText = "";

  List parties = [];
  List filteredParties = [];
  TextEditingController partySearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    selectedRange = widget.range;
    selectedStatus = widget.status;
    selectedPartyId = widget.partyId;

    customStart = widget.start;
    customEnd = widget.end;

    formatDateRange();
    fetchParties(); // ✅ ADD THIS
    fetchReport();
  }

  // ================= DATE FORMAT =================
  void formatDateRange() {
    final ranges = getDateRanges();

    if (selectedRange == 'custom') {
      dateText =
      "${_formatDate(customStart!)} - ${_formatDate(customEnd!)}";
    } else {
      dateText = ranges[selectedRange]!['range']; // ✅ REAL RANGE
    }
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}";
  }

  // ================= API =================

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
      filteredParties = parties;
    });
  }


  Future<void> fetchReport() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    String url =
        "$baseUrl/sales-summary?range=$selectedRange&status=$selectedStatus";

    if (selectedPartyId != null) {
      url += "&party_id=$selectedPartyId";
    }

    if (selectedRange == 'custom') {
      url +=
      "&start=${customStart!.toIso8601String()}&end=${customEnd!.toIso8601String()}";
    }

    final res = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);

    setState(() {
      invoices = data['data']['invoices'];
      total = (data['data']['total_sales'] ?? 0).toDouble();
      loading = false;
    });
  }

  Map<String, Map<String, dynamic>> getDateRanges() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final yesterday = today.subtract(const Duration(days: 1));

    final weekStart =
    today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(days: 1));

    final last7Start = today.subtract(const Duration(days: 6));

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

    final prevFyStart = DateTime(fyStart.year - 1, 4, 1);
    final prevFyEnd = DateTime(fyStart.year, 3, 31);

    final last365Start = today.subtract(const Duration(days: 364));

    String format(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}";

    String range(DateTime s, DateTime e) => "${format(s)} - ${format(e)}";

    return {
      'today': {'label': 'Today', 'range': range(today, today)},
      'yesterday': {'label': 'Yesterday', 'range': range(yesterday, yesterday)},
      'this_week': {'label': 'This week', 'range': range(weekStart, weekEnd)},
      'last_week': {'label': 'Last week', 'range': range(lastWeekStart, lastWeekEnd)},
      'last_7_days': {'label': 'Last 7 days', 'range': range(last7Start, today)},
      'this_month': {'label': 'This month', 'range': range(monthStart, monthEnd)},
      'last_month': {'label': 'Last month', 'range': range(lastMonthStart, lastMonthEnd)},
      'this_quarter': {'label': 'This quarter', 'range': range(quarterStart, quarterEnd)},
      'last_quarter': {'label': 'Last quarter', 'range': range(lastQuarterStart, lastQuarterEnd)},
      'current_fy': {'label': 'Current fiscal year', 'range': range(fyStart, fyEnd)},
      'previous_fy': {'label': 'Previous fiscal year', 'range': range(prevFyStart, prevFyEnd)},
      'last_365_days': {'label': 'Last 365 Days', 'range': range(last365Start, today)},
      'custom': {
        'label': 'Custom',
        'range': customStart != null && customEnd != null
            ? range(customStart!, customEnd!)
            : 'Select date range',
      },
    };
  }

  String _month(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }


  void _openShareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ IMPORTANT
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Container(
            height: 200, // ✅ FIX HEIGHT (same as CSV)
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      "Share PDF",
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

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _shareItem(Icons.download, "Download", () {
                      Navigator.pop(context);
                      _downloadPdf();
                    }),
                    _shareItem(FontAwesomeIcons.whatsapp, "WhatsApp", () {
                      Navigator.pop(context);
                      _shareWhatsApp();
                    }),
                    _shareItem(Icons.email, "Email", () {
                      Navigator.pop(context);
                      _shareEmail();
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _downloadPdfFile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    String url =
        "$baseUrl/sales-summary-pdf?range=$selectedRange&status=$selectedStatus";

    if (selectedPartyId != null) {
      url += "&party_id=$selectedPartyId";
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/sales_report.pdf";

    await Dio().download(
      url,
      filePath,
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
        responseType: ResponseType.bytes,
      ),
    );

    return filePath;
  }

  Widget _shareItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ ADD THIS
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(icon, size: 28, color: Colors.deepPurple),
          ),
          const SizedBox(height: 6),
          Text(text,
            style: const TextStyle(fontSize: 13), // ✅ smaller text
          ),
        ],
      ),
    );
  }

  void _downloadPdf() async {
    final path = await _downloadPdfFile();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF Downloaded")),
    );

    OpenFile.open(path); // auto open
  }

  void _shareWhatsApp() async {
    final path = await _downloadPdfFile();

    await Share.shareXFiles(
      [XFile(path)],
      text: "Sales Report PDF",
    );
  }

  void _shareEmail() async {
    final path = await _downloadPdfFile();

    await Share.shareXFiles(
      [XFile(path)],
      text: "Sales Report PDF",
    );
  }

  // ================= DATE FILTER =================
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

  Widget _rangeTile(String label, String value, String dateText) {
    return ListTile(
      title: Text(label),
      subtitle: Text(dateText, style: const TextStyle(fontSize: 12)),
      trailing: Radio<String>(
        value: value,
        groupValue: selectedRange,
        onChanged: (_) {
          Navigator.pop(context);
          setState(() {
            selectedRange = value;
            formatDateRange();
          });
          fetchReport();
        },
      ),
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
        }

        Navigator.pop(context);
        setState(() {
          selectedRange = value;
          formatDateRange();
        });

        fetchReport();
      },
    );
  }

  // ================= STATUS FILTER =================
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
      onTap: () {
        Navigator.pop(context);

        setState(() {
          selectedStatus = value;
        });

        fetchReport();
      },
    );
  }

  String formatInvoiceDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);

      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

      // OR use below for "30 Mar 2026"
      // return "${date.day} ${_month(date.month)} ${date.year}";
    } catch (e) {
      return rawDate;
    }
  }

  // void _openCsvShareSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true, // ✅ IMPORTANT
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (_) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Row(
  //               children: [
  //                 const Text(
  //                   "Share CSV",
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  //                 ),
  //                 const Spacer(),
  //                 IconButton(
  //                   icon: const Icon(Icons.close),
  //                   onPressed: () => Navigator.pop(context),
  //                 ),
  //               ],
  //             ),
  //
  //             const SizedBox(height: 10),
  //
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 _shareItem(Icons.download, "Download", () {
  //                   Navigator.pop(context);
  //                   _downloadCsv();
  //                 }),
  //                 _shareItem(FontAwesomeIcons.whatsapp, "WhatsApp", () {
  //                   Navigator.pop(context);
  //                   _shareCsv();
  //                 }),
  //                 _shareItem(Icons.email, "Email", () {
  //                   Navigator.pop(context);
  //                   _shareCsv();
  //                 }),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  void _openCsvShareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ IMPORTANT
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 200, // ✅ FIX HEIGHT
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      "Share CSV",
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

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _shareItem(Icons.download, "Download", () {
                      Navigator.pop(context);
                      _downloadCsv();
                    }),
                    _shareItem(FontAwesomeIcons.whatsapp, "WhatsApp", () {
                      Navigator.pop(context);
                      _shareCsv();
                    }),
                    _shareItem(Icons.email, "Email", () {
                      Navigator.pop(context);
                      _shareCsv();
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _generateCsvFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/sales_report.csv";

    String csv = "Invoice No,Date,Party,Amount,Status\n";

    for (var inv in invoices) {
      csv +=
      "${inv['invoice_number']},"
          "${formatInvoiceDate(inv['invoice_date'])},"
          "${inv['party_name']},"
          "${inv['amount']},"
          "${inv['status']}\n";
    }

    final file = File(path);
    await file.writeAsString(csv);

    return path;
  }

  void _downloadCsv() async {
    final path = await _generateCsvFile();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("CSV Downloaded")),
    );

    OpenFile.open(path);
  }

  void _shareCsv() async {
    final path = await _generateCsvFile();

    await Share.shareXFiles(
      [XFile(path)],
      text: "Sales Report CSV",
    );
  }

  // ================= PARTY FILTER (SIMPLE VERSION) =================


  void _openPartySelector() {
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
                              fetchReport();
                            },
                          ),
                        ),

                        const Divider(),

                        // PARTY LIST
                        ...filteredParties.map((p) => ListTile(
                          title: Text(p['party_name']),
                          subtitle: Text(p['contact_number'] ?? ""),
                          trailing: Radio<int?>(
                            value: p['id'],
                            groupValue: selectedPartyId,
                            onChanged: (_) {
                              Navigator.pop(context);
                              setState(() {
                                selectedPartyId = p['id'];
                                selectedPartyName = p['party_name'];
                              });
                              fetchReport();
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              selectedPartyId = p['id'];
                              selectedPartyName = p['party_name'];
                            });
                            fetchReport();
                          },
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Summary"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.orange),
            onPressed: _openShareSheet,
          ),
          IconButton(
            icon: const Icon(Icons.grid_on, color: Colors.green),
            onPressed: _openCsvShareSheet,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          // ===== DATE BAR =====
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  dateText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                )
              ],
            ),
          ),

          // ===== FILTER CHIPS =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openInvoiceStatus,
                  child: _chip(
                    selectedStatus == 'all'
                        ? "Invoice Status"
                        : selectedStatus.toUpperCase(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _openPartySelector,
                  child: _chip(selectedPartyName),
                ),
              ],
            ),
          ),

          // ===== BUSINESS =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Business Name",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Phone no: 6205857707"),
                  ],
                ),
                Text("Invoice_report",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== SUMMARY BOX =====
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Duration : $dateText"),
                  Text(
                    "Total Invoice Amount : ₹ ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== TABLE HEADER =====
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.all(8),
            child: const Row(
              children: [
                Expanded(child: Text("Invoice No")),
                Expanded(child: Text("Date")),
                Expanded(child: Text("Party")),
                Expanded(child: Text("Total")),
                Expanded(child: Text("Status")),
              ],
            ),
          ),

          // ===== LIST =====
          Expanded(
            child: ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (_, i) {
                final inv = invoices[i];

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    border:
                    Border(bottom: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(inv['invoice_number'])),
                      Expanded(child: Text(formatInvoiceDate(inv['invoice_date']))),
                      Expanded(child: Text(inv['party_name'])),
                      Expanded(child: Text("₹ ${inv['amount']}")),
                      Expanded(child: Text(inv['status'])),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}