// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'create_invoice_screen.dart'; // for PartyModel & baseUrl
//
// import '../models/party_model.dart';
//
// import 'package:flutter_project/widgets/app_background.dart';
//
//
// // --------------------------------------------------
// // 1. Select Party bottom sheet
// // --------------------------------------------------
//
// class SelectPartySheet extends StatefulWidget {
//   final Color primary;
//
//   const SelectPartySheet({super.key, required this.primary});
//
//   @override
//   State<SelectPartySheet> createState() => _SelectPartySheetState();
// }
//
// class _SelectPartySheetState extends State<SelectPartySheet>
//     with SingleTickerProviderStateMixin {
//   List<PartyModel> parties = [];
//   List<PartyModel> filtered = [];
//   bool loading = true;
//   String search = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadParties();
//   }
//
//   Future<void> _loadParties() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? "";
//
//       final res = await http.get(
//         Uri.parse('$baseUrl/parties'),
//         headers: {
//           "Accept": "application/json",
//           "Authorization": "Bearer $token",
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final list = (data['data'] as List)
//             .map((e) => PartyModel.fromJson(e))
//             .toList();
//         setState(() {
//           parties = list;
//           filtered = list;
//           loading = false;
//         });
//       } else {
//         setState(() => loading = false);
//       }
//     } catch (e) {
//       setState(() => loading = false);
//     }
//   }
//
//   void _filter(String value) {
//     setState(() {
//       search = value;
//       filtered = parties
//           .where((p) =>
//           p.partyName.toLowerCase().contains(value.toLowerCase()))
//           .toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final primary = widget.primary;
//
//     return SafeArea(
//       child: DefaultTabController(
//         length: 2,
//         child: Padding(
//           padding:
//           EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//           child: SizedBox(
//             height: MediaQuery.of(context).size.height * 0.8,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // header
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//                   child: Row(
//                     children: [
//                       const Text(
//                         "Select Party",
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.pop(context),
//                       )
//                     ],
//                   ),
//                 ),
//
//                 // search
//                 Padding(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F5F9),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.search, color: Colors.black45),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextField(
//                             onChanged: _filter,
//                             decoration: const InputDecoration(
//                               border: InputBorder.none,
//                               hintText: "Search by Party Name",
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // tabs
//                 const TabBar(
//                   labelColor: Color(0xFF4C3FF0),
//                   unselectedLabelColor: Colors.black54,
//                   indicatorColor: Color(0xFF4C3FF0),
//                   tabs: [
//                     Tab(text: "All Parties"),
//                     Tab(text: "Contacts"),
//                   ],
//                 ),
//
//                 const SizedBox(height: 4),
//
//                 Expanded(
//                   child: loading
//                       ? const Center(
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                       : TabBarView(
//                     children: [
//                       _buildPartyList(filtered),
//                       _buildPartyList(filtered), // same for now
//                     ],
//                   ),
//                 ),
//
//                 // create party button
//                 // create party button
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   child: SizedBox(
//                     width: double.infinity,
//                     height: 46, // smaller height like screenshot
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primary,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(22), // smaller radius
//                         ),
//                         padding: const EdgeInsets.symmetric(horizontal: 14),
//                       ),
//                       onPressed: () async {
//                         final PartyModel? party =
//                         await showModalBottomSheet<PartyModel>(
//                           context: context,
//                           isScrollControlled: true,
//                           shape: const RoundedRectangleBorder(
//                             borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
//                           ),
//                           builder: (_) => QuickCreatePartySheet(primary: primary),
//                         );
//
//                         if (party != null && mounted) {
//                           Navigator.pop(context, party);
//                         }
//                       },
//
//                       icon: const Icon(
//                         Icons.add,
//                         color: Colors.white, // white icon
//                         size: 22,
//                       ),
//
//                       label: const Text(
//                         "Create Party",
//                         style: TextStyle(
//                           color: Colors.white, // white text
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPartyList(List<PartyModel> list) {
//     if (list.isEmpty) {
//       return const Center(
//         child: Text("No parties found"),
//       );
//     }
//     return ListView.separated(
//       padding: const EdgeInsets.only(top: 8),
//       itemCount: list.length,
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemBuilder: (context, index) {
//         final p = list[index];
//         return ListTile(
//           onTap: () => Navigator.pop(context, p),
//           title: Text(p.partyName),
//           subtitle: Text(
//             "${p.contactNumber ?? ''} • ${p.partyType ?? 'Customer'}",
//           ),
//           // trailing: const Icon(Icons.arrow_downward, color: Colors.green),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 "₹ ${p.openingBalance?.toStringAsFixed(0) ?? 0}",
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(width: 6),
//               Icon(
//                 p.openingBalanceType == 'pay'
//                     ? Icons.arrow_upward
//                     : Icons.arrow_downward,
//                 color: p.openingBalanceType == 'pay'
//                     ? Colors.red
//                     : Colors.green,
//                 size: 18,
//               ),
//             ],
//           ),
//
//
//         );
//       },
//     );
//   }
// }
//
// // --------------------------------------------------
// // 2. Quick Create Party bottom sheet
// // --------------------------------------------------
//
// class QuickCreatePartySheet extends StatefulWidget {
//   final Color primary;
//
//   const QuickCreatePartySheet({super.key, required this.primary});
//
//   @override
//   State<QuickCreatePartySheet> createState() => _QuickCreatePartySheetState();
// }
//
// class _QuickCreatePartySheetState extends State<QuickCreatePartySheet> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _partyName = TextEditingController();
//   final TextEditingController _contactNumber = TextEditingController();
//   bool _saving = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final primary = widget.primary;
//
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom, // 🔥 KEYBOARD FIX
//       ),
//       child: SafeArea(
//         child: SingleChildScrollView( // 🔥 allows sheet to move/scroll
//           child: Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
//             ),
//             padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//
//                 // ================= HEADER =================
//                 Row(
//                   children: [
//                     const Text(
//                       "Create Party",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const Spacer(),
//                     InkWell(
//                       onTap: () => Navigator.pop(context),
//                       child: const Icon(Icons.close, size: 26),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 22),
//
//                 // ================= FORM =================
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//
//                       // ---------- Party Name ----------
//                       const Text(
//                         "Party Name *",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.black54,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//
//                       Container(
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF5F5FF),
//                           borderRadius: BorderRadius.circular(14),
//                           border: Border.all(color: const Color(0xFFE0E0F3)),
//                         ),
//                         padding: const EdgeInsets.symmetric(horizontal: 14),
//                         child: TextFormField(
//                           controller: _partyName,
//                           textInputAction: TextInputAction.next, // ✅ UX improvement
//                           decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             hintText: "Ex: Ankit Mishra",
//                             hintStyle: TextStyle(color: Colors.black38),
//                           ),
//                           validator: (v) =>
//                           v == null || v.trim().isEmpty ? "Required" : null,
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       // ---------- Contact Number ----------
//                       const Text(
//                         "Contact Number",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.black54,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//
//                       Container(
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF5F5FF),
//                           borderRadius: BorderRadius.circular(14),
//                           border: Border.all(color: const Color(0xFFE0E0F3)),
//                         ),
//                         padding: const EdgeInsets.symmetric(horizontal: 14),
//                         child: TextFormField(
//                           controller: _contactNumber,
//                           keyboardType: TextInputType.phone,
//                           textInputAction: TextInputAction.done, // ✅ Done button
//                           decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             hintText: "Ex: 9876543210",
//                             hintStyle: TextStyle(color: Colors.black38),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 28),
//
//                 // ================= ACTION ROW =================
//                 Row(
//                   children: [
//
//                     // ---------- Add More Details ----------
//                     InkWell(
//                       onTap: () async {
//                         final party = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => CreateNewPartyScreen(
//                               primary: primary,
//                               prefillName: _partyName.text.trim(),
//                               prefillPhone: _contactNumber.text.trim(),
//                             ),
//                           ),
//                         );
//
//                         if (party != null && mounted) {
//                           Navigator.of(context).pop(party);
//                         }
//                       },
//                       child: Text(
//                         "Add more details\nGST, Address, etc.",
//                         style: TextStyle(
//                           color: primary,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//
//                     const Spacer(),
//
//                     // ---------- Save Button ----------
//                     SizedBox(
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primary,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(horizontal: 32),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         onPressed: _saving ? null : _saveQuickParty,
//                         child: _saving
//                             ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                             : const Text(
//                           "Save Party",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Future<void> _saveQuickParty() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _saving = true);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? "";
//
//       final body = {
//         "party_name": _partyName.text.trim(),
//         "contact_number": _contactNumber.text.trim(),
//         "party_type": "customer",
//
//         // ✅ REQUIRED BY BACKEND
//         "opening_balance": 0,
//         "opening_balance_type": "receive",
//       };
//
//
//       final res = await http.post(
//         Uri.parse('$baseUrl/parties'),
//         headers: {
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       );
//
//       if (res.statusCode == 200 || res.statusCode == 201) {
//         final json = jsonDecode(res.body);
//         final party = PartyModel.fromJson(json['data']);
//
//         // ✅ THIS LINE IS THE FIX
//         if (mounted) {
//           Navigator.of(context).pop(party);
//         }
//       }
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }
//
// }
//
// // --------------------------------------------------
// // 3. Full "Create New Party" screen (LABELS OUTSIDE BOX)
// // --------------------------------------------------
//
// class CreateNewPartyScreen extends StatefulWidget {
//   final Color primary;
//   final PartyModel? initialParty;
//
//   final String? prefillName;
//   final String? prefillPhone;
//
//   const CreateNewPartyScreen({
//     super.key,
//     required this.primary,
//     this.initialParty,
//     this.prefillName,
//     this.prefillPhone,
//   });
//
//   @override
//   State<CreateNewPartyScreen> createState() => _CreateNewPartyScreenState();
// }
//
// class _CreateNewPartyScreenState extends State<CreateNewPartyScreen>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _partyName = TextEditingController();
//   final TextEditingController _contactNumber = TextEditingController();
//   String partyType = "customer";
//
//   final TextEditingController _gstNumber = TextEditingController();
//   final TextEditingController _panNumber = TextEditingController();
//   BillingAddress? billingAddress;
//
//   final TextEditingController _openingBalance = TextEditingController();
//   final TextEditingController _creditPeriodDays = TextEditingController();
//   final TextEditingController _creditLimit = TextEditingController();
//
//   final TextEditingController _partyCategoryName = TextEditingController();
//   final TextEditingController _contactPersonName = TextEditingController();
//   DateTime? _dob;
//
//   bool _saving = false;
//
//   String? selectedCreditLabel = "Select Days";
//   int? selectedCreditDays;
//
//   String openingBalanceType = 'receive'; // default
//
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   if (widget.initialParty != null) {
//   //     _partyName.text = widget.initialParty!.partyName;
//   //     _contactNumber.text = widget.initialParty!.contactNumber ?? '';
//   //     partyType = widget.initialParty!.partyType ?? 'customer';
//   //   } else {
//   //     _partyName.text = widget.prefillName ?? "";
//   //     _contactNumber.text = widget.prefillPhone ?? "";
//   //   }
//   // }
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //
//   //   final p = widget.initialParty;
//   //
//   //   if (p != null) {
//   //     // BASIC
//   //     _partyName.text = p.partyName;
//   //     _contactNumber.text = p.contactNumber ?? '';
//   //     partyType = p.partyType ?? 'customer';
//   //
//   //     // GST & PAN
//   //     _gstNumber.text = p.gstNumber ?? '';
//   //     _panNumber.text = p.panNumber ?? '';
//   //
//   //     // OPENING BALANCE
//   //     _openingBalance.text = p.openingBalance?.toString() ?? '';
//   //     openingBalanceType = p.openingBalanceType ?? 'receive';
//   //
//   //     // CREDIT
//   //     selectedCreditDays = p.creditPeriodDays;
//   //     selectedCreditLabel = p.creditPeriodDays != null
//   //         ? "${p.creditPeriodDays} Days"
//   //         : "Select Days";
//   //
//   //     _creditLimit.text = p.creditLimit?.toString() ?? '';
//   //
//   //     // OTHER
//   //     _contactPersonName.text = p.contactPersonName ?? '';
//   //     _dob = p.dob;
//   //
//   //     // BILLING ADDRESS
//   //     if (p.billingStreet != null) {
//   //       billingAddress = BillingAddress(
//   //         street: p.billingStreet ?? '',
//   //         city: p.billingCity ?? '',
//   //         state: p.billingState ?? '',
//   //         pincode: p.billingPincode ?? '',
//   //       );
//   //     }
//   //   }
//   // }
//   @override
//   void initState() {
//     super.initState();
//
//     final p = widget.initialParty;
//
//     if (p != null) {
//       // ================= EDIT PARTY =================
//       _partyName.text = p.partyName;
//       _contactNumber.text = p.contactNumber ?? '';
//       partyType = p.partyType;
//
//       _gstNumber.text = p.gstNumber ?? '';
//       _panNumber.text = p.panNumber ?? '';
//
//       _openingBalance.text = p.openingBalance.toString();
//       openingBalanceType = p.openingBalanceType;
//
//       selectedCreditDays = p.creditPeriodDays;
//       selectedCreditLabel = p.creditPeriodDays != null
//           ? "${p.creditPeriodDays} Days"
//           : "Select Days";
//
//       _creditLimit.text = p.creditLimit?.toString() ?? '';
//       _contactPersonName.text = p.contactPersonName ?? '';
//       _dob = p.dob;
//
//       if (p.billingStreet != null) {
//         billingAddress = BillingAddress(
//           street: p.billingStreet ?? '',
//           city: p.billingCity ?? '',
//           state: p.billingState ?? '',
//           pincode: p.billingPincode ?? '',
//         );
//       }
//     } else {
//       // ================= QUICK → FULL CREATE =================
//       _partyName.text = widget.prefillName ?? '';
//       _contactNumber.text = widget.prefillPhone ?? '';
//       partyType = 'customer';
//     }
//   }
//
//
//
//   // INPUT DECORATION
//   InputDecoration _boxDecoration({String? hint}) {
//     return InputDecoration(
//       hintText: hint,
//       filled: true,
//       fillColor: const Color(0xFFF9F8FF),
//       hintStyle: const TextStyle(
//         color: Color(0xFFB8B8C8),
//         fontSize: 15,
//         fontWeight: FontWeight.w400,
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0xFFE5E4F3), width: 1),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0xFF4C3FF0), width: 1.6),
//       ),
//     );
//   }
//
//   // LABEL
//   Widget _label(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 15,
//           color: Color(0xFF545454),
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
//
//   // --------------------------------------------------
//   // CREDIT PERIOD BOTTOM SHEET
//   // --------------------------------------------------
//   Future<void> _openCreditPeriodSheet() async {
//     TextEditingController customController = TextEditingController();
//
//     final result = await showModalBottomSheet(
//       isScrollControlled: true,
//       context: context,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
//       builder: (context) {
//         return StatefulBuilder(builder: (context, setModalState) {
//           return Padding(
//             padding: MediaQuery.of(context).viewInsets,
//             child: Container(
//               padding:
//               const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: const [
//                       Expanded(
//                         child: Text(
//                           "Set Credit Period",
//                           style: TextStyle(
//                               fontSize: 17, fontWeight: FontWeight.w700),
//                         ),
//                       ),
//                       Icon(Icons.close)
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//
//                   ...[7, 15, 30, 45, 60, 90].map((d) {
//                     return ListTile(
//                       title: Text("$d Days"),
//                       trailing: selectedCreditDays == d
//                           ? const Icon(Icons.radio_button_checked,
//                           color: Color(0xFF4C3FF0))
//                           : const Icon(Icons.radio_button_off),
//                       onTap: () => Navigator.pop(context, d),
//                     );
//                   }),
//
//                   const Divider(),
//
//                   ListTile(
//                     title: const Text("Custom"),
//                     trailing: selectedCreditDays == -1
//                         ? const Icon(Icons.radio_button_checked,
//                         color: Color(0xFF4C3FF0))
//                         : const Icon(Icons.radio_button_off),
//                     onTap: () => setModalState(() {
//                       selectedCreditDays = -1;
//                     }),
//                   ),
//
//                   if (selectedCreditDays == -1) ...[
//                     const SizedBox(height: 10),
//                     TextField(
//                       controller: customController,
//                       keyboardType: TextInputType.number,
//                       decoration: _boxDecoration(hint: "Enter Days"),
//                     ),
//                   ],
//
//                   const SizedBox(height: 20),
//
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF4C3FF0),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12)),
//                       ),
//                       onPressed: () {
//                         if (selectedCreditDays == -1) {
//                           final c =
//                           int.tryParse(customController.text.trim());
//                           Navigator.pop(context, c);
//                         } else {
//                           Navigator.pop(context, selectedCreditDays);
//                         }
//                       },
//                       child: const Text("Save",
//                           style:
//                           TextStyle(color: Colors.white, fontSize: 16)),
//                     ),
//                   ),
//
//                   const SizedBox(height: 22),
//                 ],
//               ),
//             ),
//           );
//         });
//       },
//     );
//
//     if (result != null) {
//       setState(() {
//         selectedCreditDays = result;
//         selectedCreditLabel = "$result Days";
//         _creditPeriodDays.text = result.toString();
//       });
//     }
//   }
//
//   // --------------------------------------------------
//   // CATEGORY SELECTION BOTTOM SHEET
//   // --------------------------------------------------
//   Future<void> _openCategorySelector() async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
//       builder: (context) {
//         return SizedBox(
//           height: 260,
//           child: Column(
//             children: [
//               const SizedBox(height: 18),
//               const Text(
//                 "Select Category",
//                 style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 18),
//
//               // ADD CATEGORY BUTTON
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pop(context);
//                   _openCreateCategorySheet();
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 18),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                         color: const Color(0xFF4C3FF0), width: 1.2),
//                   ),
//                   alignment: Alignment.center,
//                   child: const Text(
//                     "+ Add Category",
//                     style: TextStyle(
//                       color: Color(0xFF4C3FF0),
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   // --------------------------------------------------
//   // CREATE CATEGORY POPUP
//   // --------------------------------------------------
//   Future<void> _openCreateCategorySheet() async {
//     TextEditingController catCtrl = TextEditingController();
//
//     final newCategory = await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
//       builder: (context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: Container(
//             padding:
//             const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   children: const [
//                     Expanded(
//                         child: Text("Create Category",
//                             style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w700))),
//                     Icon(Icons.close),
//                   ],
//                 ),
//                 const SizedBox(height: 18),
//
//                 _label("Category Name"),
//                 TextField(
//                   controller: catCtrl,
//                   decoration: _boxDecoration(hint: "Enter Category Name"),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF4C3FF0),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14)),
//                     ),
//                     onPressed: () {
//                       if (catCtrl.text.trim().isNotEmpty) {
//                         Navigator.pop(context, catCtrl.text.trim());
//                       }
//                     },
//                     child: const Text(
//                       "Save",
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 18),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//
//     if (newCategory != null) {
//       setState(() {
//         _partyCategoryName.text = newCategory;
//       });
//     }
//   }
//
//   // --------------------------------------------------
//   // BUILD METHOD
//   // --------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     final primary = widget.primary;
//     final dateFmt = DateFormat('dd MMM yyyy');
//
//     return Scaffold(
//       // backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         foregroundColor: Colors.black,
//         title: const Text("Create New Party",
//             style:
//             TextStyle(fontWeight: FontWeight.w600)),
//       ),
//
//         body: AppBackground(
//           child: DefaultTabController(
//         length: 3,
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 16, vertical: 12),
//                 children: [
//
//                   // GST Banner
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFF8E1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         const Expanded(
//                           child: Text(
//                             "Autofill party details with GST number",
//                             style: TextStyle(fontSize: 14),
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () {},
//                           child: const Text(
//                             "Add",
//                             style: TextStyle(
//                               color: Color(0xFF4C3FF0),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close, size: 18),
//                           onPressed: () {},
//                         )
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // BASIC DETAILS
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//
//                       children: [
//
//                         _label("Party Name *"),
//                         TextFormField(
//                           controller: _partyName,
//                           decoration:
//                           _boxDecoration(hint: "Enter Party Name"),
//                           validator: (v) =>
//                           v == null || v.trim().isEmpty
//                               ? "Required"
//                               : null,
//                         ),
//                         const SizedBox(height: 18),
//
//                         _label("Contact Number"),
//                         TextFormField(
//                           controller: _contactNumber,
//                           keyboardType: TextInputType.phone,
//                           decoration: _boxDecoration(
//                               hint: "Enter Contact Number"),
//                         ),
//                         const SizedBox(height: 22),
//
//                         _label("Party Type"),
//                         const SizedBox(height: 6),
//                         Row(
//                           children: [
//                             _partyTypeChip(
//                                 "Customer", "customer", primary),
//                             const SizedBox(width: 12),
//                             _partyTypeChip(
//                                 "Supplier", "supplier", primary),
//                           ],
//                         ),
//
//                         const SizedBox(height: 26),
//                       ],
//                     ),
//                   ),
//
//                   // TAB BAR
//                   const TabBar(
//                     labelColor: Color(0xFF4C3FF0),
//                     unselectedLabelColor: Colors.black54,
//                     indicatorColor: Color(0xFF4C3FF0),
//                     tabs: [
//                       Tab(text: "Business Info"),
//                       Tab(text: "Credit Info"),
//                       Tab(text: "Other Details"),
//                     ],
//                   ),
//
//                   SizedBox(
//                     height: 480,
//                     child: TabBarView(
//                       children: [
//
//                         // ------------------------------
//                         // BUSINESS INFO TAB
//                         // ------------------------------
//                         ListView(
//                           padding: const EdgeInsets.only(top: 16),
//                           children: [
//                             _label("GST Number"),
//                             TextField(
//                               controller: _gstNumber,
//                               decoration: _boxDecoration(
//                                   hint: "Ex: 24AAACC1206D1ZM"),
//                             ),
//                             const SizedBox(height: 16),
//
//                             _label("PAN Number"),
//                             TextField(
//                               controller: _panNumber,
//                               decoration:
//                               _boxDecoration(hint: "Ex: AAACC1206D"),
//                             ),
//                             const SizedBox(height: 20),
//
//                             ListTile(
//                               contentPadding: EdgeInsets.zero,
//                               leading: Icon(Icons.location_city,
//                                   color: primary, size: 28),
//                               title: const Text("Billing Address",
//                                   style:
//                                   TextStyle(fontWeight: FontWeight.w600)),
//                               subtitle: billingAddress == null
//                                   ? null
//                                   : Text(
//                                 "${billingAddress!.street}, ${billingAddress!.city}",
//                                 style: const TextStyle(
//                                     color: Colors.black54),
//                               ),
//                               trailing: const Icon(Icons.chevron_right),
//                               onTap: () async {
//                                 final result =
//                                 await showModalBottomSheet<
//                                     BillingAddress>(
//                                   context: context,
//                                   isScrollControlled: true,
//                                   shape: const RoundedRectangleBorder(
//                                       borderRadius:
//                                       BorderRadius.vertical(
//                                           top: Radius.circular(20))),
//                                   builder: (_) =>
//                                       BillingAddressSheet(
//                                           initial: billingAddress),
//                                 );
//                                 if (result != null)
//                                   setState(() =>
//                                   billingAddress = result);
//                               },
//                             ),
//                           ],
//                         ),
//
//                         // ------------------------------
//                         // CREDIT INFO TAB
//                         // ------------------------------
//                         ListView(
//                           padding: const EdgeInsets.only(top: 16),
//                           children: [
//                             _label("Opening Balance Type"),
//                             const SizedBox(height: 6),
//
//                             Row(
//                               children: [
//                                 _balanceTypeChip("I receive", "receive"),
//                                 const SizedBox(width: 12),
//                                 _balanceTypeChip("I pay", "pay"),
//                               ],
//                             ),
//
//                             const SizedBox(height: 14),
//
//                             _label("Opening Balance"),
//                             TextField(
//                               controller: _openingBalance,
//                               keyboardType:
//                               const TextInputType.numberWithOptions(
//                                   decimal: true),
//                               decoration: _boxDecoration(hint: "0.0")
//                                   .copyWith(
//                                 prefixIcon: Padding(
//                                   padding: const EdgeInsets.only(
//                                       left: 12, right: 4, top: 12),
//                                   child: Text("₹",
//                                       style: TextStyle(
//                                           fontSize: 18,
//                                           color: Colors
//                                               .grey.shade700)),
//                                 ),
//                                 prefixIconConstraints:
//                                 const BoxConstraints(
//                                     minWidth: 0, minHeight: 0),
//                               ),
//                             ),
//                             const SizedBox(height: 18),
//
//                             _label("Credit Period (Days)"),
//                             GestureDetector(
//                               onTap: _openCreditPeriodSheet,
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 14, vertical: 14),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF9F8FF),
//                                   borderRadius:
//                                   BorderRadius.circular(12),
//                                   border: Border.all(
//                                       color: const Color(0xFFE5E4F3),
//                                       width: 1),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment:
//                                   MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       selectedCreditLabel ??
//                                           "Select Days",
//                                       style: const TextStyle(
//                                           color: Colors.black87,
//                                           fontSize: 15),
//                                     ),
//                                     const Icon(Icons.expand_more,
//                                         color: Colors.black54)
//                                   ],
//                                 ),
//                               ),
//                             ),
//
//                             const SizedBox(height: 18),
//
//                             _label("Credit Limit"),
//                             TextField(
//                               controller: _creditLimit,
//                               keyboardType:
//                               const TextInputType.numberWithOptions(
//                                   decimal: true),
//                               decoration: _boxDecoration(hint: "0.0")
//                                   .copyWith(
//                                 prefixIcon: Padding(
//                                   padding: const EdgeInsets.only(
//                                       left: 12, right: 4, top: 12),
//                                   child: Text("₹",
//                                       style: TextStyle(
//                                           fontSize: 18,
//                                           color: Colors
//                                               .grey.shade700)),
//                                 ),
//                                 prefixIconConstraints:
//                                 const BoxConstraints(
//                                     minWidth: 0, minHeight: 0),
//                               ),
//                             ),
//                           ],
//                         ),
//
//                         // ------------------------------
//                         // OTHER DETAILS TAB (UPDATED)
//                         // ------------------------------
//                         ListView(
//                           padding: const EdgeInsets.only(top: 16),
//                           children: [
//
//                             // -------- PARTY CATEGORY (UPDATED) --------
//                             _label("Party Category"),
//                             GestureDetector(
//                               onTap: _openCategorySelector,
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 14, vertical: 14),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF9F8FF),
//                                   borderRadius:
//                                   BorderRadius.circular(12),
//                                   border: Border.all(
//                                       color: const Color(0xFFE5E4F3),
//                                       width: 1),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment:
//                                   MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       _partyCategoryName.text.isEmpty
//                                           ? "Select Category"
//                                           : _partyCategoryName.text,
//                                       style: TextStyle(
//                                         fontSize: 15,
//                                         color: _partyCategoryName
//                                             .text.isEmpty
//                                             ? Colors.black38
//                                             : Colors.black87,
//                                       ),
//                                     ),
//                                     const Icon(Icons.expand_more,
//                                         color: Colors.black54),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//
//                             _label("Contact Person Name"),
//                             TextField(
//                               controller: _contactPersonName,
//                               decoration: _boxDecoration(
//                                   hint: "Ex: Ankit Mishra"),
//                             ),
//                             const SizedBox(height: 16),
//
//                             // ListTile(
//                             //   contentPadding: EdgeInsets.zero,
//                             //   title: const Text("Date of Birth",
//                             //       style: TextStyle(fontWeight: FontWeight.w600)),
//                             //   subtitle: Text(
//                             //     _dob == null ? "Select DOB" : dateFmt.format(_dob!),
//                             //     style: const TextStyle(color: Colors.black54),
//                             //   ),
//                             //   trailing: const Icon(Icons.calendar_today_rounded),
//                             //   onTap: () async {
//                             //     final picked = await showDatePicker(
//                             //       context: context,
//                             //       initialDate: _dob ?? DateTime(1996),
//                             //       firstDate: DateTime(1900),
//                             //       lastDate: DateTime.now(),
//                             //     );
//                             //     if (picked != null) setState(() => _dob = picked);
//                             //   },
//                             // ),
//
//                             _label("Date of Birth"),
//
//                             GestureDetector(
//                               onTap: () async {
//                                 final picked = await showDatePicker(
//                                   context: context,
//                                   initialDate: _dob ?? DateTime(1996),
//                                   firstDate: DateTime(1900),
//                                   lastDate: DateTime.now(),
//                                 );
//                                 if (picked != null) {
//                                   setState(() => _dob = picked);
//                                 }
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF9F8FF),
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(color: const Color(0xFFE5E4F3), width: 1),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       _dob == null ? "Ex: 25 Aug 1999" : dateFmt.format(_dob!),
//                                       style: TextStyle(
//                                         fontSize: 15,
//                                         color: _dob == null ? Colors.black38 : Colors.black87,
//                                       ),
//                                     ),
//                                     const Icon(
//                                       Icons.calendar_today_rounded,
//                                       color: Colors.black54,
//                                       size: 20,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//
//                             const SizedBox(height: 20),
//
//
//                           ],
//                         ),
//
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // SAVE BUTTON
//             Container(
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 16, vertical: 14),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primary,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14)),
//                   ),
//                   onPressed: _saving ? null : _saveFullParty,
//                   child: _saving
//                       ? const CircularProgressIndicator(
//                       color: Colors.white)
//                       : const Text("Save",
//                       style: TextStyle(
//                           fontSize: 17,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.white)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//         ),
//     );
//   }
//
//   // PARTY TYPE CHIP
//   Widget _partyTypeChip(String label, String value, Color primary) {
//     final selected = partyType == value;
//     return GestureDetector(
//       onTap: () => setState(() => partyType = value),
//       child: Container(
//         padding:
//         const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//         decoration: BoxDecoration(
//           color:
//           selected ? primary.withOpacity(0.15) : const Color(0xFFF1F1F7),
//           borderRadius: BorderRadius.circular(28),
//           border: Border.all(
//               color: selected ? primary : const Color(0xFFE0E0E0)),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: selected ? primary : Colors.black87,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _balanceTypeChip(String label, String value) {
//     final selected = openingBalanceType == value;
//     return GestureDetector(
//       onTap: () => setState(() => openingBalanceType = value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? widget.primary.withOpacity(0.15) : const Color(0xFFF1F1F7),
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//             color: selected ? widget.primary : const Color(0xFFE0E0E0),
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: selected ? widget.primary : Colors.black87,
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   // SAVE PARTY
//   Future<void> _saveFullParty() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _saving = true);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? "";
//
//       final body = {
//         "party_name": _partyName.text.trim(),
//         "contact_number": _contactNumber.text.trim(),
//         "party_type": partyType,
//         "gst_number":
//         _gstNumber.text.trim().isEmpty ? null : _gstNumber.text.trim(),
//         "pan_number":
//         _panNumber.text.trim().isEmpty ? null : _panNumber.text.trim(),
//         "billing_street": billingAddress?.street,
//         "billing_state": billingAddress?.state,
//         "billing_pincode": billingAddress?.pincode,
//         "billing_city": billingAddress?.city,
//         "opening_balance":
//         double.tryParse(_openingBalance.text.trim()) ?? 0,
//         "opening_balance_type": openingBalanceType, // ✅ ADD THIS
//         "credit_period_days": selectedCreditDays ?? 0,
//         "credit_limit":
//         double.tryParse(_creditLimit.text.trim()) ?? 0,
//         "party_category_id": null,
//         "contact_person_name":
//         _contactPersonName.text.trim().isEmpty
//             ? null
//             : _contactPersonName.text.trim(),
//         "dob": _dob == null
//             ? null
//             : DateFormat('yyyy-MM-dd').format(_dob!),
//       };
//
//       // final res = await http.post(
//       //   Uri.parse('$baseUrl/parties'),
//       //   headers: {
//       //     "Content-Type": "application/json",
//       //     "Accept": "application/json",
//       //     "Authorization": "Bearer $token",
//       //   },
//       //   body: jsonEncode(body),
//       // );
//       // final isEdit = widget.initialParty != null;
//       //
//       // final uri = isEdit
//       //     ? Uri.parse('$baseUrl/parties/${widget.initialParty!.id}')
//       //     : Uri.parse('$baseUrl/parties');
//       //
//       // final res = await http.post(
//       //   uri,
//       //   headers: {
//       //     "Content-Type": "application/json",
//       //     "Accept": "application/json",
//       //     "Authorization": "Bearer $token",
//       //   },
//       //   body: jsonEncode(body),
//       // );
//
//       final isEdit = widget.initialParty != null;
//
//       final uri = isEdit
//           ? Uri.parse('$baseUrl/parties/${widget.initialParty!.id}')
//           : Uri.parse('$baseUrl/parties');
//
//       final res = isEdit
//           ? await http.put( // ✅ PUT FOR UPDATE
//         uri,
//         headers: {
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       )
//           : await http.post( // ✅ POST FOR CREATE
//         uri,
//         headers: {
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       );
//
//
//
//       // if (res.statusCode == 200 || res.statusCode == 201) {
//       //   final json = jsonDecode(res.body);
//       //   Navigator.pop(context, PartyModel.fromJson(json['data']));
//       // }
//
//       if (res.statusCode == 200 || res.statusCode == 201) {
//         final json = jsonDecode(res.body);
//         if (mounted) {
//           Navigator.of(context).pop(
//             PartyModel.fromJson(json['data']),
//           );
//         }
//       }
//
//     } finally {
//       setState(() => _saving = false);
//     }
//   }
// }
//
//
//
// // --------------------------------------------------
// // 4. Billing Address bottom sheet (UPDATED UI LIKE SCREENSHOT 2)
// // --------------------------------------------------
//
// class BillingAddress {
//   final String street;
//   final String state;
//   final String pincode;
//   final String city;
//
//   BillingAddress({
//     required this.street,
//     required this.state,
//     required this.pincode,
//     required this.city,
//   });
// }
//
// class BillingAddressSheet extends StatefulWidget {
//   final BillingAddress? initial;
//
//   const BillingAddressSheet({super.key, this.initial});
//
//   @override
//   State<BillingAddressSheet> createState() => _BillingAddressSheetState();
// }
//
// class _BillingAddressSheetState extends State<BillingAddressSheet> {
//   final _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _street = TextEditingController();
//   final TextEditingController _state = TextEditingController();
//   final TextEditingController _pincode = TextEditingController();
//   final TextEditingController _city = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.initial != null) {
//       _street.text = widget.initial!.street;
//       _state.text = widget.initial!.state;
//       _pincode.text = widget.initial!.pincode;
//       _city.text = widget.initial!.city;
//     }
//   }
//
//   // SAME BOX STYLE AS SCREENSHOT 2
//   InputDecoration _inputBox(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       filled: true,
//       fillColor: const Color(0xFFF5F3FF),
//       hintStyle: const TextStyle(
//         color: Color(0xFFB8B8C8),
//         fontSize: 15,
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Color(0xFFE5E4F3)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Color(0xFF4C3FF0), width: 1.4),
//       ),
//     );
//   }
//
//   // LABEL STYLE (outside box)
//   Widget _label(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF545454),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Padding(
//         padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: [
//                   const Text(
//                     "Add Billing Address",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 10),
//
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//
//                     // STREET
//                     _label("Street Address *"),
//                     TextFormField(
//                       controller: _street,
//                       decoration: _inputBox(
//                         "Ex: 15, Hill View Apt, LBS Marg",
//                       ),
//                       validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
//                     ),
//                     const SizedBox(height: 14),
//
//                     // STATE + PINCODE ROW
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _label("State"),
//                               TextFormField(
//                                 controller: _state,
//                                 decoration: _inputBox("Ex: Maharashtra"),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 14),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _label("Pincode"),
//                               TextFormField(
//                                 controller: _pincode,
//                                 keyboardType: TextInputType.number,
//                                 decoration: _inputBox("Ex: 560076"),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 14),
//
//                     // CITY
//                     _label("City"),
//                     TextFormField(
//                       controller: _city,
//                       decoration: _inputBox("Ex: Bengaluru"),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4C3FF0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   onPressed: _saveAddress,
//                   child: const Text(
//                     "Save",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _saveAddress() {
//     if (!_formKey.currentState!.validate()) return;
//
//     final addr = BillingAddress(
//       street: _street.text.trim(),
//       state: _state.text.trim(),
//       pincode: _pincode.text.trim(),
//       city: _city.text.trim(),
//     );
//
//     Navigator.pop(context, addr);
//   }
// }
//


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'create_invoice_screen.dart'; // for PartyModel & baseUrl

