import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/party_model.dart';
import 'party_flow_screens.dart';

const String baseUrl = 'http://127.0.0.1:8000/api';
// const String baseUrl = "http://10.0.2.2:8000/api";


class SelectPartySheet extends StatefulWidget {
  final Color primary;

  const SelectPartySheet({
    super.key,
    required this.primary,
  });


  @override
  State<SelectPartySheet> createState() => _SelectPartySheetState();
}

class _SelectPartySheetState extends State<SelectPartySheet> {
  List<PartyModel> parties = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchParties();
  }

  // ================== FIXED METHOD ==================
  Future<void> fetchParties() async {
    try {
      // 🔑 SAME TOKEN LOGIC AS CreateInvoiceScreen
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (token.isEmpty) {
        throw Exception("Token not found");
      }

      final res = await http.get(
        Uri.parse("$baseUrl/parties"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      // 🔍 DEBUG (you can remove later)
      debugPrint("Party API Status: ${res.statusCode}");
      debugPrint("Party API Body: ${res.body}");

      if (res.statusCode != 200) {
        throw Exception("Unauthorized");
      }

      final decoded = jsonDecode(res.body);

      final List list = decoded['data'] ?? [];

      parties = list
          .map((e) => PartyModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint("Fetch parties error: $e");
      parties = [];
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  "Select Party",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by Mobile Number",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ================= LIST =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : parties.isEmpty
                ? const Center(
              child: Text(
                "No parties found",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: parties.length,
              itemBuilder: (_, i) {
                final p = parties[i];
                return ListTile(
                  onTap: () => Navigator.pop(context, p),
                  title: Text(
                    p.partyName,
                    style:
                    const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "${p.contactNumber ?? ""} • ${p.partyType}",
                  ),
                  // trailing: Text(
                  //   "₹ ${p.openingBalance ?? 0}",
                  //   style: const TextStyle(
                  //       fontWeight: FontWeight.w600),
                  // ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "₹ ${p.openingBalance.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        p.openingBalanceType == 'pay'
                            ? Icons.arrow_upward       // 🔴 YOU PAY
                            : Icons.arrow_downward,    // 🟢 YOU RECEIVE
                        color: p.openingBalanceType == 'pay'
                            ? Colors.red
                            : Colors.green,
                        size: 18,
                      ),
                    ],
                  ),

                );
              },
            ),
          ),

          // ================= CREATE PARTY =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(

                onPressed: () async {
                  final PartyModel? party =
                  await showModalBottomSheet<PartyModel>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (_) => QuickCreatePartySheet(
                      primary: widget.primary,
                    ),
                  );

                  if (party != null && mounted) {
                    Navigator.pop(context, party);
                  }

                },


                icon: const Icon(Icons.add),
                label: const Text("Create Party"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
