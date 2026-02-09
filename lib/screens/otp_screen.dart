import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

// NEW imports for onboarding steps
import 'business_steps/step_city_billing.dart';
import '../models/business_details_model.dart';

import 'package:flutter_project/widgets/app_background.dart';


class OtpScreenArgs {
  final String mobile;
  OtpScreenArgs({required this.mobile});
}

class OtpScreen extends StatefulWidget {
  static const routeName = '/otp';

  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  late String _mobile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
    ModalRoute.of(context)!.settings.arguments as OtpScreenArgs;
    _mobile = args.mobile;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showSnack('Enter valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.verifyOtp(_mobile, otp);

      if (result['success'] == true) {
        _showSnack('OTP Verified');

        // Save token
        final token = result['token'];
        await ApiService.saveToken(token);

        final hasBusiness = result['has_business_details'] ?? false;

        if (!mounted) return;

        if (hasBusiness) {
          Navigator.pushReplacementNamed(
              context, HomeScreen.routeName);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StepCityBilling(
                model: BusinessDetailsModel(),
              ),
            ),
          );
        }
      } else {
        _showSnack(result['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
        body: AppBackground(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            Text(
              'Enter OTP sent to +91 $_mobile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '6-digit code',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
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
                    : const Text('Verify & Continue'),
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
