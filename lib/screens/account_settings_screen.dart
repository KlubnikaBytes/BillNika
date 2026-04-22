import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'phone_login_screen.dart';

const String baseUrl = 'http://192.168.1.12:8000/api';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool appLockEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Account Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------- NAME --------
          const Text("Name", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          _inputBox(
            child: const Text(
              "Your Name",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 16),

          // -------- MOBILE --------
          const Text("Mobile Number",
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          _inputBox(
            color: const Color(0xFFF0F1F5),
            child: const Text("6205857707"),
          ),

          const SizedBox(height: 24),

          // -------- OPTIONS --------
          _tile(Icons.card_giftcard, "Referral Code"),
          _divider(),
          _tile(Icons.translate, "Language"),
          _divider(),

          // -------- APP LOCK --------
          Container(
            color: Colors.white,
            child: SwitchListTile(
              secondary:
              const Icon(Icons.lock_outline, color: Colors.deepPurple),
              title: const Text(
                "App Lock",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                "Secure your account by using existing phone password or fingerprint",
                style: TextStyle(fontSize: 12),
              ),
              value: appLockEnabled,
              onChanged: (value) {
                setState(() {
                  appLockEnabled = value;
                });
              },
              activeColor: Colors.deepPurple,
            ),
          ),

          _divider(),

          // -------- DATA BACKUP --------
          _tile(
            Icons.cloud_done_outlined,
            "Data Backup: ON",
            subtitle:
            "No need to worry - your bills and data are auto-saved online, even if your phone is lost.\n\nLast Backup at: Thu, 05 Feb 2026 05:10 pm",
          ),

          const SizedBox(height: 32),

          // -------- LOGOUT --------
          GestureDetector(
            onTap: _showLogoutSheet,
            child: const Text(
              "Log Out",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    try {
      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
    } catch (e) {
      debugPrint("Logout API error: $e");
    }

    await prefs.remove('token');
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      PhoneLoginScreen.routeName,
          (route) => false,
    );
  }

  // ================= HELPERS =================

  Widget _inputBox({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _tile(IconData icon, String title, {String? subtitle}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle:
        subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.grey.shade300);
  }

  // ================= LOGOUT BOTTOM SHEET =================
  void _showLogoutSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Log Out",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text("Are you sure you want to Logout?"),
              const SizedBox(height: 20),

              // NO
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),

              const SizedBox(height: 10),

              // YES
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                child: const Text("Yes"),
              ),
            ],
          ),
        );
      },
    );
  }
}
