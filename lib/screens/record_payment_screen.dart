import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/party_model.dart';
import 'select_party_sheet.dart';
import 'select_invoice_sheet.dart'; // ✅ ADD THIS
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_project/widgets/app_background.dart';


const String baseUrl = "http://127.0.0.1:8000/api";
// const String baseUrl = "http://10.0.2.2:8000/api";



class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  PartyModel? selectedParty;

  int? paymentNumber;


  final TextEditingController amountCtrl = TextEditingController();
  double newPartyBalance = 0;

  String selectedPaymentMode = "Cash";


  // ✅ REQUIRED STATE VARIABLES
  DateTime selectedDate = DateTime.now();
  // int receiptNumber = 5;

  // 👇 ADD THIS
  @override
  void initState() {
    super.initState();
    _loadNextPaymentNumber();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
    DateFormat("dd MMM yyyy").format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Record Payment In"),
        elevation: 0.5,
      ),
        body: AppBackground(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   "Received Payment #$receiptNumber",
                    //   style: const TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),

                    // const Text(
                    //   "Received Payment",
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),

                    Text(
                      paymentNumber == null
                          ? "Received Payment"
                          : "Received Payment #$paymentNumber",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),


                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _openEditSheet(context),
                  child: const Text("EDIT"),
                )
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "PARTY NAME *",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            // ✅ ADD THIS BLOCK HERE
            if (selectedParty != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Current Balance: ₹ ${selectedParty!.openingBalance.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: selectedParty!.openingBalanceType == 'pay'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      selectedParty!.openingBalanceType == 'pay'
                          ? Icons.arrow_upward     // 🔴 YOU PAY
                          : Icons.arrow_downward,  // 🟢 YOU RECEIVE
                      color: selectedParty!.openingBalanceType == 'pay'
                          ? Colors.red
                          : Colors.green,
                      size: 18,
                    ),
                  ],
                ),
              ),

            InkWell(
              onTap: () async {
                final party = await showModalBottomSheet<PartyModel>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  // builder: (_) => const SelectPartySheet(),
                  builder: (_) => SelectPartySheet(
                    primary: Theme.of(context).primaryColor,
                  ),

                );

                if (party != null) {
                  setState(() => selectedParty = party);
                }
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4C3FF0),
                    width: 1.6,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.grey),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        selectedParty?.partyName ?? "Search / Create Party",
                        style: TextStyle(
                          color: selectedParty == null
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),



            const SizedBox(height: 20),

            const Text("AMOUNT *"),
            const SizedBox(height: 6),

            TextField(
              controller: amountCtrl,

              // 🔒 Disable until party selected
              enabled: selectedParty != null,

              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "₹ ",
                hintText: selectedParty == null
                    ? "Select party first"
                    : "Enter amount",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // ✅ OPEN INVOICE SHEET WHEN CLICKED
              onTap: () {
                if (selectedParty == null) return;
                _openInvoiceSheet();
              },

              // ✅ LIVE CALCULATION
              onChanged: (v) {
                final entered = double.tryParse(v) ?? 0;

                if (selectedParty == null) return;

                setState(() {
                  if (selectedParty!.openingBalanceType == 'receive') {
                    // 🟢 Customer pays you → reduce balance
                    newPartyBalance =
                        selectedParty!.openingBalance - entered;
                  } else {
                    // 🔴 You pay supplier → reduce payable
                    newPartyBalance =
                        selectedParty!.openingBalance - entered;
                  }
                });
              },
            ),



            if (selectedParty != null && amountCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "New Party Balance: ",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "₹ ${newPartyBalance.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: newPartyBalance >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),




            const SizedBox(height: 20),

            const Text("PAYMENT MODE"),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: selectedPaymentMode,
              items: const [
                DropdownMenuItem(value: "Cash", child: Text("Cash")),
                DropdownMenuItem(value: "UPI", child: Text("UPI")),
                DropdownMenuItem(value: "Card", child: Text("Card")),
                DropdownMenuItem(value: "Bank", child: Text("Bank")),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedPaymentMode = v);
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),


            const SizedBox(height: 20),

            ListTile(
              title: const Text("Select Bank Account"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),

            const Spacer(),

            // SizedBox(
            //   width: double.infinity,
            //   height: 50,
            //   child: ElevatedButton(
            //     // onPressed: () {},
            //     onPressed: selectedParty == null || amountCtrl.text.isEmpty
            //         ? null
            //         : _savePayment,
            //
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.green,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     child: const Text("Save Payment"),
            //   ),
            // ),
          ],
        ),
      ),
        ),
    );
  }

  // ================== BOTTOM SHEET ==================

  void _openInvoiceSheet() async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SelectInvoiceSheet(
          party: selectedParty!,
          enteredAmount: double.tryParse(amountCtrl.text) ?? 0,

          // ✅ THESE COME FROM RECORD PAYMENT SCREEN
          paymentDate: selectedDate,
          // paymentNumber: receiptNumber,
          paymentMode: selectedPaymentMode,
        );
      },
    );

    if (success == true) {
      Navigator.pop(context); // close RecordPaymentScreen
    }
  }


  Future<void> _loadNextPaymentNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final res = await http.get(
        Uri.parse("$baseUrl/payments/next-number"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode != 200) {
        throw Exception("Failed to fetch payment number");
      }

      final decoded = jsonDecode(res.body);

      setState(() {
        paymentNumber = decoded['next_number'];
      });
    } catch (e) {
      debugPrint("Failed to load payment number: $e");
    }
  }




  Future<void> _savePayment() async {
    final entered = double.tryParse(amountCtrl.text) ?? 0;

    if (entered <= 0) return;

    // Backend will update opening_balance correctly
    // Just send amount

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment saved")),
    );

    Navigator.pop(context);
  }



  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Received Payment Date & Number",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              const Text("Received Payment Date"),
              const SizedBox(height: 6),
              TextField(
                readOnly: true,
                controller: TextEditingController(
                  text: DateFormat("dd MMM yyyy").format(selectedDate),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("SAVE"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
