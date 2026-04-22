import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cash_bank_details_screen.dart';
import 'package:flutter_project/widgets/app_background.dart';



const String baseUrl = 'http://192.168.1.12:8000/api';
// const String baseUrl = "http://10.0.2.2:8000/api";


class CashBankScreen extends StatefulWidget {
  const CashBankScreen({super.key});

  @override
  State<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends State<CashBankScreen> {
  double totalBalance = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCashBank();
  }

  Future<void> fetchCashBank() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/cash-bank-summary"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final decoded = jsonDecode(res.body);

    setState(() {
      totalBalance =
          (decoded['data']['cash_in_hand'] ?? 0).toDouble();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Cash & Bank"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),

        body: AppBackground(
          child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 30),

          // ================= TOTAL BALANCE =================
          Text(
            "Total Cash & Bank Balance",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            "₹ ${totalBalance.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // VIEW DETAILS
          // Text(
          //   "View Details →",
          //   style: TextStyle(
          //     color: Colors.deepPurple,
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),

          // VIEW DETAILS
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // builder: (_) => const CashBankDetailsScreen(),
                  builder: (_) => const CashBankDetailsScreen(
                    title: "Total Cash & Bank Balance",
                    type: "all",
                  ),

                ),
              );
            },
            child: const Text(
              "View Details →",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),


          const SizedBox(height: 24),

          // ================= CASH IN HAND =================

          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CashBankDetailsScreen(
                    title: "Cash in Hand",
                    type: "cash",
                    currentBalance: totalBalance,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cash in Hand",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "₹ ${totalBalance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),



          const SizedBox(height: 20),

          // ================= BANK / ONLINE =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "Bank / Online",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  "+ Add New Bank",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    "Unlinked Payments",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  "₹ 0.0",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ================= SMALL ADJUST BALANCE BUTTON =================
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

}