import '../models/party_model.dart';

import 'package:flutter_project/widgets/app_background.dart';



// import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

import 'package:flutter_contacts/flutter_contacts.dart';



// --------------------------------------------------
// 1. Select Party bottom sheet
// --------------------------------------------------

class SelectPartySheet extends StatefulWidget {
  final Color primary;

  const SelectPartySheet({super.key, required this.primary});

  @override
  State<SelectPartySheet> createState() => _SelectPartySheetState();
}

class _SelectPartySheetState extends State<SelectPartySheet>
    with SingleTickerProviderStateMixin {
  List<PartyModel> parties = [];
  List<PartyModel> filtered = [];
  bool loading = true;
  String search = '';

  List<Contact> contacts = [];
  bool contactsLoading = true;

  bool permissionAsked = false; // add this



  late TabController _tabController;


  // bool _contactsLoaded = false; // 👈 ADD THIS

  @override
  void initState() {
    super.initState();
    _loadParties();

    _tabController = TabController(length: 2, vsync: this);

    // preload contacts once
    loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }




  Future<void> loadContacts() async {
    setState(() => contactsLoading = true);

    try {
      final granted = await FlutterContacts.requestPermission();

      if (!granted) {
        print("❌ Permission Denied");
        setState(() => contactsLoading = false);
        return;
      }

      print("✅ Permission Granted");

      final data = await FlutterContacts.getContacts(
        withProperties: true,
      );

      print("CONTACT COUNT: ${data.length}");

      setState(() {
        contacts = data;
        contactsLoading = false;
      });

    } catch (e) {
      print("ERROR: $e");
      setState(() => contactsLoading = false);
    }
  }

  Future<void> _loadParties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final res = await http.get(
        Uri.parse('$baseUrl/parties'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List)
            .map((e) => PartyModel.fromJson(e))
            .toList();
        setState(() {
          parties = list;
          filtered = list;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _filter(String value) {
    setState(() {
      search = value;
      filtered = parties
          .where((p) =>
          p.partyName.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        "Select Party",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),

                // search
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black45),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: _filter,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search by Party Name",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // tabs
                TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF4C3FF0),
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Color(0xFF4C3FF0),
                  tabs: [
                    Tab(text: "All Parties"),
                    Tab(text: "Contacts"),
                  ],
                ),

                const SizedBox(height: 4),

                Expanded(
                  child: loading
                      ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPartyList(filtered),
                      _buildContactsList(),
                    ],
                  ),
                ),

                // create party button
                // create party button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46, // smaller height like screenshot
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22), // smaller radius
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () async {
                        final PartyModel? party =
                        await showModalBottomSheet<PartyModel>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          builder: (_) => QuickCreatePartySheet(primary: primary),
                        );

                        if (party != null && mounted) {
                          Navigator.pop(context, party);
                        }
                      },

                      icon: const Icon(
                        Icons.add,
                        color: Colors.white, // white icon
                        size: 22,
                      ),

                      label: const Text(
                        "Create Party",
                        style: TextStyle(
                          color: Colors.white, // white text
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildContactsList() {
    if (contactsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contacts.isEmpty) {
      return const Center(child: Text("No contacts found"));
    }

    return ListView.separated(
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final c = contacts[index];

        final name = c.displayName;
        final phone = c.phones.isNotEmpty
            ? c.phones.first.number
            : "No Number";

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple.shade100,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(color: Colors.black),
            ),
          ),
          title: Text(name),
          subtitle: Text(phone),


            onTap: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token') ?? "";

                // 🔥 Normalize phone (important)
                final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');

                // 🔥 1. Check existing party
                final existing = parties.firstWhere(
                      (p) => (p.contactNumber ?? '').replaceAll(RegExp(r'\s+'), '') == cleanPhone,
                  orElse: () => PartyModel(
                    id: -1,
                    partyName: '',
                    contactNumber: '',
                    partyType: 'customer',
                    openingBalance: 0,
                    openingBalanceType: 'receive',
                  ),
                );

                if (existing.id != -1) {
                  Navigator.pop(context, existing);
                  return;
                }

                // 🔥 2. Create party via API
                final res = await http.post(
                  Uri.parse('$baseUrl/parties'),
                  headers: {
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                    "Authorization": "Bearer $token",
                  },
                  body: jsonEncode({
                    "party_name": name,
                    "contact_number": cleanPhone,
                    "party_type": "customer",
                    "opening_balance": 0,
                    "opening_balance_type": "receive",
                  }),
                );

                if (res.statusCode == 200 || res.statusCode == 201) {
                  final json = jsonDecode(res.body);
                  final party = PartyModel.fromJson(json['data']);

                  if (mounted) {
                    Navigator.pop(context, party);
                  }
                } else {
                  print("❌ Party create failed: ${res.body}");
                }
              } catch (e) {
                print("ERROR: $e");
              }
            }
        );
      },
    );
  }

  Widget _buildPartyList(List<PartyModel> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text("No parties found"),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = list[index];
        return ListTile(
          onTap: () => Navigator.pop(context, p),
          title: Text(p.partyName),
          subtitle: Text(
            "${p.contactNumber ?? ''} • ${p.partyType ?? 'Customer'}",
          ),
          // trailing: const Icon(Icons.arrow_downward, color: Colors.green),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "₹ ${p.openingBalance?.toStringAsFixed(0) ?? 0}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Icon(
                p.openingBalanceType == 'pay'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: p.openingBalanceType == 'pay'
                    ? Colors.red
                    : Colors.green,
                size: 18,
              ),
            ],
          ),


        );
      },
    );
  }
}

