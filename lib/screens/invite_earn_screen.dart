import 'package:flutter/material.dart';
import 'InviteContactsSheet.dart';

class InviteEarnScreen extends StatelessWidget {
  const InviteEarnScreen({super.key});

  final Color primary = const Color(0xFF4C3FF0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Invite & Earn"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.info_outline),
          )
        ],
      ),

      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF4C3FF0)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Share app with other businessmen",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  "You earn ₹501, they get 15% Off",
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ================= REFERRAL BOX =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Your referral code",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDEBFF),
                      foregroundColor: const Color(0xFF4C3FF0),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text("Share Code"),
                  )
                ],
              ),
            ),
          ),

          // ================= HOW IT WORKS =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "How it works:",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.share, color: Colors.purple),
                      SizedBox(width: 10),
                      Expanded(child: Text("Share the referral code")),
                    ],
                  ),
                  SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.download, color: Colors.purple),
                      SizedBox(width: 10),
                      Expanded(child: Text("They install & buy plan")),
                    ],
                  ),
                  SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.purple),
                      SizedBox(width: 10),
                      Expanded(child: Text("You earn ₹501 reward")),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ================= BUTTON =================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const InviteContactsSheet(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text(
                    "Invite Friends",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}