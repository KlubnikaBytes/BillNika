import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/party_model.dart';
import 'package:intl/intl.dart';


const String baseUrl = 'http://192.168.1.12:8000/api';
// const String baseUrl = "http://10.0.2.2:8000/api";


class SelectInvoiceSheet extends StatefulWidget {
  final PartyModel party;
  final double enteredAmount;


  // ✅ ADD THESE
  final DateTime paymentDate;
  // final int paymentNumber;
  final String paymentMode;



  const SelectInvoiceSheet({
    super.key,
    required this.party,
    required this.enteredAmount,
    required this.paymentDate,
    // required this.paymentNumber,
    required this.paymentMode,
  });

  @override
  State<SelectInvoiceSheet> createState() => _SelectInvoiceSheetState();
}


class _SelectInvoiceSheetState extends State<SelectInvoiceSheet> {
  final TextEditingController amountCtrl = TextEditingController();

  double newPartyBalance = 0;
  bool loading = true;

  List<Map<String, dynamic>> invoices = [];
  Set<int> selectedInvoiceIds = {};

  Map<int, double> settledAmounts = {}; // invoiceId → settled amount


  @override
  void initState() {
    super.initState();
    amountCtrl.text = widget.enteredAmount.toStringAsFixed(0);
    _recalculate();
    fetchInvoices();
  }

  // ================= FETCH INVOICES =================
  Future<void> fetchInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final res = await http.get(
        Uri.parse("$baseUrl/parties/${widget.party.id}/invoices"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode != 200) {
        throw Exception("Invoice API failed");
      }

      final decoded = jsonDecode(res.body);

      setState(() {
        invoices = List<Map<String, dynamic>>.from(decoded['invoices'] ?? []);
        loading = false;
      });
    } catch (e) {
      debugPrint("Invoice fetch error: $e");
      setState(() => loading = false); // 🔥 STOP SPINNER
    }
  }


  Future<void> _savePayment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    final res = await http.post(
      Uri.parse("$baseUrl/payments"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "party_id": widget.party.id,

        // ✅ COMES FROM RecordPaymentScreen
        "payment_date": DateFormat("yyyy-MM-dd")
            .format(widget.paymentDate),

        // "payment_number": widget.paymentNumber,
        "amount": amount,
        "payment_mode": widget.paymentMode,

        // 👇 ADD THIS
        "invoices": settledAmounts.entries.map((e) => {
          "invoice_id": e.key,
          "amount": e.value,
        }).toList(),
      }),
    );

    if (res.statusCode == 201) {
      Navigator.pop(context, true); // return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment failed")),
      );
    }
  }


  // ================= BALANCE CALC =================

  void _recalculate() {
    double entered = double.tryParse(amountCtrl.text) ?? 0;

    settledAmounts.clear();
    selectedInvoiceIds.clear();

    for (final inv in invoices) {
      if (entered <= 0) break;

      final invId = inv['id'];

      // ✅ FIXED LINE
      final balance = double.parse(inv['balance_amount'].toString());

      final settle = entered >= balance ? balance : entered;

      settledAmounts[invId] = settle;
      selectedInvoiceIds.add(invId);

      entered -= settle;
    }

    setState(() {
      newPartyBalance =
          widget.party.openingBalance - (double.tryParse(amountCtrl.text) ?? 0);
    });
  }



  @override
  Widget build(BuildContext context) {
    final isPay = widget.party.openingBalanceType == 'pay';
    return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // 🔥 KEY LINE
          ),
          child: Column(
        children: [

          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  "Select Invoice",
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

          // ================= AMOUNT =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    text: "AMOUNT",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: " *",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    hintText: "Please enter amount",
                    prefixText: "₹ ",
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF4C3FF0)),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Current Balance: ₹ ${widget.party.openingBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: isPay ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isPay ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPay ? Colors.red : Colors.green,
                        size: 18,
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),


          const Divider(),

          // ================= INVOICES =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text("INVOICE",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                const Text(
                  "Settle outstanding Invoice with the above Payment",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                ...invoices.map((inv) => _invoiceTile(inv)),
              ],
            ),
          ),

          // ================= FOOTER =================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "New Party Balance",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "₹ ${newPartyBalance.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isPay ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isPay ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPay ? Colors.red : Colors.green,
                      size: 18,
                    ),
                  ],
                ),


                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C3FF0), // purple
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
        ),
    );
  }

  // ================= INVOICE TILE =================
  Widget _invoiceTile(Map<String, dynamic> inv) {
    final id = inv['id'];

    final total = double.parse(inv['balance_amount'].toString());
    final settled = settledAmounts[id] ?? 0;
    final remaining = total - settled;

    final isSettled = remaining <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSettled || selectedInvoiceIds.contains(id),
            onChanged: null, // auto controlled
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("#${inv['invoice_number']} • ${inv['invoice_date']}"),

                if (isSettled)
                  Text(
                    "₹ ${settled.toStringAsFixed(2)} Settled ✓",
                    style: const TextStyle(color: Colors.green),
                  )
                else
                  Text(
                    "₹ ${remaining.toStringAsFixed(2)} Remaining",
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          Text(
            "₹ ${double.parse(inv['grand_total'].toString()).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }


}