// --------------------------------------------------
// 2. Quick Create Party bottom sheet
// --------------------------------------------------

class QuickCreatePartySheet extends StatefulWidget {
  final Color primary;

  const QuickCreatePartySheet({super.key, required this.primary});

  @override
  State<QuickCreatePartySheet> createState() => _QuickCreatePartySheetState();
}

class _QuickCreatePartySheetState extends State<QuickCreatePartySheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _partyName = TextEditingController();
  final TextEditingController _contactNumber = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // 🔥 KEYBOARD FIX
      ),
      child: SafeArea(
        child: SingleChildScrollView( // 🔥 allows sheet to move/scroll
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= HEADER =================
                Row(
                  children: [
                    const Text(
                      "Create Party",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 26),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ================= FORM =================
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ---------- Party Name ----------
                      const Text(
                        "Party Name *",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0E0F3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextFormField(
                          controller: _partyName,
                          textInputAction: TextInputAction.next, // ✅ UX improvement
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Ex: Ankit Mishra",
                            hintStyle: TextStyle(color: Colors.black38),
                          ),
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? "Required" : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------- Contact Number ----------
                      const Text(
                        "Contact Number",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0E0F3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextFormField(
                          controller: _contactNumber,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done, // ✅ Done button
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Ex: 9876543210",
                            hintStyle: TextStyle(color: Colors.black38),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ================= ACTION ROW =================
                Row(
                  children: [

                    // ---------- Add More Details ----------
                    InkWell(
                      onTap: () async {
                        final party = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateNewPartyScreen(
                              primary: primary,
                              prefillName: _partyName.text.trim(),
                              prefillPhone: _contactNumber.text.trim(),
                            ),
                          ),
                        );

                        if (party != null && mounted) {
                          Navigator.of(context).pop(party);
                        }
                      },
                      child: Text(
                        "Add more details\nGST, Address, etc.",
                        style: TextStyle(
                          color: primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ---------- Save Button ----------
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _saving ? null : _saveQuickParty,
                        child: _saving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          "Save Party",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _saveQuickParty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final body = {
        "party_name": _partyName.text.trim(),
        "contact_number": _contactNumber.text.trim(),
        "party_type": "customer",

        // ✅ REQUIRED BY BACKEND
        "opening_balance": 0,
        "opening_balance_type": "receive",
      };


      final res = await http.post(
        Uri.parse('$baseUrl/parties'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        final party = PartyModel.fromJson(json['data']);

        // ✅ THIS LINE IS THE FIX
        if (mounted) {
          Navigator.of(context).pop(party);
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

}

// --------------------------------------------------
// 3. Full "Create New Party" screen (LABELS OUTSIDE BOX)
// --------------------------------------------------

class CreateNewPartyScreen extends StatefulWidget {
  final Color primary;
  final PartyModel? initialParty;

  final String? prefillName;
  final String? prefillPhone;

  const CreateNewPartyScreen({
    super.key,
    required this.primary,
    this.initialParty,
    this.prefillName,
    this.prefillPhone,
  });

  @override
  State<CreateNewPartyScreen> createState() => _CreateNewPartyScreenState();
}

class _CreateNewPartyScreenState extends State<CreateNewPartyScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _partyName = TextEditingController();
  final TextEditingController _contactNumber = TextEditingController();
  String partyType = "customer";

  final TextEditingController _gstNumber = TextEditingController();
  final TextEditingController _panNumber = TextEditingController();
  BillingAddress? billingAddress;

  final TextEditingController _openingBalance = TextEditingController();
  final TextEditingController _creditPeriodDays = TextEditingController();
  final TextEditingController _creditLimit = TextEditingController();

  final TextEditingController _partyCategoryName = TextEditingController();
  final TextEditingController _contactPersonName = TextEditingController();
  DateTime? _dob;

  bool _saving = false;

  String? selectedCreditLabel = "Select Days";
  int? selectedCreditDays;

  String openingBalanceType = 'receive'; // default


  // @override
  // void initState() {
  //   super.initState();
  //   if (widget.initialParty != null) {
  //     _partyName.text = widget.initialParty!.partyName;
  //     _contactNumber.text = widget.initialParty!.contactNumber ?? '';
  //     partyType = widget.initialParty!.partyType ?? 'customer';
  //   } else {
  //     _partyName.text = widget.prefillName ?? "";
  //     _contactNumber.text = widget.prefillPhone ?? "";
  //   }
  // }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   final p = widget.initialParty;
  //
  //   if (p != null) {
  //     // BASIC
  //     _partyName.text = p.partyName;
  //     _contactNumber.text = p.contactNumber ?? '';
  //     partyType = p.partyType ?? 'customer';
  //
  //     // GST & PAN
  //     _gstNumber.text = p.gstNumber ?? '';
  //     _panNumber.text = p.panNumber ?? '';
  //
  //     // OPENING BALANCE
  //     _openingBalance.text = p.openingBalance?.toString() ?? '';
  //     openingBalanceType = p.openingBalanceType ?? 'receive';
  //
  //     // CREDIT
  //     selectedCreditDays = p.creditPeriodDays;
  //     selectedCreditLabel = p.creditPeriodDays != null
  //         ? "${p.creditPeriodDays} Days"
  //         : "Select Days";
  //
  //     _creditLimit.text = p.creditLimit?.toString() ?? '';
  //
  //     // OTHER
  //     _contactPersonName.text = p.contactPersonName ?? '';
  //     _dob = p.dob;
  //
  //     // BILLING ADDRESS
  //     if (p.billingStreet != null) {
  //       billingAddress = BillingAddress(
  //         street: p.billingStreet ?? '',
  //         city: p.billingCity ?? '',
  //         state: p.billingState ?? '',
  //         pincode: p.billingPincode ?? '',
  //       );
  //     }
  //   }
  // }
  @override
  void initState() {
    super.initState();

    final p = widget.initialParty;

    if (p != null) {
      // ================= EDIT PARTY =================
      _partyName.text = p.partyName;
      _contactNumber.text = p.contactNumber ?? '';
      partyType = p.partyType;

      _gstNumber.text = p.gstNumber ?? '';
      _panNumber.text = p.panNumber ?? '';

      _openingBalance.text = p.openingBalance.toString();
      openingBalanceType = p.openingBalanceType;

      selectedCreditDays = p.creditPeriodDays;
      selectedCreditLabel = p.creditPeriodDays != null
          ? "${p.creditPeriodDays} Days"
          : "Select Days";

      _creditLimit.text = p.creditLimit?.toString() ?? '';
      _contactPersonName.text = p.contactPersonName ?? '';
      _dob = p.dob;

      if (p.billingStreet != null) {
        billingAddress = BillingAddress(
          street: p.billingStreet ?? '',
          city: p.billingCity ?? '',
          state: p.billingState ?? '',
          pincode: p.billingPincode ?? '',
        );
      }
    } else {
      // ================= QUICK → FULL CREATE =================
      _partyName.text = widget.prefillName ?? '';
      _contactNumber.text = widget.prefillPhone ?? '';
      partyType = 'customer';
    }
  }



  // INPUT DECORATION
  InputDecoration _boxDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9F8FF),
      hintStyle: const TextStyle(
        color: Color(0xFFB8B8C8),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E4F3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4C3FF0), width: 1.6),
      ),
    );
  }

  // LABEL
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF545454),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CREDIT PERIOD BOTTOM SHEET
  // --------------------------------------------------
  Future<void> _openCreditPeriodSheet() async {
    TextEditingController customController = TextEditingController();

    final result = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          "Set Credit Period",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.close)
                    ],
                  ),
                  const SizedBox(height: 20),

                  ...[7, 15, 30, 45, 60, 90].map((d) {
                    return ListTile(
                      title: Text("$d Days"),
                      trailing: selectedCreditDays == d
                          ? const Icon(Icons.radio_button_checked,
                          color: Color(0xFF4C3FF0))
                          : const Icon(Icons.radio_button_off),
                      onTap: () => Navigator.pop(context, d),
                    );
                  }),

                  const Divider(),

                  ListTile(
                    title: const Text("Custom"),
                    trailing: selectedCreditDays == -1
                        ? const Icon(Icons.radio_button_checked,
                        color: Color(0xFF4C3FF0))
                        : const Icon(Icons.radio_button_off),
                    onTap: () => setModalState(() {
                      selectedCreditDays = -1;
                    }),
                  ),

                  if (selectedCreditDays == -1) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      decoration: _boxDecoration(hint: "Enter Days"),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C3FF0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (selectedCreditDays == -1) {
                          final c =
                          int.tryParse(customController.text.trim());
                          Navigator.pop(context, c);
                        } else {
                          Navigator.pop(context, selectedCreditDays);
                        }
                      },
                      child: const Text("Save",
                          style:
                          TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 22),
                ],
              ),
            ),
          );
        });
      },
    );

    if (result != null) {
      setState(() {
        selectedCreditDays = result;
        selectedCreditLabel = "$result Days";
        _creditPeriodDays.text = result.toString();
      });
    }
  }

  // --------------------------------------------------
  // CATEGORY SELECTION BOTTOM SHEET
  // --------------------------------------------------
  Future<void> _openCategorySelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              const SizedBox(height: 18),
              const Text(
                "Select Category",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),

              // ADD CATEGORY BUTTON
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _openCreateCategorySheet();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF4C3FF0), width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "+ Add Category",
                    style: TextStyle(
                      color: Color(0xFF4C3FF0),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // CREATE CATEGORY POPUP
  // --------------------------------------------------
  Future<void> _openCreateCategorySheet() async {
    TextEditingController catCtrl = TextEditingController();

    final newCategory = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Expanded(
                        child: Text("Create Category",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700))),
                    Icon(Icons.close),
                  ],
                ),
                const SizedBox(height: 18),

                _label("Category Name"),
                TextField(
                  controller: catCtrl,
                  decoration: _boxDecoration(hint: "Enter Category Name"),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C3FF0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (catCtrl.text.trim().isNotEmpty) {
                        Navigator.pop(context, catCtrl.text.trim());
                      }
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );

    if (newCategory != null) {
      setState(() {
        _partyCategoryName.text = newCategory;
      });
    }
  }

  // --------------------------------------------------
  // BUILD METHOD
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      resizeToAvoidBottomInset: true, // 🔥 IMPORTANT
      // backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        title: const Text("Create New Party",
            style:
            TextStyle(fontWeight: FontWeight.w600)),
      ),

        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AppBackground(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [

                    // GST Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Autofill party details with GST number",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Add",
                              style: TextStyle(
                                color: Color(0xFF4C3FF0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {},
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BASIC DETAILS
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          _label("Party Name *"),
                          TextFormField(
                            controller: _partyName,
                            decoration:
                            _boxDecoration(hint: "Enter Party Name"),
                            validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? "Required"
                                : null,
                          ),
                          const SizedBox(height: 18),

                          _label("Contact Number"),
                          TextFormField(
                            controller: _contactNumber,
                            keyboardType: TextInputType.phone,
                            decoration: _boxDecoration(
                                hint: "Enter Contact Number"),
                          ),
                          const SizedBox(height: 22),

                          _label("Party Type"),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _partyTypeChip(
                                  "Customer", "customer", primary),
                              const SizedBox(width: 12),
                              _partyTypeChip(
                                  "Supplier", "supplier", primary),
                            ],
                          ),

                          const SizedBox(height: 26),
                        ],
                      ),
                    ),

                    // TAB BAR
                    const TabBar(
                      labelColor: Color(0xFF4C3FF0),
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: Color(0xFF4C3FF0),
                      tabs: [
                        Tab(text: "Business Info"),
                        Tab(text: "Credit Info"),
                        Tab(text: "Other Details"),
                      ],
                    ),

                    // SizedBox(
                    //   height: 480,
                    //   child: TabBarView(
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: TabBarView(
                        children: [

                          // ------------------------------
                          // BUSINESS INFO TAB
                          // ------------------------------
                          ListView(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 16),
                            children: [
                              _label("GST Number"),
                              TextField(
                                controller: _gstNumber,
                                decoration: _boxDecoration(
                                    hint: "Ex: 24AAACC1206D1ZM"),
                              ),
                              const SizedBox(height: 16),

                              _label("PAN Number"),
                              TextField(
                                controller: _panNumber,
                                decoration:
                                _boxDecoration(hint: "Ex: AAACC1206D"),
                              ),
                              const SizedBox(height: 20),

                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.location_city,
                                    color: primary, size: 28),
                                title: const Text("Billing Address",
                                    style:
                                    TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: billingAddress == null
                                    ? null
                                    : Text(
                                  "${billingAddress!.street}, ${billingAddress!.city}",
                                  style: const TextStyle(
                                      color: Colors.black54),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final result =
                                  await showModalBottomSheet<
                                      BillingAddress>(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.vertical(
                                            top: Radius.circular(20))),
                                    builder: (_) =>
                                        BillingAddressSheet(
                                            initial: billingAddress),
                                  );
                                  if (result != null)
                                    setState(() =>
                                    billingAddress = result);
                                },
                              ),
                            ],
                          ),

                          // ------------------------------
                          // CREDIT INFO TAB
                          // ------------------------------
                          ListView(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 16),
                            children: [
                              _label("Opening Balance Type"),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  _balanceTypeChip("I receive", "receive"),
                                  const SizedBox(width: 12),
                                  _balanceTypeChip("I pay", "pay"),
                                ],
                              ),

                              const SizedBox(height: 14),

                              _label("Opening Balance"),
                              TextField(
                                controller: _openingBalance,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: _boxDecoration(hint: "0.0")
                                    .copyWith(
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 12, right: 4, top: 12),
                                    child: Text("₹",
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors
                                                .grey.shade700)),
                                  ),
                                  prefixIconConstraints:
                                  const BoxConstraints(
                                      minWidth: 0, minHeight: 0),
                                ),
                              ),
                              const SizedBox(height: 18),

                              _label("Credit Period (Days)"),
                              GestureDetector(
                                onTap: _openCreditPeriodSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F8FF),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE5E4F3),
                                        width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedCreditLabel ??
                                            "Select Days",
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15),
                                      ),
                                      const Icon(Icons.expand_more,
                                          color: Colors.black54)
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              _label("Credit Limit"),
                              TextField(
                                controller: _creditLimit,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: _boxDecoration(hint: "0.0")
                                    .copyWith(
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 12, right: 4, top: 12),
                                    child: Text("₹",
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors
                                                .grey.shade700)),
                                  ),
                                  prefixIconConstraints:
                                  const BoxConstraints(
                                      minWidth: 0, minHeight: 0),
                                ),
                              ),
                            ],
                          ),

                          // ------------------------------
                          // OTHER DETAILS TAB (UPDATED)
                          // ------------------------------
                          ListView(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 16),
                            children: [

                              // -------- PARTY CATEGORY (UPDATED) --------
                              _label("Party Category"),
                              GestureDetector(
                                onTap: _openCategorySelector,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F8FF),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE5E4F3),
                                        width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _partyCategoryName.text.isEmpty
                                            ? "Select Category"
                                            : _partyCategoryName.text,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _partyCategoryName
                                              .text.isEmpty
                                              ? Colors.black38
                                              : Colors.black87,
                                        ),
                                      ),
                                      const Icon(Icons.expand_more,
                                          color: Colors.black54),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              _label("Contact Person Name"),
                              TextField(
                                controller: _contactPersonName,
                                decoration: _boxDecoration(
                                    hint: "Ex: Ankit Mishra"),
                              ),
                              const SizedBox(height: 16),

                              // ListTile(
                              //   contentPadding: EdgeInsets.zero,
                              //   title: const Text("Date of Birth",
                              //       style: TextStyle(fontWeight: FontWeight.w600)),
                              //   subtitle: Text(
                              //     _dob == null ? "Select DOB" : dateFmt.format(_dob!),
                              //     style: const TextStyle(color: Colors.black54),
                              //   ),
                              //   trailing: const Icon(Icons.calendar_today_rounded),
                              //   onTap: () async {
                              //     final picked = await showDatePicker(
                              //       context: context,
                              //       initialDate: _dob ?? DateTime(1996),
                              //       firstDate: DateTime(1900),
                              //       lastDate: DateTime.now(),
                              //     );
                              //     if (picked != null) setState(() => _dob = picked);
                              //   },
                              // ),

                              _label("Date of Birth"),

                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _dob ?? DateTime(1996),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _dob = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F8FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E4F3), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _dob == null ? "Ex: 25 Aug 1999" : dateFmt.format(_dob!),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _dob == null ? Colors.black38 : Colors.black87,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),


                            ],
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // SAVE BUTTON
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saving ? null : _saveFullParty,
                    child: _saving
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text("Save",
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }

  // PARTY TYPE CHIP
  Widget _partyTypeChip(String label, String value, Color primary) {
    final selected = partyType == value;
    return GestureDetector(
      onTap: () => setState(() => partyType = value),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color:
          selected ? primary.withOpacity(0.15) : const Color(0xFFF1F1F7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: selected ? primary : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? primary : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _balanceTypeChip(String label, String value) {
    final selected = openingBalanceType == value;
    return GestureDetector(
      onTap: () => setState(() => openingBalanceType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? widget.primary.withOpacity(0.15) : const Color(0xFFF1F1F7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? widget.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? widget.primary : Colors.black87,
          ),
        ),
      ),
    );
  }


  // SAVE PARTY
  Future<void> _saveFullParty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      final body = {
        "party_name": _partyName.text.trim(),
        "contact_number": _contactNumber.text.trim(),
        "party_type": partyType,
        "gst_number":
        _gstNumber.text.trim().isEmpty ? null : _gstNumber.text.trim(),
        "pan_number":
        _panNumber.text.trim().isEmpty ? null : _panNumber.text.trim(),
        "billing_street": billingAddress?.street,
        "billing_state": billingAddress?.state,
        "billing_pincode": billingAddress?.pincode,
        "billing_city": billingAddress?.city,
        "opening_balance":
        double.tryParse(_openingBalance.text.trim()) ?? 0,
        "opening_balance_type": openingBalanceType, // ✅ ADD THIS
        "credit_period_days": selectedCreditDays ?? 0,
        "credit_limit":
        double.tryParse(_creditLimit.text.trim()) ?? 0,
        "party_category_id": null,
        "contact_person_name":
        _contactPersonName.text.trim().isEmpty
            ? null
            : _contactPersonName.text.trim(),
        "dob": _dob == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_dob!),
      };

      // final res = await http.post(
      //   Uri.parse('$baseUrl/parties'),
      //   headers: {
      //     "Content-Type": "application/json",
      //     "Accept": "application/json",
      //     "Authorization": "Bearer $token",
      //   },
      //   body: jsonEncode(body),
      // );
      // final isEdit = widget.initialParty != null;
      //
      // final uri = isEdit
      //     ? Uri.parse('$baseUrl/parties/${widget.initialParty!.id}')
      //     : Uri.parse('$baseUrl/parties');
      //
      // final res = await http.post(
      //   uri,
      //   headers: {
      //     "Content-Type": "application/json",
      //     "Accept": "application/json",
      //     "Authorization": "Bearer $token",
      //   },
      //   body: jsonEncode(body),
      // );

      final isEdit = widget.initialParty != null;

      final uri = isEdit
          ? Uri.parse('$baseUrl/parties/${widget.initialParty!.id}')
          : Uri.parse('$baseUrl/parties');

      final res = isEdit
          ? await http.put( // ✅ PUT FOR UPDATE
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      )
          : await http.post( // ✅ POST FOR CREATE
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );



      // if (res.statusCode == 200 || res.statusCode == 201) {
      //   final json = jsonDecode(res.body);
      //   Navigator.pop(context, PartyModel.fromJson(json['data']));
      // }

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (mounted) {
          Navigator.of(context).pop(
            PartyModel.fromJson(json['data']),
          );
        }
      }

    } finally {
      setState(() => _saving = false);
    }
  }
}



