// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'services/api_service.dart';
//
// // REMOVE the old screen import
// // import 'screens/business_details_screen.dart';
//
// // NEW imports for multi-step onboarding
// import 'screens/business_steps/step_city_billing.dart';
// import 'models/business_details_model.dart';
//
// import 'screens/phone_login_screen.dart';
// import 'screens/otp_screen.dart';
// import 'screens/home_screen.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // ------------------------------
//   // AUTO LOGIN CHECK
//   // ------------------------------
//   final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString("token");
//
//   Widget initialScreen;
//
//   if (token != null) {
//     try {
//       final profile = await ApiService.getUserProfile();
//       final hasBusiness = profile['has_business_details'] ?? false;
//
//       if (hasBusiness) {
//         initialScreen = const HomeScreen();
//       } else {
//         // 👇 UPDATED — start onboarding wizard
//         initialScreen = StepCityBilling(model: BusinessDetailsModel());
//       }
//     } catch (e) {
//       initialScreen = const PhoneLoginScreen();
//     }
//   } else {
//     initialScreen = const PhoneLoginScreen();
//   }
//
//   runApp(BillmaticApp(initialScreen: initialScreen));
// }
//
// class BillmaticApp extends StatelessWidget {
//   final Widget initialScreen;
//
//   const BillmaticApp({super.key, required this.initialScreen});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Billmatic',
//       debugShowCheckedModeBanner: false,
//
//       // ⭐ UPDATED THEME HERE — NOTHING ELSE CHANGED
//       theme: ThemeData(
//         primaryColor: const Color(0xFF4C3FF0),
//
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF4C3FF0),
//         ),
//
//         scaffoldBackgroundColor: Colors.white,
//         useMaterial3: true,
//
//         // ⭐ BILLBOOK STYLE INPUT FIELDS
//         inputDecorationTheme: InputDecorationTheme(
//           filled: true,
//           fillColor: const Color(0xFFF9F9FC),
//
//           contentPadding:
//           const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide:
//             const BorderSide(color: Color(0xFFE3E3EC), width: 1),
//           ),
//
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide:
//             const BorderSide(color: Color(0xFF4C3FF0), width: 1.6),
//           ),
//
//           labelStyle: const TextStyle(
//             color: Color(0xFF787885),
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//           ),
//
//           hintStyle: const TextStyle(
//             color: Color(0xFF9B9CA3),
//             fontSize: 14,
//           ),
//         ),
//       ),
//
//       // 👇 UPDATED — starting screen
//       home: initialScreen,
//
//       routes: {
//         PhoneLoginScreen.routeName: (_) => const PhoneLoginScreen(),
//         OtpScreen.routeName: (_) => const OtpScreen(),
//
//         // 👇 UPDATED — Replaced old route
//         "/business-details": (_) =>
//             StepCityBilling(model: BusinessDetailsModel()),
//
//         HomeScreen.routeName: (_) => const HomeScreen(),
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

// REMOVE the old screen import
// import 'screens/business_details_screen.dart';

// NEW imports for multi-step onboarding
import 'screens/business_steps/step_city_billing.dart';
import 'models/business_details_model.dart';

import 'screens/phone_login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';
import 'package:media_store_plus/media_store_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ADD THIS LINE (VERY IMPORTANT)
  await MediaStore.ensureInitialized();
  // ✅ REQUIRED (fixes your current error)
  MediaStore.appFolder = "Billnika";


  // ------------------------------
  // AUTO LOGIN CHECK
  // ------------------------------
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  Widget initialScreen;

  if (token != null) {
    // try {
    //   final profile = await ApiService.getUserProfile();
    //   final hasBusiness = profile['has_business_details'] ?? false;
    //
    //   if (hasBusiness) {
    //     initialScreen = const HomeScreen();
    //   } else {
    //     // 👇 UPDATED — start onboarding wizard
    //     initialScreen = StepCityBilling(model: BusinessDetailsModel());
    //   }
    // } catch (e) {
    //   initialScreen = const PhoneLoginScreen();
    // }
    try {
      // ✅ FIRST CHECK LOCAL STORAGE
      final localHasBusiness = prefs.getBool('has_business_details');

      if (localHasBusiness != null) {
        if (localHasBusiness) {
          initialScreen = const HomeScreen();
        } else {
          initialScreen =
              StepCityBilling(model: BusinessDetailsModel());
        }
      } else {
        // ✅ FALLBACK TO API
        final profile = await ApiService.getUserProfile();
        final hasBusiness = profile['has_business_details'] ?? false;

        // SAVE LOCALLY
        await prefs.setBool('has_business_details', hasBusiness);

        if (hasBusiness) {
          initialScreen = const HomeScreen();
        } else {
          initialScreen =
              StepCityBilling(model: BusinessDetailsModel());
        }
      }
    } catch (e) {
      // ⚠️ If API fails → DO NOT break login → fallback to login
      initialScreen = const PhoneLoginScreen();
    }
  } else {
    initialScreen = const PhoneLoginScreen();
  }

  runApp(BillmaticApp(initialScreen: initialScreen));
}

class BillmaticApp extends StatelessWidget {
  final Widget initialScreen;

  const BillmaticApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billmatic',
      debugShowCheckedModeBanner: false,

      // ⭐ UPDATED THEME HERE — NOTHING ELSE CHANGED
      theme: ThemeData(
        primaryColor: const Color(0xFF4C3FF0),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C3FF0),
        ),

        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,

        // ⭐ BILLBOOK STYLE INPUT FIELDS
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9F9FC),

          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFFE3E3EC), width: 1),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF4C3FF0), width: 1.6),
          ),

          labelStyle: const TextStyle(
            color: Color(0xFF787885),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),

          hintStyle: const TextStyle(
            color: Color(0xFF9B9CA3),
            fontSize: 14,
          ),
        ),
      ),

      // 👇 UPDATED — starting screen
      home: initialScreen,

      routes: {
        PhoneLoginScreen.routeName: (_) => const PhoneLoginScreen(),
        OtpScreen.routeName: (_) => const OtpScreen(),

        // 👇 UPDATED — Replaced old route
        "/business-details": (_) =>
            StepCityBilling(model: BusinessDetailsModel()),

        HomeScreen.routeName: (_) => const HomeScreen(),
      },
    );
  }
}
