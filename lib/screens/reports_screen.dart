import 'package:flutter/material.dart';
import 'sales_summary_screen.dart';
import 'stock_summary_screen.dart';
import 'cash_bank_screen.dart';

import 'package:flutter_project/widgets/app_background.dart';


class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const Color purple = Color(0xFF5B4DFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reports",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

        body: AppBackground(
          child: ListView(
            children: [
          _section("Popular"),

          _tile(Icons.description, "Bill wise profit", locked: true),
          // _tile(Icons.currency_rupee, "Sales Summary"),
          _tile(
            Icons.currency_rupee,
            "Sales Summary",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SalesSummaryScreen(),
                ),
              );
            },
          ),

          _tile(Icons.menu_book, "Daybook"),
          _tile(Icons.trending_up, "Profit and Loss"),
          _tile(Icons.people, "Party Statement (Ledger)", locked: true),
          _tile(
            Icons.inventory_2,
            "Stock Summary",
            subtitle: "A summary of price & stock of all items",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockSummaryScreen(),
                ),
              );
            },
          ),

          _tile(Icons.balance, "Balance Sheet"),
          _tile(
            Icons.account_balance,
            "Cash and Bank (All Payments)",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CashBankScreen(),
                ),
              );
            },
          ),


          _section("More"),

          _tile(Icons.people_outline, "Party Reports"),
          _tile(Icons.inventory_2_outlined, "Item Reports"),
          _tile(Icons.receipt_long, "GST Reports"),
          _tile(Icons.shopping_cart, "Transaction Reports"),
        ],
      ),
        ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  // ================= REPORT TILE =================
  Widget _tile(
      IconData icon,
      String title, {
        String? subtitle,
        bool locked = false,
        VoidCallback? onTap,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: purple),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 13))
            : null,
        trailing: locked
            ? const Icon(Icons.lock, size: 18, color: Colors.grey)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: locked ? null : onTap,
      ),
    );
  }

}