// --------------------------------------------------
// 4. Billing Address bottom sheet (UPDATED UI LIKE SCREENSHOT 2)
// --------------------------------------------------

class BillingAddress {
  final String street;
  final String state;
  final String pincode;
  final String city;

  BillingAddress({
    required this.street,
    required this.state,
    required this.pincode,
    required this.city,
  });
}

class BillingAddressSheet extends StatefulWidget {
  final BillingAddress? initial;

  const BillingAddressSheet({super.key, this.initial});

  @override
  State<BillingAddressSheet> createState() => _BillingAddressSheetState();
}

class _BillingAddressSheetState extends State<BillingAddressSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _street = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _city = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _street.text = widget.initial!.street;
      _state.text = widget.initial!.state;
      _pincode.text = widget.initial!.pincode;
      _city.text = widget.initial!.city;
    }
  }

  // SAME BOX STYLE AS SCREENSHOT 2
  InputDecoration _inputBox(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F3FF),
      hintStyle: const TextStyle(
        color: Color(0xFFB8B8C8),
        fontSize: 15,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E4F3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4C3FF0), width: 1.4),
      ),
    );
  }

  // LABEL STYLE (outside box)
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF545454),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    "Add Billing Address",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // STREET
                    _label("Street Address *"),
                    TextFormField(
                      controller: _street,
                      decoration: _inputBox(
                        "Ex: 15, Hill View Apt, LBS Marg",
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 14),

                    // STATE + PINCODE ROW
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("State"),
                              TextFormField(
                                controller: _state,
                                decoration: _inputBox("Ex: Maharashtra"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Pincode"),
                              TextFormField(
                                controller: _pincode,
                                keyboardType: TextInputType.number,
                                decoration: _inputBox("Ex: 560076"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // CITY
                    _label("City"),
                    TextFormField(
                      controller: _city,
                      decoration: _inputBox("Ex: Bengaluru"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C3FF0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saveAddress,
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;

    final addr = BillingAddress(
      street: _street.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
      city: _city.text.trim(),
    );

    Navigator.pop(context, addr);
  }
}

