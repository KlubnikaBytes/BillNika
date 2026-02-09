import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'party_flow_screens.dart';
import '../models/party_model.dart';
import 'create_invoice_screen.dart';
import 'package:flutter_project/widgets/app_background.dart';


const String baseUrl = "http://127.0.0.1:8000/api";
// const String baseUrl = "http://10.0.2.2:8000/api";


class PartyDetailScreen extends StatefulWidget {
  final int partyId;

  const PartyDetailScreen({super.key, required this.partyId});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  bool loading = true;
  Map party = {};
  // List invoices = [];
  List transactions = [];
  List filteredTransactions = [];

  String selectedRangeLabel = "Last 365 Days";
  DateTimeRange? selectedRange;
  DateTimeRange? customRange;


  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    fetchPartyInvoices();
  }

  Future<void> fetchPartyInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      // Uri.parse("$baseUrl/parties/${widget.partyId}/all-invoices"),
      Uri.parse("$baseUrl/parties/${widget.partyId}/transactions"),

      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    setState(() {
      party = decoded['party'];
      transactions = decoded['transactions']; // 👈 IMPORTANT
      filteredTransactions = transactions; // default
      loading = false;
    });
  }


  void applyDateFilter(String label) {
    final now = DateTime.now();

    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (label) {

      case "Today":
        start = DateTime(now.year, now.month, now.day);
        break;

      case "Yesterday":
        final y = now.subtract(const Duration(days: 1));
        start = DateTime(y.year, y.month, y.day);
        end = DateTime(y.year, y.month, y.day, 23, 59, 59);
        break;

      case "This week":
        start = now.subtract(Duration(days: now.weekday - 1));
        break;

      case "Last week":
        final lastWeekEnd = now.subtract(Duration(days: now.weekday));
        start = lastWeekEnd.subtract(const Duration(days: 6));
        end = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day, 23, 59, 59);
        break;

      case "Last 7 days":
        start = now.subtract(const Duration(days: 6));
        break;

      case "This month":
        start = DateTime(now.year, now.month, 1);
        break;

      case "Last month":
        final prev = DateTime(now.year, now.month - 1, 1);
        start = prev;
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;

      case "This quarter":
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        start = DateTime(now.year, q, 1);
        break;

      case "Last quarter":
        final q = ((now.month - 1) ~/ 3) * 3 - 2;
        start = DateTime(now.year, q, 1);
        end = DateTime(now.year, q + 3, 0, 23, 59, 59);
        break;

      case "Current fiscal year":
        start = now.month >= 4
            ? DateTime(now.year, 4, 1)
            : DateTime(now.year - 1, 4, 1);
        break;

      case "Previous fiscal year":
        start = DateTime(now.year - 1, 4, 1);
        end = DateTime(now.year, 3, 31, 23, 59, 59);
        break;

      case "Last 365 Days":
      default:
        start = now.subtract(const Duration(days: 365));
    }

    setState(() {
      filteredTransactions = transactions.where((tx) {
        final txDate = DateTime.parse(tx['date']);
        return txDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            txDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    });
  }

  DateTimeRange? _rangeForLabel(String label) {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (label) {
      case "Today":
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
        break;

      case "Yesterday":
        start = DateTime(now.year, now.month, now.day - 1);
        end = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(seconds: 1));
        break;

      case "This week":
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;

      case "Last week":
        end = now.subtract(Duration(days: now.weekday));
        start = end.subtract(const Duration(days: 6));
        break;

      case "Last 7 days":
        start = now.subtract(const Duration(days: 6));
        end = now;
        break;

      case "This month":
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;

      case "Last month":
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;

      case "This quarter":
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        start = DateTime(now.year, q, 1);
        end = DateTime(now.year, q + 3, 0);
        break;

      case "Last quarter":
        final q = ((now.month - 1) ~/ 3) * 3 - 2;
        start = DateTime(now.year, q, 1);
        end = DateTime(now.year, q + 3, 0);
        break;

      case "Current fiscal year":
        start = now.month >= 4
            ? DateTime(now.year, 4, 1)
            : DateTime(now.year - 1, 4, 1);
        end = DateTime(start.year + 1, 3, 31);
        break;

      case "Previous fiscal year":
        start = DateTime(now.year - 1, 4, 1);
        end = DateTime(now.year, 3, 31);
        break;

      case "Last 365 Days":
        start = now.subtract(const Duration(days: 365));
        end = now;
        break;

      default:
        return null;
    }

    return DateTimeRange(start: start, end: end);
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customRange,
    );

    if (picked != null) {
      setState(() {
        customRange = picked;
        selectedRangeLabel = "Custom";

        filteredTransactions = transactions.where((tx) {
          final txDate = DateTime.parse(tx['date']);
          return txDate.isAfter(picked.start.subtract(const Duration(seconds: 1))) &&
              txDate.isBefore(picked.end.add(const Duration(seconds: 1)));
        }).toList();
      });
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [

          IconButton(
            icon: const Icon(Icons.edit, color: Colors.deepPurple),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token') ?? "";

              final res = await http.get(
                Uri.parse("$baseUrl/parties/${widget.partyId}"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Accept": "application/json",
                },
              );

              if (res.statusCode == 200) {
                final json = jsonDecode(res.body);
                final party = PartyModel.fromJson(json['data']);

                final updatedParty = await Navigator.push<PartyModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateNewPartyScreen(
                      primary: Colors.deepPurple,
                      initialParty: party,
                    ),
                  ),
                );

// 🔁 REFRESH AFTER SAVE
                if (updatedParty != null) {
                  fetchPartyInvoices(); // reload party + transactions
                }

              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeletePartySheet,
          ),

        ],
      ),

        body: AppBackground(
          child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ---------- HEADER ----------
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    party['party_name'][0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        party['party_name'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Text(
                            "₹ ${party['opening_balance']}",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            party['opening_balance_type'] == 'pay'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: party['opening_balance_type'] == 'pay'
                                ? Colors.red
                                : Colors.green,
                            size: 18,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                // const Icon(Icons.picture_as_pdf, color: Colors.red),
                // -------- PDF + Party Type --------
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      party['party_type'] == 'supplier'
                          ? 'Supplier'
                          : 'Customer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------- ACTION BUTTONS ----------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text("Invite Now"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () {},
                    // icon: const Icon(Icons.whatsapp),
                    label: const Text("Send Reminder"),
                  ),
                ),
              ],
            ),
          ),

          // ---------- TABS ----------
          TabBar(
            controller: tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: "Transactions"),
              Tab(text: "Details"),
              Tab(text: "Notes"),
            ],
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Expanded(

                  child: Text(
                    customRange != null
                        ? "${_fmt(customRange!.start)} - ${_fmt(customRange!.end)}"
                        : selectedRangeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),

                ),
                GestureDetector(
                  onTap: _openDateFilterSheet,
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


          // ---------- TAB CONTENT ----------
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _transactionsTab(),
                _detailsTab(),
                _notesTab(),
              ],
            ),
          ),
        ],
      ),
        ),

      // ---------- BOTTOM BUTTON ----------
      // floatingActionButtonLocation:
      // FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: ElevatedButton.icon(
      //   style: ElevatedButton.styleFrom(
      //     backgroundColor: Colors.deepPurple,
      //     padding:
      //     const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      //     shape:
      //     RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      //   ),
      //   onPressed: () {},
      //   icon: const Icon(Icons.add),
      //   label: const Text("+ Bill / Invoice"),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 👈 CENTER GROUP
          children: [

            // ✅ SMALL ROUND "+" BUTTON
            FloatingActionButton(
              heroTag: "addBtn",
              mini: true, // 👈 SMALL SIZE
              backgroundColor: Colors.green,
              elevation: 4,
              onPressed: () {
                // TODO: quick add
              },
              child: const Icon(
                Icons.add,
                size: 22,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 12),

            // ✅ SMALLER "+ Bill / Invoice" BUTTON
            SizedBox(
              height: 44, // 👈 SMALLER HEIGHT
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                // onPressed: () {
                //   // TODO: Create invoice
                // },
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateInvoiceScreen(
                        // preselectedParty: PartyModel.fromJson(party), // ✅ PASS PARTY
                        preselectedParty: PartyModel(
                          id: party['id'],
                          partyName: party['party_name'],
                          contactNumber: party['contact_number'],
                          partyType: party['party_type'],
                          openingBalance:
                          double.tryParse(party['opening_balance'].toString()) ?? 0,
                          openingBalanceType:
                          party['opening_balance_type'] ?? 'receive',
                        ),

                      ),
                    ),
                  );
                },

                child: const Text(
                  "+ Bill / Invoice",
                  style: TextStyle(
                    fontSize: 14, // 👈 SMALLER TEXT
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),


    );
  }

  // ================= TABS =================

  void _openDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Select Date",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                children: [
                  _dateOption("Today"),
                  _dateOption("Yesterday"),
                  _dateOption("This week"),
                  _dateOption("Last week"),
                  _dateOption("Last 7 days"),
                  _dateOption("This month"),
                  _dateOption("Last month"),
                  _dateOption("This quarter"),
                  _dateOption("Last quarter"),
                  _dateOption("Current fiscal year"),
                  _dateOption("Previous fiscal year"),
                  _dateOption("Last 365 Days"),
                  _dateOption("Custom"),
                ],
              ),
            ),
          ],
        );
      },
    );
  }



  Widget _dateOption(String label) {
    final range = _rangeForLabel(label);

    return ListTile(
      title: Text(label),
      subtitle: range == null
          ? null
          : Text(
        "${_fmt(range.start)} - ${_fmt(range.end)}",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Radio<String>(
        value: label,
        groupValue: selectedRangeLabel,
        onChanged: (val) {
          Navigator.pop(context);

          if (val == "Custom") {
            _pickCustomRange();
            return;
          }

          setState(() {
            selectedRangeLabel = val!;
            customRange = null;
            applyDateFilter(val);
          });
        },
      ),
    );
  }




  Widget _transactionsTab() {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        // itemCount: transactions.length,
          itemCount: filteredTransactions.length,


          itemBuilder: (context, index) {
          // final tx = transactions[index];
             final tx = filteredTransactions[index];

          // ================= INVOICE =================
          if (tx['type'] == 'invoice') {
            final String status = tx['status'];

            final bool isPaid = status == 'paid';
            final double amount = isPaid
                ? (double.tryParse(tx['received_amount'].toString()) ?? 0)
                : (double.tryParse(tx['balance_amount'].toString()) ?? 0);

            Color badgeColor;
            String badgeText;

            switch (status) {
              case 'paid':
                badgeColor = Colors.green.shade100;
                badgeText = 'Paid';
                break;
              case 'partial':
                badgeColor = Colors.orange.shade100;
                badgeText = 'Partial';
                break;
              default:
                badgeColor = Colors.red.shade100;
                badgeText = 'Unpaid';
            }

            return Card(
              child: ListTile(
                title: Text("Invoice #${tx['number']}"),
                subtitle: Text(tx['date']),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "₹ ${amount.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ================= RECEIVED PAYMENT =================
          return Card(
            color: Colors.grey.shade200,
            child: ListTile(
              title: Text("Received Payment #${tx['number']}"),
              subtitle: Text(tx['date']),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "₹ ${tx['amount']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Send Receipt",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }



  Widget _detailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("Party Info"),
        _infoRow(
          icon: Icons.phone,
          label: "Contact Number",
          // Contact
          value: party['contact_number'] ?? "--",
        ),

        const SizedBox(height: 20),
        _divider(),

        _sectionTitle("GST & PAN"),
        _twoColumnRow(
          leftLabel: "GST Registration Type",
          // leftValue: party['gst_type'] ?? "Unregistered",
          leftValue: party['gst_number'] == null ? "Unregistered" : "Registered",
          rightLabel: "GSTIN",
          // rightValue: party['gstin'] ?? "--",
          rightValue: party['gst_number'] ?? "--",
        ),
        const SizedBox(height: 12),
        _singleInfoRow(
          label: "PAN Number",
          value: party['pan_number'] ?? "--",
        ),

        const SizedBox(height: 20),
        _divider(),

        _sectionTitle("Address"),
        _twoColumnRow(
          leftLabel: "Billing Address",
          // leftValue: party['billing_address'] ?? "--",
          leftValue: party['billing_address'] ?? "--",
          rightLabel: "Shipping Address",
          // rightValue: party['shipping_address'] ?? party['party_name'],
          rightValue: party['shipping_address'] ?? "--",
        ),

        const SizedBox(height: 20),
        _divider(),

        _sectionTitle("Balance Details"),
        _twoColumnRow(
          leftLabel: "Credit Period (Days)",
          // leftValue: party['credit_period']?.toString() ?? "0",
          leftValue: party['credit_period_days']?.toString() ?? "0",
          rightLabel: "Credit Limit",
          // rightValue: party['credit_limit']?.toString() ?? "--",
          rightValue: party['credit_limit']?.toString() ?? "--",
        ),
      ],
    );
  }


  Widget _notesTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 10),
        const Text("No Notes & Appointments"),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today),
              label: const Text("Appointment"),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87),
              onPressed: () {},
              icon: const Icon(Icons.note),
              label: const Text("Note"),
            ),
          ],
        )
      ],
    );
  }

  void _showDeletePartySheet() {
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
                      "Delete Party",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
                "Are you sure you want to delete this Party? "
                    "Deleted Party cannot be retrieved",
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
                      color: Colors.white, // ✅ FIX
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
                  onPressed: _deleteParty,
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


  Future<void> _deleteParty() async {
    Navigator.pop(context); // close bottom sheet

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.delete(
      Uri.parse("$baseUrl/parties/${widget.partyId}"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      // 🔁 Go back to previous screen (party list)
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete party")),
      );
    }
  }




  String _fmt(DateTime d) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return "${d.day.toString().padLeft(2, '0')} "
        "${months[d.month - 1]} "
        "${d.year}";
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _twoColumnRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return Row(
      children: [
        Expanded(
          child: _singleInfoRow(
            label: leftLabel,
            value: leftValue,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _singleInfoRow(
            label: rightLabel,
            value: rightValue,
          ),
        ),
      ],
    );
  }

  Widget _singleInfoRow({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


}
