import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';

import 'package:flutter_project/widgets/app_background.dart';


class PhoneLoginScreen extends StatefulWidget {
  static const routeName = '/phone-login';

  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _mobileController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _secondsLeft = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final mobile = _mobileController.text.trim();

    if (mobile.length != 10) {
      _showSnack('Please enter valid 10-digit mobile number');
      return;
    }

    if (_secondsLeft > 0) {
      _showSnack('Please wait $_secondsLeft sec before resending OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.sendOtp(mobile);

      if (result['success'] == true) {
        _showSnack('OTP sent to $mobile');
        final cooldown = (result['cooldown_seconds'] ?? 30) as int;
        _startCooldown(cooldown);

        if (mounted) {
          Navigator.pushNamed(
            context,
            OtpScreen.routeName,
            arguments: OtpScreenArgs(mobile: mobile),
          );
        }
      } else {
        _showSnack(result['message']?.toString() ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
        body: AppBackground(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Enter Mobile Number',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We’ll send a code to your phone number to verify it. "
                  "Keep this number same as your WhatsApp number.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Text(
                    '+91 ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '8987693653',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  _secondsLeft > 0
                      ? 'Continue ($_secondsLeft)'
                      : 'Continue',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
        ),
    );
  }
}
