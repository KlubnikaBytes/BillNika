import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ ADDED
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart'; //

import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


const String baseUrl = 'http://192.168.1.11:8000/api';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  bool loading = true;
  List items = [];
  double totalValue = 0;
  double totalQty = 0;

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/stock-summary"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(res.body);

    // setState(() {
    //   items = data['data']['items'];
    //   totalValue = (data['data']['total_stock_value'] ?? 0).toDouble();
    //   loading = false;
    // });

    setState(() {
      items = data['data']['items'];
      totalValue = (data['data']['total_stock_value'] ?? 0).toDouble();

      totalQty = 0;
      for (var item in items) {
        totalQty += double.tryParse(item['quantity'].toString()) ?? 0;
      }

      loading = false;
    });
  }

  String today = DateFormat("dd/MM/yyyy").format(DateTime.now());

  // ================= SHARE SHEET =================
  Future<void> openShareSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewPadding.bottom + 16, // 👈 FIX
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Row(
                children: [
                  const Text(
                    "Share via",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  _shareItem(Icons.download, "Download", () async {
                    Navigator.pop(context);
                    await downloadPdf();
                  }),

                  _shareItem(FontAwesomeIcons.whatsapp, "WhatsApp", () async {
                    Navigator.pop(context);
                    await shareOnWhatsApp();
                  }),

                  _shareItem(Icons.email, "Email", () async {
                    Navigator.pop(context);
                    await shareOnEmail();
                  }),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }



  // ================= DOWNLOAD PDF =================
  Future<void> downloadPdf() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final url = "$baseUrl/stock-summary-pdf?token=$token";

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ================= WHATSAPP SHARE =================
  Future<void> shareOnWhatsApp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final url = "$baseUrl/stock-summary-pdf?token=$token";

    // 🔽 DOWNLOAD FILE FIRST
    final response = await http.get(Uri.parse(url));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/stock_report.pdf');

    await file.writeAsBytes(response.bodyBytes);

    // 🔽 SHARE FILE (WhatsApp picker will open)
    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Stock Summary Report",
    );
  }

  Future<void> shareOnEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final url = "$baseUrl/stock-summary-pdf?token=$token";

    // 🔽 DOWNLOAD FILE
    final response = await http.get(Uri.parse(url));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/stock_report.pdf');

    await file.writeAsBytes(response.bodyBytes);

    // 🔽 SHARE AS EMAIL ATTACHMENT
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: "Stock Summary Report",
      text: "Please find attached Stock Summary Report",
    );
  }

  Future<void> openCsvShareSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewPadding.bottom + 16, // 👈 FIX
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Row(
                children: [
                  const Text("Share via",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  _shareItem(Icons.download, "Download", () async {
                    Navigator.pop(context);
                    await downloadPdf();
                  }),

                  _shareItem(FontAwesomeIcons.whatsapp, "WhatsApp", () async {
                    Navigator.pop(context);
                    await shareCsvWhatsApp();
                  }),

                  _shareItem(Icons.email, "Email", () async {
                    Navigator.pop(context);
                    await shareCsvEmail();
                  }),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<File> createCsvFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/stock_report.csv');

    String csv = "Name,Code,Purchase,Selling,Qty,Value\n";

    for (var item in items) {
      csv +=
      "${item['name']},${item['item_code']},${item['purchase_price']},${item['selling_price']},${item['quantity']} ${item['unit']},${item['value']}\n";
    }

    await file.writeAsString(csv);

    return file;
  }



  Future<void> downloadCsv() async {
    final file = await createCsvFile();

    const platform = MethodChannel('download_channel');

    try {
      await platform.invokeMethod('saveFileToDownloads', {
        "path": file.path,
        "fileName": "stock_report.csv"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CSV downloaded to Downloads")),
      );
    } catch (e) {
      print("Download error: $e");
    }
  }

  Future<void> shareCsvWhatsApp() async {
    final file = await createCsvFile();

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Stock CSV Report",
    );
  }

  Future<void> shareCsvEmail() async {
    final file = await createCsvFile();

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: "Stock CSV Report",
      text: "Please find attached CSV report",
    );
  }

  // ================= SHARE ITEM =================
  Widget _shareItem(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: icon == FontAwesomeIcons.whatsapp
                ? const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 24)
                : Icon(icon, size: 24),
          ),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Summary"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.orange),
            onPressed: openShareSheet, // ✅ UPDATED
          ),
          IconButton(
            icon: const Icon(Icons.grid_on, color: Colors.green),
            onPressed: openCsvShareSheet, // ✅ ADD THIS
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // 👈 IMPORTANT
        child: Column(
          children: [

            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.deepPurple),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("All Categories",
                        style: TextStyle(color: Colors.deepPurple)),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.deepPurple)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
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
                Text("Stock Summary Report",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date: $today"),
                    Text(
                      "Total Stock Value : ₹ ${totalValue.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              color: Colors.grey.shade300,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text("Name")),
                  Expanded(child: Text("Item Code")),
                  Expanded(child: Text("Purchase Price")),
                  Expanded(child: Text("Selling Price")),
                  Expanded(child: Text("Stock Qty")),
                  Expanded(child: Text("Stock Value")),
                ],
              ),
            ),

            ...items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(item['name'] ?? "")),
                    Expanded(child: Text(item['item_code'] ?? "-")),
                    Expanded(child: Text("${item['purchase_price'] ?? 0}")),
                    Expanded(child: Text("${item['selling_price'] ?? 0}")),
                    Expanded(child: Text("${item['quantity']} ${item['unit']}")),
                    Expanded(child: Text("₹ ${item['value']}")),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 10),


            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text("Total",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                const Expanded(child: SizedBox()), // Code
                const Expanded(child: SizedBox()), // Purchase
                const Expanded(child: SizedBox()), // Selling

                // ✅ TOTAL QTY
                Expanded(
                  child: Text(
                    totalQty.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

                // ✅ TOTAL VALUE
                Expanded(
                  child: Text(
                    "₹ ${totalValue.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}