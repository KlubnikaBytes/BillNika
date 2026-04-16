import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteContactsSheet extends StatefulWidget {
  const InviteContactsSheet({super.key});

  @override
  State<InviteContactsSheet> createState() => _InviteContactsSheetState();
}

class _InviteContactsSheetState extends State<InviteContactsSheet> {
  List<Contact> contacts = [];
  List<Contact> filtered = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    final granted = await FlutterContacts.requestPermission();

    if (!granted) {
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

  Future<void> openWhatsApp(String phone, String name) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    if (!cleanPhone.startsWith('91')) {
      cleanPhone = "91$cleanPhone";
    }

    final message = Uri.encodeComponent(
      "Hello $name 👋\n\n"
          "I use this Billnika app to manage my business.\n"
          "You will get 15% OFF 🎉\n\n"
          "Download now:\n"
          "https://yourapp.link\n\n"
          "Use my referral code: ABC123",
    );

    // ✅ METHOD 1 (BEST)
    final Uri whatsappUrl = Uri.parse(
      "whatsapp://send?phone=$cleanPhone&text=$message",
    );

    try {
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // 🔁 FALLBACK (browser)
      final Uri webUrl = Uri.parse(
        "https://wa.me/$cleanPhone?text=$message",
      );

      await launchUrl(
        webUrl,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _filter(String value) {
    setState(() {
      filtered = contacts.where((c) {
        final name = c.displayName.toLowerCase();
        return name.contains(value.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    "Invite Friends",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: _filter,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search by Contact Name",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // LIST
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final c = filtered[index];

                  final name = c.displayName;
                  final phone = c.phones.isNotEmpty
                      ? c.phones.first.number
                      : "";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors
                          .primaries[index % Colors.primaries.length]
                          .shade300,
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text(phone),

                    trailing: ElevatedButton(
                      onPressed: () {
                        if (phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No phone number")),
                          );
                          return;
                        }

                        openWhatsApp(phone, name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C3FF0),
                        foregroundColor: Colors.white, // ✅ ADD THIS
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Invite"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}