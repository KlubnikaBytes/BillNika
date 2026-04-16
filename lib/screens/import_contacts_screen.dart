import 'package:flutter/material.dart';
import 'contact_picker_sheet.dart';

class ImportContactsScreen extends StatefulWidget {
  const ImportContactsScreen({super.key});

  @override
  State<ImportContactsScreen> createState() =>
      _ImportContactsScreenState();
}

class _ImportContactsScreenState extends State<ImportContactsScreen> {

  int customerCount = 0;
  int supplierCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Add parties from Contacts",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Column(
        children: [

          // ===== TOP IMAGE SECTION =====
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // 👉 IMAGE (add your asset)
                Image.asset(
                  "assets/contact_import.png", // 🔥 add image here
                  height: 120,
                ),

                const SizedBox(height: 12),

                const Text(
                  "Select contacts & create multiple Parties!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "For quicker and easier experience of creating sales invoices",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ===== CUSTOMER CARD =====
          _card(
            title: "Customer",
            count: customerCount,
            onTap: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ContactPickerSheet(type: "customer"),
              );

              if (result != null) {
                setState(() {
                  customerCount = result;
                });
              }
            },
          ),

          // ===== SUPPLIER CARD =====
          // _card(
          //   title: "Supplier",
          //   count: supplierCount,
          //   onTap: () async {
          //     final result = await Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) =>
          //         const ContactPickerScreen(type: "supplier"),
          //       ),
          //     );
          //
          //     if (result != null) {
          //       setState(() {
          //         supplierCount = result;
          //       });
          //     }
          //   },
          // ),

          const Spacer(),

          // ===== CREATE BUTTON =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: (customerCount == 0 && supplierCount == 0)
                  ? null
                  : () {
                Navigator.pop(context, true); // 🔥 refresh list
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Create Parties",
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ===== CARD UI =====
  Widget _card({
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 18),
            child: Row(
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$count Contacts Selected",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: const [
                    Text(
                      "Select",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 18, color: Colors.deepPurple),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}