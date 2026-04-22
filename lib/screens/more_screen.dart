import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'parties_screen.dart';
import 'items_screen.dart';
import 'for_you_screen.dart';

import 'package:flutter_project/widgets/app_background.dart';
import 'account_settings_screen.dart';




class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  final Color primary = const Color(0xFF4C3FF0);

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
    // return Scaffold(
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
          );
          return false;
        },
        child: Scaffold(
      // backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () => Navigator.pop(context),
        // ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
            );
          },
        ),
        title: const Text(
          "More",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      // ================= BODY =================
        body: AppBackground(
          child: ListView(
            children: [
          // ---------- BUSINESS HEADER ----------
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "CENTRAL WARE HOUSING CORP. LTD.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "BUSINESS & GST SETTINGS",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.lightBlue,
                  child: Text(
                    "C",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          _tile(Icons.workspace_premium, "myBillBook Subscription Plan"),
          _tile(Icons.help_outline, "Help"),
          _tile(Icons.card_giftcard, "Invite & Earn"),

          _section("Settings"),
          _tile(Icons.receipt_long, "Invoice Settings"),
          // _tile(Icons.person_outline, "Account Settings"),
              _tile(
                Icons.person_outline,
                "Account Settings",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen(),
                    ),
                  );
                },
              ),

              _tile(Icons.notifications_none, "Reminder Settings"),
          _tile(Icons.people_outline, "Manage User"),
          _tile(Icons.restore, "Recover Deleted Invoices"),

          _section("Others"),
          _tile(Icons.search, "GST Rate Finder"),
          _tile(Icons.print, "Buy Printer"),
          _tile(Icons.star_border, "Rate app on Playstore"),
          _tile(Icons.info_outline, "About"),

          const SizedBox(height: 80),
        ],
      ),
        ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PartiesScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ItemsScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ForYouScreen()),
            );
          }
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
            icon: Icon(Icons.star_border),
            label: "For You",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "More",
          ),
        ],
      ),
        ),
    );
  }

  // ================= HELPERS =================
  Widget _section(String title) {
    return Container(
      color: const Color(0xFFF0F1F5),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

//   Widget _tile(IconData icon, String title) {
//     return Container(
//       color: Colors.white,
//       child: ListTile(
//         leading: Icon(icon, color: Colors.deepPurple),
//         title: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.w500),
//         ),
//         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//         onTap: () {},
//       ),
//     );
//   }
// }

  Widget _tile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
