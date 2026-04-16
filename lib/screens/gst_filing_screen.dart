import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_project/widgets/app_background.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

const String baseUrl = 'http://192.168.1.11:8000/api';

class GstFilingScreen extends StatefulWidget {
  const GstFilingScreen({super.key});

  @override
  State<GstFilingScreen> createState() => _GstFilingScreenState();
}

class _GstFilingScreenState extends State<GstFilingScreen> {
  List data = [];
  bool loading = true;

  String selectedRange = "last_month";
  String rangeLabel = "Last Month";
  String startDate = "";
  String endDate = "";

  String businessName = "";
  String mobile = "";
  String gstNo = "";

  @override
  void initState() {
    super.initState();
    setDefaultDates();
    fetchGST();
  }

  void setDefaultDates() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month - 1, 1);
    final lastDay = DateTime(now.year, now.month, 0);

    startDate = DateFormat("yyyy-MM-dd").format(firstDay);
    endDate = DateFormat("yyyy-MM-dd").format(lastDay);
  }

  Future<void> fetchGST() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/gst-report?range=$selectedRange"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    setState(() {
      data = decoded['data'] ?? [];
      startDate = decoded['start'] ?? startDate;
      endDate = decoded['end'] ?? endDate;

      // ✅ ADD THIS
      businessName = decoded['business']?['name'] ?? '';
      mobile = decoded['business']?['mobile'] ?? '';
      gstNo = decoded['business']?['gst'] ?? '';
      loading = false;
    });
  }

  String formatDate(String date) {
    return DateFormat("dd/MM/yyyy").format(DateTime.parse(date));
  }

  String formatRange() {
    return "${DateFormat("dd/MM/yyyy").format(DateTime.parse(startDate))} "
        "to ${DateFormat("dd/MM/yyyy").format(DateTime.parse(endDate))}";
  }

  // ================= DATE PICKER =================
  void openDateSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: [
            buildOption("Today", "today"),
            buildOption("Yesterday", "yesterday"),
            buildOption("This week", "this_week"),
            buildOption("Last week", "last_week"),
            buildOption("Last 7 days", "last_7_days"),
            buildOption("This month", "this_month"),
            buildOption("Last Month", "last_month"),
            buildOption("This quarter", "this_quarter"),
            buildOption("Last quarter", "last_quarter"),
            // ✅ ADD THIS
            buildOption("Custom", "custom"),
          ],
        );
      },
    );
  }

  Future<void> pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.deepPurple,
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedRange = "custom";
        rangeLabel = "Custom";

        startDate = DateFormat("yyyy-MM-dd").format(picked.start);
        endDate = DateFormat("yyyy-MM-dd").format(picked.end);
      });

      fetchGSTCustom(); // ✅ CALL CUSTOM API
    }
  }

  Future<void> fetchGSTCustom() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse(
          "$baseUrl/gst-report?range=custom&start=$startDate&end=$endDate"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    setState(() {
      data = decoded['data'] ?? [];
      loading = false;
    });
  }

  Widget buildOption(String title, String value) {
    final range = getRangeDates(value); // ✅ get calculated date

    return ListTile(
      title: Text(title),
      subtitle: Text(
        range, // ✅ SHOW DATE RANGE HERE
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: selectedRange == value
          ? const Icon(Icons.radio_button_checked, color: Colors.deepPurple)
          : const Icon(Icons.radio_button_off),
      onTap: () async {
        Navigator.pop(context);

        if (value == "custom") {
          await pickCustomDateRange(); // ✅ OPEN CALENDAR
        } else {
          setState(() {
            selectedRange = value;
            rangeLabel = title;
          });
          fetchGST();
        }
      },
    );
  }

  String getRangeDates(String range) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    switch (range) {
      case "today":
        start = end = now;
        break;

      case "yesterday":
        start = end = now.subtract(const Duration(days: 1));
        break;

      case "this_week":
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;

      case "last_week":
        end = now.subtract(Duration(days: now.weekday));
        start = end.subtract(const Duration(days: 6));
        break;

      case "last_7_days":
        start = now.subtract(const Duration(days: 6));
        end = now;
        break;

      case "this_month":
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;

      case "last_month":
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;

      case "this_quarter":
        int q = ((now.month - 1) ~/ 3) + 1;
        start = DateTime(now.year, (q - 1) * 3 + 1, 1);
        end = DateTime(now.year, q * 3 + 1, 0);
        break;

      case "last_quarter":
        int q = ((now.month - 1) ~/ 3);
        if (q == 0) {
          start = DateTime(now.year - 1, 10, 1);
          end = DateTime(now.year - 1, 12, 31);
        } else {
          start = DateTime(now.year, (q - 1) * 3 + 1, 1);
          end = DateTime(now.year, q * 3, 0);
        }
        break;

      default:
        start = now;
        end = now;
    }

    return "${DateFormat("dd MMM yyyy").format(start)} - ${DateFormat("dd MMM yyyy").format(end)}";
  }

  double getTotalSales() {
    double total = 0;
    for (var item in data) {
      total += (item['invoice_value'] ?? 0);
    }
    return total;
  }

  Future<String?> downloadCsv() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/gst_report.csv");

      // ✅ CSV HEADER
      String csv = "Customer,Place,Invoice,Date,Value,Taxable,GST %,CGST,SGST,Total GST\n";

      // ✅ ADD DATA ROWS
      for (var row in data) {
        csv += "${row['party_name']},"
            "${row['place_of_supply']},"
            "${row['invoice_no']},"
            "${formatDate(row['date'])},"
            "${row['invoice_value']},"
            "${row['taxable_value']},"
            "${row['gst_percent']},"
            "${row['cgst']},"
            "${row['sgst']},"
            "${row['total_tax']}\n";
      }

      await file.writeAsString(csv);

      return file.path;
    } catch (e) {
      print("CSV Error: $e");
      return null;
    }
  }

  Future<String?> downloadPdf() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final response = await http.get(
      Uri.parse(
          "$baseUrl/gst-report-pdf?range=$selectedRange&start=$startDate&end=$endDate"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/gst_report.pdf");

      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    }

    return null;
  }

  void showShareOptions(String filePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ IMPORTANT
      backgroundColor: Colors.transparent, // nice UI
      builder: (_) {
        return SafeArea( // ✅ avoids system nav overlap
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Wrap( // ✅ auto height fix
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    buildShareItem(
                      Icons.download,
                      "Download",
                          () {
                        Navigator.pop(context); // ✅ close first
                        OpenFile.open(filePath);
                      },
                    ),
                    buildShareItem(
                      Icons.share,
                      "WhatsApp",
                          () {
                        Navigator.pop(context);
                        Share.shareXFiles([XFile(filePath)]);
                      },
                    ),
                    buildShareItem(
                      Icons.email,
                      "Email",
                          () {
                        Navigator.pop(context);
                        Share.shareXFiles([XFile(filePath)]);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildShareItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            child: Icon(icon, color: Colors.deepPurple),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GSTR-1 (Sales)"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () async {
                final path = await downloadPdf();

                if (path != null) {
                  showShareOptions(path); // ✅ OPEN BOTTOM SHEET
                }
              },
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
          ),
          // ✅ NEW EXCEL BUTTON
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () async {
                final path = await downloadCsv(); // 👈 call CSV
                if (path != null) showShareOptions(path);
              },
              child: const Icon(Icons.table_chart, color: Colors.green),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // ================= DATE RANGE =================
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    rangeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: openDateSelector,
                    child: const Text(
                      "CHANGE",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= REPORT =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "GSTR-1",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 5),
                    Text(businessName.isEmpty ? "Business Name" : businessName),
                    Text("Mobile: ${mobile.isEmpty ? 'N/A' : mobile}"),
                    Text("GST No: ${gstNo.isEmpty ? 'N/A' : gstNo}"),

                    const SizedBox(height: 10),

                    Text(
                      "Date Range: ${formatRange()}",
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 16),

                    // HEADER
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[300],
                      child: Row(
                        children: const [
                          Expanded(flex: 2, child: Text("Customer")),
                          Expanded(flex: 2, child: Text("Place")),
                          Expanded(flex: 2, child: Text("Invoice")),
                          Expanded(flex: 2, child: Text("Date")),
                          Expanded(flex: 2, child: Text("Value")),
                          Expanded(flex: 2, child: Text("Taxable")),
                          Expanded(flex: 2, child: Text("GST %")),
                          Expanded(flex: 2, child: Text("CGST")),
                          Expanded(flex: 2, child: Text("SGST")),
                          Expanded(flex: 2, child: Text("Total GST")),
                        ],
                      ),
                    ),

                    ...data.map((row) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                            BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 2,
                                child: Text(row['party_name'] ?? '')),
                            Expanded(
                                flex: 2,
                                child:
                                Text(row['place_of_supply'] ?? '')),
                            Expanded(
                                flex: 2,
                                child: Text(row['invoice_no'] ?? '')),
                            Expanded(
                                flex: 2,
                                child: Text(formatDate(row['date']))),

                            Expanded(
                                flex: 2,
                                child:
                                Text("₹ ${row['invoice_value']}")),
                            Expanded(
                                flex: 2,
                                child:
                                Text("₹ ${row['taxable_value']}")),
                            Expanded(
                                flex: 2,
                                child:
                                Text("${row['gst_percent']}%")),
                            Expanded(
                                flex: 2,
                                child: Text("₹ ${row['cgst']}")),
                            Expanded(
                                flex: 2,
                                child: Text("₹ ${row['sgst']}")),
                            Expanded(
                                flex: 2,
                                child: Text("₹ ${row['total_tax']}")),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    Text(
                      "Total Sales: ₹ ${getTotalSales().toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}