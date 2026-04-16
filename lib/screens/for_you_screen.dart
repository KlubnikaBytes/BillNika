import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'more_screen.dart';
import 'parties_screen.dart';
import 'items_screen.dart';
import 'home_screen.dart';
import 'calculator_screen.dart';
import 'gst_filing_screen.dart';

import 'package:flutter_project/widgets/app_background.dart';


class ForYouScreen extends StatelessWidget {
  const ForYouScreen({super.key});

  static const Color purple = Color(0xFF5B4DFF);

  void handleBottomNavTap(BuildContext context, int index) {
    Widget target;

    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const PartiesScreen();
        break;
      case 2:
        target = const ItemsScreen();
        break;
      case 3:
        target = const ForYouScreen();
        break;
      case 4:
        target = const MoreScreen();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => target),
          (route) => false, // 🔥 prevents stack piling
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "For You",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      // ================= BODY =================
        body: AppBackground(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

          // ================= HERO =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7F4DFF), Color(0xFF9F6BFF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "For You ✨",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Features designed specially for your business",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= RECOMMENDED =================
          const Text(
            "Recommended for you",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _RecommendTile(Icons.receipt_long, "e-Invoice"),
                _RecommendTile(Icons.event_available, "Staff\nAttendance & Payroll"),
                _RecommendTile(Icons.desktop_windows, "Desktop\nSoftware"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= MARKETING =================
          _section("Marketing & Sales"),
          _iconGrid([
            _iconTile(context,FontAwesomeIcons.whatsapp, "WhatsApp\nMarketing"),
            _iconTile(context,Icons.card_giftcard, "Reward\nPoints"),
            _iconTile(context,Icons.event, "Notes &\nAppointments"),
            _iconTile(context,Icons.store, "Online\nStore"),
          ]),

          const SizedBox(height: 20),

          // ================= ACCOUNTING =================
          _section("Accounting"),
          _iconGrid([
            _iconTile(context,Icons.receipt_long, "GST\nFiling"),
            _iconTile(context,Icons.balance, "Balance\nSheet"),
            _iconTile(context,Icons.autorenew, "Automated\nBills"),
            _iconTile(context,Icons.share, "CA Reports\nSharing"),
          ]),

          const SizedBox(height: 20),

          // ================= BUSINESS =================
          _section("Business Efficiency"),
          _iconGrid([
            _iconTile(context, Icons.calculate, "Smart\nCalculator"),
          ]),
        ],
      ),
        ),


      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, // For You
        selectedItemColor: purple,
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          handleBottomNavTap(context, index); // ✅ THIS WAS MISSING
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Parties",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: "Items",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: "For You",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "More",
          ),
        ],
      ),

    );
  }

  // ================= SECTION =================
  static Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ================= GRID =================
  static Widget _iconGrid(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }

  // static Widget _iconTile(IconData icon, String label) {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       CircleAvatar(
  //         radius: 26,
  //         backgroundColor: purple.withOpacity(0.1),
  //         child: icon is IconData
  //             ? Icon(icon, color: purple)
  //             : FaIcon(icon, color: purple),
  //       ),
  //       const SizedBox(height: 6),
  //       Text(
  //         label,
  //         textAlign: TextAlign.center,
  //         style: const TextStyle(fontSize: 12),
  //       ),
  //     ],
  //   );
  // }

  static Widget _iconTile(
      BuildContext context,
      IconData icon,
      String label,
      ) {
    return GestureDetector(
      onTap: () {
        // ✅ ONLY FOR CALCULATOR
        // ✅ GST Filing
        if (label.contains("GST")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GstFilingScreen(),
            ),
          );
        }

        // ✅ Calculator
        else if (label.contains("Calculator")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CalculatorScreen(),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: purple.withOpacity(0.1),
            child: icon is IconData
                ? Icon(icon, color: purple)
                : FaIcon(icon, color: purple),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

}

// ================= RECOMMENDED TILE =================
class _RecommendTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RecommendTile(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: ForYouScreen.purple, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
