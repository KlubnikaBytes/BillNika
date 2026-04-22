
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // ✅ ADDED
import '../models/party_model.dart';
import 'party_flow_screens.dart';

const String baseUrl = 'http://192.168.1.12:8000/api';

class SelectPartySheet extends StatefulWidget {
  final Color primary;

  const SelectPartySheet({
    super.key,
    required this.primary,
  });

  @override
  State<SelectPartySheet> createState() => _SelectPartySheetState();
}

class _SelectPartySheetState extends State<SelectPartySheet>
    with SingleTickerProviderStateMixin {

  List<PartyModel> parties = [];
  bool loading = true;

  List<Contact> contacts = [];
  bool contactsLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    fetchParties();

    _tabController = TabController(length: 2, vsync: this);

    // 👉 Load contacts only when tab clicked
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      if (_tabController.index == 1 && contacts.isEmpty) {
        loadContacts();
      }
    });
  }

  // ================== FETCH PARTIES ==================
  Future<void> fetchParties() async {
    try {
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
      final List list = decoded['data'] ?? [];

      parties = list.map((e) => PartyModel.fromJson(e)).toList();

    } catch (e) {
      debugPrint("Fetch parties error: $e");
      parties = [];
    }

    setState(() => loading = false);
  }

  // ================== LOAD CONTACTS ==================

  Future<void> loadContacts() async {
    setState(() => contactsLoading = true);

    // 🔥 Step 1: check permission FIRST
    if (!await FlutterContacts.requestPermission()) {
      setState(() => contactsLoading = false);
      return;
    }

    try {
      // 🔥 Step 2: small delay (IMPORTANT FIX)
      await Future.delayed(const Duration(milliseconds: 300));

      final data = await FlutterContacts.getContacts(
        withProperties: true,
      );

      setState(() {
        contacts = data;
        contactsLoading = false;
      });

    } catch (e) {
      debugPrint("Contacts error: $e");
      setState(() => contactsLoading = false);
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [

          // HEADER
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

          // SEARCH
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

          const SizedBox(height: 10),

          // ================== TABS ==================
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4C3FF0),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFF4C3FF0),
            tabs: const [
              Tab(text: "All Parties"),
              Tab(text: "Contacts"),
            ],
          ),

          const SizedBox(height: 6),

          // ================== CONTENT ==================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildPartyList(),
                _buildContactsList(),
              ],
            ),
          ),

          // ================== CREATE PARTY ==================
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
                    builder: (_) =>
                        QuickCreatePartySheet(primary: widget.primary),
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

  // ================== PARTY LIST ==================
  Widget _buildPartyList() {
    if (parties.isEmpty) {
      return const Center(child: Text("No parties found"));
    }

    return ListView.builder(
      itemCount: parties.length,
      itemBuilder: (_, i) {
        final p = parties[i];

        return ListTile(
          onTap: () => Navigator.pop(context, p),
          title: Text(
            p.partyName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text("${p.contactNumber ?? ""} • ${p.partyType}"),
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
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: p.openingBalanceType == 'pay'
                    ? Colors.red
                    : Colors.green,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }

  // ================== CONTACT LIST ==================
  Widget _buildContactsList() {
    // 🔥 AUTO LOAD WHEN UI OPENS (REAL FIX)
    if (_tabController.index == 1 &&
        contacts.isEmpty &&
        !contactsLoading) {
      loadContacts();
    }

    if (contactsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contacts.isEmpty) {
      return const Center(child: Text("No contacts found"));
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (_, i) {
        final c = contacts[i];

        final name = c.displayName;
        final phone =
        c.phones.isNotEmpty ? c.phones.first.number : "No Number";

        return ListTile(
          title: Text(name),
          subtitle: Text(phone),
          // onTap: () {
          //   final party = PartyModel(
          //     id: 0,
          //     partyName: name,
          //     contactNumber: phone,
          //     partyType: "customer",
          //     openingBalance: 0,
          //     openingBalanceType: "receive",
          //   );
          //
          //   Navigator.pop(context, party);
          // },
            onTap: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token') ?? "";

                final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');

                // 🔥 1. CHECK EXISTING PARTY
                final existing = parties.firstWhere(
                      (p) =>
                  (p.contactNumber ?? '').replaceAll(RegExp(r'\s+'), '') ==
                      cleanPhone,
                  orElse: () => PartyModel(
                    id: -1,
                    partyName: '',
                    contactNumber: '',
                    partyType: 'customer',
                    openingBalance: 0,
                    openingBalanceType: 'receive',
                  ),
                );

                if (existing.id != -1) {
                  Navigator.pop(context, existing);
                  return;
                }

                // 🔥 2. CREATE PARTY API
                final res = await http.post(
                  Uri.parse("$baseUrl/parties"),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode({
                    "party_name": name,
                    "contact_number": cleanPhone,
                    "party_type": "customer",
                    "opening_balance": 0,
                    "opening_balance_type": "receive",
                  }),
                );

                if (res.statusCode == 200 || res.statusCode == 201) {
                  final data = jsonDecode(res.body);

                  final party = PartyModel.fromJson(data['data']);

                  if (mounted) {
                    Navigator.pop(context, party);
                  }
                } else {
                  debugPrint("Create party failed: ${res.body}");
                }

              } catch (e) {
                debugPrint("Contact tap error: $e");
              }
            }
        );
      },
    );
  }
}
