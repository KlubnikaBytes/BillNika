import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://192.168.1.12:8000/api';

class ContactPickerSheet extends StatefulWidget {
  final String type;

  const ContactPickerSheet({super.key, required this.type});

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {

  List<Contact> contacts = [];
  List<Contact> selected = [];
  List<Contact> filtered = [];

  bool loading = true;
  bool creating = false;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  // ================= LOAD CONTACTS =================
  Future<void> loadContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      setState(() => loading = false);
      return;
    }

    final data = await FlutterContacts.getContacts(withProperties: true);

    setState(() {
      contacts = data;
      filtered = data;
      loading = false;
    });
  }

  // ================= SEARCH =================
  void search(String value) {
    setState(() {
      filtered = contacts.where((c) {
        return c.displayName.toLowerCase().contains(value.toLowerCase());
      }).toList();
    });
  }

  // ================= TOGGLE =================
  void toggle(Contact c) {
    setState(() {
      if (selected.contains(c)) {
        selected.remove(c);
      } else {
        selected.add(c);
      }
    });
  }

  // ================= CREATE PARTIES =================
  Future<void> createParties() async {
    setState(() => creating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      for (var c in selected) {
        final name = c.displayName;

        if (c.phones.isEmpty) continue;

        String phone = c.phones.first.number;

        // 🔥 clean phone
        phone = phone.replaceAll(RegExp(r'\s+'), '');

        try {
          await http.post(
            Uri.parse("$baseUrl/parties"),
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "party_name": name,
              "contact_number": phone,
              "party_type": widget.type,
              "opening_balance": 0,
              "opening_balance_type": "receive",
            }),
          );
        } catch (e) {
          debugPrint("Single create error: $e");
        }
      }

    } catch (e) {
      debugPrint("Create parties error: $e");
    }

    setState(() => creating = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      child: Column(
        children: [

          // ===== HEADER =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  "Select ${widget.type.capitalize()}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // ===== SEARCH =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              onChanged: search,
              decoration: InputDecoration(
                hintText: "Search by Contact Name",
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

          // ===== LIST =====
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final phone = c.phones.isNotEmpty
                    ? c.phones.first.number
                    : "";

                final isSelected = selected.contains(c);

                return ListTile(
                  onTap: () => toggle(c),
                  title: Text(c.displayName),
                  subtitle: Text(phone),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (_) => toggle(c),
                  ),
                );
              },
            ),
          ),

          // ===== BUTTON =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: (selected.isEmpty || creating)
                  ? null
                  : () async {
                await createParties(); // 🔥 CREATE API
                Navigator.pop(context, selected.length);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
              ),
              child: creating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                selected.isEmpty
                    ? "Select Contacts"
                    : "Create ${selected.length} Parties",
              ),
            ),
          )
        ],
      ),
    );
  }
}

// helper
extension Cap on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}