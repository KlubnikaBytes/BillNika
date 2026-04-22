import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import '../models/party_model.dart';
import 'select_party_sheet.dart';
import 'add_items_screen.dart';
import 'create_invoice_screen.dart';

import 'purchase_invoice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'scan_upload_screen.dart';


const String baseUrl = 'http://192.168.1.12:8000/api';

class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() =>
      _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {

  String purchaseNo = "";

  PartyModel? selectedParty;

  double discountPercent = 0;
  double discountAmount = 0;
  double roundOff = 0;
  double tcsAmount = 0;
  double receivedAmount = 0;
  double balanceAmount = 0;

  bool showAdditionalCharges = false;
  bool showDiscount = false;
  bool showRoundOff = false;
  bool showReceived = false;
  bool showNotes = false;

  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController roundOffCtrl = TextEditingController();
  final TextEditingController receivedCtrl = TextEditingController();

  List<AdditionalCharge> additionalCharges = [];

  double totalAmount = 0.0; // ✅ NEW
  List<InvoiceItem> items = []; // ✅ ADD THIS
  double totalTax = 0.0; // ✅ ADD THIS

  List<String> states = [
    "Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chhattisgarh",
    "Goa","Gujarat","Haryana","Himachal Pradesh","Jharkhand",
    "Karnataka","Kerala","Madhya Pradesh","Maharashtra","Manipur",
    "Meghalaya","Mizoram","Nagaland","Odisha","Punjab",
    "Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura",
    "Uttar Pradesh","Uttarakhand","West Bengal",
    "Andaman and Nicobar Islands","Chandigarh","Dadra and Nagar Haveli and Daman and Diu",
    "Delhi","Jammu and Kashmir","Ladakh","Lakshadweep","Puducherry"
  ];

  String? selectedState;

  double getFinalTotal() {
    double additional =
    additionalCharges.fold(0, (s, e) => s + e.amount);

    return totalAmount +
        totalTax +   // ✅ ADD THIS (VERY IMPORTANT)
        additional -
        discountAmount +
        roundOff +
        tcsAmount;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Create Purchase",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanUploadScreen(),
                  ),
                );

                if (result != null) {
                  _fillData(result);
                }
              },
              child: const Icon(Icons.print_outlined, color: Colors.deepPurple),
            ),
          )
        ],
      ),

      // ✅ BODY
      body: Column(
        children: [

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  // ================= TOP =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            Text(
                              "Purchase # (Auto)",
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.deepPurple),
                              ),
                              child: const Text("EDIT"),
                            )
                          ],
                        ),

                        const SizedBox(height: 6),

                        const Text("Original Invoice # -",
                            style: TextStyle(color: Colors.black54)),

                        const SizedBox(height: 6),

                        Text(
                          "${DateFormat('dd MMM yyyy').format(DateTime.now())} - 7 day(s) to due",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= PARTY =================
                  _sectionTitle("PARTY NAME *"),

                  GestureDetector(
                    onTap: () async {
                      final PartyModel? party =
                      await showModalBottomSheet<PartyModel>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        builder: (_) => const SelectPartySheet(
                          primary: Color(0xFF4C3FF0),
                        ),
                      );

                      if (party != null) {
                        setState(() {
                          selectedParty = party;
                        });
                      }
                    },

                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.grey),
                          const SizedBox(width: 10),

                          Expanded(
                            child: selectedParty == null
                                ? const Text(
                              "Search/Create Party",
                              style: TextStyle(color: Colors.grey),
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedParty!.partyName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  selectedParty!.contactNumber ?? "",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= PLACE OF SUPPLY (ONLY AFTER SELECT) =================
                  if (selectedParty != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child:
                      // Row(
                      //   children: [
                      //     const Expanded(
                      //       child:
                      //       Text(
                      //         "Place of Supply - Gujarat",
                      //         style: TextStyle(
                      //             fontWeight: FontWeight.w500),
                      //       ),
                      //     ),
                      //     Container(
                      //       padding: const EdgeInsets.symmetric(
                      //           horizontal: 12, vertical: 6),
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(20),
                      //         border: Border.all(
                      //             color: Colors.deepPurple),
                      //       ),
                      //       child: const Text(
                      //         "EDIT",
                      //         style: TextStyle(
                      //             color: Colors.deepPurple),
                      //       ),
                      //     )
                      //   ],
                      // ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          DropdownButtonFormField<String>(
                            value: selectedState,
                            hint: const Text("Select Place of Supply"),
                            items: states.map((state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedState = value;
                              });
                            },
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.deepPurple),
                              ),
                              child: const Text(
                                "EDIT",
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                            ),
                          )
                        ],
                      )
                    ),

                  const SizedBox(height: 10),

                  // ================= ITEMS =================

                  _sectionTitle("ITEMS"),

                  if (items.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: GestureDetector(
                        onTap: _openItems,
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEBFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              "Add Items",
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (items.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            "ITEMS (${items.length})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _openItems,
                            child: const Text("+ Item"),
                          )
                        ],
                      ),
                    ),

                    ...items.map((item) => _itemTile(item)).toList(),
                  ],

                  const SizedBox(height: 20),

                  // ================= TOTAL (ONLY AFTER SELECT) =================

                  // if (selectedParty != null)
                  //   Container(
                  //     padding: const EdgeInsets.all(16),
                  //     color: Colors.white,
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //
                  //         // ================= SUBTOTAL =================
                  //         _row("Item Subtotal", totalAmount),
                  //
                  //         const SizedBox(height: 8),
                  //
                  //         // ================= ADDITIONAL =================
                  //         if (!showAdditionalCharges)
                  //           _rightAction("+ Additional Charges", () {
                  //             setState(() {
                  //               showAdditionalCharges = true;
                  //               additionalCharges.add(AdditionalCharge());
                  //             });
                  //           }),
                  //
                  //         if (showAdditionalCharges)
                  //           Column(
                  //             children: additionalCharges.map((c) {
                  //               return Row(
                  //                 children: [
                  //                   Expanded(
                  //                     child: TextField(
                  //                       controller: c.nameCtrl,
                  //                       decoration: const InputDecoration(
                  //                         hintText: "Charge Name",
                  //                       ),
                  //                     ),
                  //                   ),
                  //                   SizedBox(
                  //                     width: 100,
                  //                     child: TextField(
                  //                       controller: c.amountCtrl,
                  //                       keyboardType: TextInputType.number,
                  //                       decoration: const InputDecoration(
                  //                         prefixText: "₹ ",
                  //                       ),
                  //                       onChanged: (_) => setState(() {}),
                  //                     ),
                  //                   )
                  //                 ],
                  //               );
                  //             }).toList(),
                  //           ),
                  //
                  //         // ================= DISCOUNT =================
                  //         if (!showDiscount)
                  //           _rightAction("+ Discount", () {
                  //             setState(() => showDiscount = true);
                  //           }),
                  //
                  //         if (showDiscount)
                  //           Row(
                  //             children: [
                  //               const Text("Discount %"),
                  //               const Spacer(),
                  //               SizedBox(
                  //                 width: 80,
                  //                 child: TextField(
                  //                   keyboardType: TextInputType.number,
                  //                   // onChanged: (v) {
                  //                   //   setState(() {
                  //                   //     discountPercent = double.tryParse(v) ?? 0;
                  //                   //     discountAmount =
                  //                   //         totalAmount * discountPercent / 100;
                  //                   //   });
                  //                   // },
                  //                   onChanged: (v) {
                  //                     setState(() {
                  //                       discountPercent = double.tryParse(v) ?? 0;
                  //
                  //                       double baseAmount = totalAmount +
                  //                           additionalCharges.fold(0, (s, e) => s + e.amount);
                  //
                  //                       discountAmount = baseAmount * discountPercent / 100;
                  //                     });
                  //                   },
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //
                  //         // ================= ROUND OFF =================
                  //         if (!showRoundOff)
                  //           _rightAction("+ Round Off", () {
                  //             setState(() => showRoundOff = true);
                  //           }),
                  //
                  //         if (showRoundOff)
                  //           Row(
                  //             children: [
                  //               const Text("Round Off"),
                  //               const Spacer(),
                  //               SizedBox(
                  //                 width: 100,
                  //                 child: TextField(
                  //                   controller: roundOffCtrl,
                  //                   onChanged: (v) {
                  //                     setState(() {
                  //                       roundOff = double.tryParse(v) ?? 0;
                  //                     });
                  //                   },
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //
                  //         // ================= TCS =================
                  //         _rightAction("+ Apply TCS", () async {
                  //           final ctrl = TextEditingController();
                  //           final val = await showDialog<double>(
                  //             context: context,
                  //             builder: (_) => AlertDialog(
                  //               title: const Text("TCS"),
                  //               content: TextField(controller: ctrl),
                  //               actions: [
                  //                 TextButton(
                  //                   onPressed: () =>
                  //                       Navigator.pop(context, double.tryParse(ctrl.text) ?? 0),
                  //                   child: const Text("Apply"),
                  //                 )
                  //               ],
                  //             ),
                  //           );
                  //
                  //           if (val != null) {
                  //             setState(() => tcsAmount = val);
                  //           }
                  //         }),
                  //
                  //         const Divider(),
                  //
                  //         // ================= TOTAL =================
                  //         // _row(
                  //         //   "Total Amount",
                  //         //   totalAmount +
                  //         //       additionalCharges.fold(0, (s, e) => s + e.amount) -
                  //         //       discountAmount +
                  //         //       roundOff +
                  //         //       tcsAmount,
                  //         //   bold: true,
                  //         // ),
                  //         _row(
                  //           "Total Amount",
                  //           getFinalTotal(),
                  //           bold: true,
                  //         ),
                  //
                  //         const SizedBox(height: 6),
                  //
                  //         // ================= AMOUNT PAID =================
                  //         // if (!showReceived)
                  //         //   _rightAction("+ Amount Paid", () {
                  //         //     setState(() {
                  //         //       showReceived = true;
                  //         //       receivedCtrl.text = totalAmount.toString();
                  //         //     });
                  //         //   }),
                  //         if (!showReceived)
                  //           _rightAction("+ Amount Paid", () {
                  //             setState(() {
                  //               showReceived = true;
                  //
                  //               double finalTotal = getFinalTotal();
                  //
                  //               receivedCtrl.text = finalTotal.toString();
                  //               receivedAmount = finalTotal;
                  //               balanceAmount = 0;
                  //             });
                  //           }),
                  //
                  //         if (showReceived)
                  //           Column(
                  //             children: [
                  //               Row(
                  //                 children: [
                  //                   const Text("Amount Paid"),
                  //                   const Spacer(),
                  //                   SizedBox(
                  //                     width: 120,
                  //                     child: TextField(
                  //                       controller: receivedCtrl,
                  //                       // onChanged: (v) {
                  //                       //   setState(() {
                  //                       //     receivedAmount =
                  //                       //         double.tryParse(v) ?? 0;
                  //                       //     balanceAmount =
                  //                       //         totalAmount - receivedAmount;
                  //                       //   });
                  //                       // },
                  //
                  //                       onChanged: (v) {
                  //                         setState(() {
                  //                           receivedAmount = double.tryParse(v) ?? 0;
                  //
                  //                           double finalTotal = getFinalTotal();
                  //
                  //                           // balanceAmount = finalTotal - receivedAmount;
                  //                           balanceAmount = getFinalTotal() - receivedAmount;
                  //                         });
                  //                       },
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //               Row(
                  //                 children: [
                  //                   const Text("Balance"),
                  //                   const Spacer(),
                  //                   Text("₹ ${balanceAmount.toStringAsFixed(2)}"),
                  //                 ],
                  //               ),
                  //             ],
                  //           ),
                  //
                  //         // ================= NOTES =================
                  //         _rightAction("+ Notes", () {
                  //           setState(() => showNotes = true);
                  //         }),
                  //
                  //         if (showNotes)
                  //           TextField(
                  //             controller: notesCtrl,
                  //             maxLines: 3,
                  //             decoration: const InputDecoration(
                  //               hintText: "Enter notes",
                  //             ),
                  //           ),
                  //       ],
                  //     ),
                  //   ),
                  if (selectedParty != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ✅ ONLY TOTAL WHEN NO ITEMS
                          if (items.isEmpty) ...[
                            _row("Total Amount", 0.0, bold: true),
                          ],

                          // ✅ SHOW FULL UI WHEN ITEMS EXIST
                          if (items.isNotEmpty) ...[

                            _row("Item Subtotal", totalAmount),

                            const SizedBox(height: 8),

                            _rightAction("+ Additional Charges", () {
                              setState(() {
                                showAdditionalCharges = true;
                                additionalCharges.add(AdditionalCharge());
                              });
                            }),

                            // if (showAdditionalCharges)
                            //   Column(
                            //     children: additionalCharges.map((c) {
                            //       return Row(
                            //         children: [
                            //           Expanded(
                            //             child: TextField(
                            //               controller: c.nameCtrl,
                            //               decoration: const InputDecoration(
                            //                 hintText: "Charge Name",
                            //               ),
                            //             ),
                            //           ),
                            //           SizedBox(
                            //             width: 100,
                            //             child: TextField(
                            //               controller: c.amountCtrl,
                            //               keyboardType: TextInputType.number,
                            //               decoration: const InputDecoration(
                            //                 prefixText: "₹ ",
                            //               ),
                            //               onChanged: (_) => setState(() {}),
                            //             ),
                            //           )
                            //         ],
                            //       );
                            //     }).toList(),
                            //   ),

                            if (showAdditionalCharges)
                              Column(
                                children: List.generate(additionalCharges.length, (index) {
                                  final c = additionalCharges[index];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [

                                        // 🔴 NAME FIELD
                                        Expanded(
                                          child: TextField(
                                            controller: c.nameCtrl,
                                            decoration: InputDecoration(
                                              hintText: "Charge Name",
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10), // ✅ SPACE FIX

                                        // 🔵 AMOUNT FIELD
                                        SizedBox(
                                          width: 110,
                                          child: TextField(
                                            controller: c.amountCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              prefixText: "₹ ",
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            // onChanged: (_) => setState(() {}),
                                            onChanged: (_) {
                                              setState(() {
                                                updateBalance(); // ✅ ADD THIS
                                              });
                                            },
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // ❌ REMOVE BUTTON
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              additionalCharges.removeAt(index);
                                              updateBalance(); // ✅ ADD THIS
                                            });
                                          },
                                          child: const Icon(Icons.close, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),

                            _rightAction("+ Discount", () {
                              setState(() => showDiscount = true);
                            }),

                            if (showDiscount)
                              Row(
                                children: [
                                  const Text("Discount %"),
                                  const Spacer(),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        setState(() {
                                          discountPercent = double.tryParse(v) ?? 0;

                                          double baseAmount = totalAmount +
                                              additionalCharges.fold(0, (s, e) => s + e.amount);

                                          discountAmount = baseAmount * discountPercent / 100;
                                          updateBalance(); // ✅ ADD THIS
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                            _rightAction("+ Round Off", () {
                              setState(() => showRoundOff = true);
                            }),

                            if (showRoundOff)
                              Row(
                                children: [
                                  const Text("Round Off"),
                                  const Spacer(),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: roundOffCtrl,
                                      onChanged: (v) {
                                        setState(() {
                                          roundOff = double.tryParse(v) ?? 0;
                                          updateBalance(); // ✅ ADD THIS
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                            _rightAction("+ Apply TCS", () async {
                              final ctrl = TextEditingController();
                              final val = await showDialog<double>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("TCS"),
                                  content: TextField(controller: ctrl),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, double.tryParse(ctrl.text) ?? 0),
                                      child: const Text("Apply"),
                                    )
                                  ],
                                ),
                              );

                              if (val != null) {
                                setState(() => tcsAmount = val);
                              }
                            }),

                            const Divider(),

                            _row("Total Amount", getFinalTotal(), bold: true),

                            const SizedBox(height: 6),

                            _rightAction("+ Amount Paid", () {
                              setState(() {
                                showReceived = true;

                                double finalTotal = getFinalTotal();
                                receivedCtrl.text = finalTotal.toString();
                                receivedAmount = finalTotal;
                                balanceAmount = 0;
                              });
                            }),

                            if (showReceived)
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text("Amount Paid"),
                                      const Spacer(),
                                      SizedBox(
                                        width: 120,
                                        child: TextField(
                                          controller: receivedCtrl,
                                          onChanged: (v) {
                                            setState(() {
                                              receivedAmount = double.tryParse(v) ?? 0;
                                              balanceAmount = getFinalTotal() - receivedAmount;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text("Balance"),
                                      const Spacer(),
                                      Text("₹ ${balanceAmount.toStringAsFixed(2)}"),
                                    ],
                                  ),
                                ],
                              ),

                            _rightAction("+ Notes", () {
                              setState(() => showNotes = true);
                            }),

                            if (showNotes)
                              TextField(
                                controller: notesCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: "Enter notes",
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),


                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ================= BOTTOM BUTTONS =================
          if (selectedParty != null)
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                MediaQuery.of(context).padding.bottom + 6, // ✅ THIS FIX
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 55,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text(
                          "Save & New",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: savePurchase, // ✅ THIS IS IMPORTANT
                      child: Container(
                        height: 55,
                        color: const Color(0xFF4C3FF0),
                        child: const Center(
                          child: Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  void _fillData(Map data) {
    setState(() {

      selectedState = data['place_of_supply'];

      selectedParty = PartyModel.fromJson(data['party']);

      items = (data['items'] as List)
          .map((e) => InvoiceItem.fromJson(e))
          .toList();

      totalAmount = items.fold(0, (sum, item) => sum + item.lineTotal);
    });
  }

  void updateBalance() {
    double finalTotal = getFinalTotal();

    // if user has not edited amount manually → auto update
    if (receivedCtrl.text.isEmpty) {
      receivedAmount = finalTotal;
      receivedCtrl.text = finalTotal.toStringAsFixed(2);
    }

    balanceAmount = finalTotal - receivedAmount;
  }

  Future<void> savePurchase() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final body = {
      // "purchase_number": purchaseNo,
      "purchase_number": "PUR-${DateTime.now().millisecondsSinceEpoch}",
      "purchase_date": DateTime.now().toString(),

      "place_of_supply": selectedState,

      "party_id": selectedParty!.id,

      "items": items.map((e) => e.toApiJson()).toList(),

      "additional_charges":
      additionalCharges.map((e) => e.toApiJson()).toList(),

      "discount_percent": discountPercent,
      "discount_amount": discountAmount,
      "round_off": roundOff,
      "tcs_amount": tcsAmount,

      "received_amount": receivedAmount,
      "payment_mode": "Cash",

      "notes": notesCtrl.text,
    };

    final res = await http.post(
      Uri.parse("$baseUrl/purchases"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // builder: (_) => InvoicePreviewScreen(invoiceData: data["data"]),
          builder: (_) => PurchaseInvoiceScreen(data: data["data"]),
        ),
      );
    } else {
      print(data);
    }
  }

  Widget _rightAction(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4C3FF0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontWeight:
                bold ? FontWeight.bold : FontWeight.w500)),
        const Spacer(),
        Text("₹ ${value.toStringAsFixed(2)}",
            style: TextStyle(
                fontWeight:
                bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  Widget _itemTile(InvoiceItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Text(
                //   "${item.qty} ${item.unit} x ${item.price}",
                //   style: const TextStyle(color: Colors.black54),
                // ),

                // Text(
                //   "${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2)} "
                //       "${item.unit} x ${item.price.toStringAsFixed(2)}",
                //   style: const TextStyle(color: Colors.black54),
                // ),

                Row(
                  children: [
                    const SizedBox(
                      width: 90, // 🔥 controls alignment
                      child: Text(
                        "Qty x Rate",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),

                    Text(
                      "${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2)} "
                          "${item.unit} x ${item.price.toStringAsFixed(1)}",
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),

                if (item.gstPercent > 0)
                  // Text(
                  //   "Tax ${item.gstPercent}% = ₹ ${item.gstAmount.toStringAsFixed(0)}",
                  //   style: const TextStyle(color: Colors.black54),
                  // ),
                  // Text(
                  //   "Tax ${item.gstPercent.toStringAsFixed(1)}% = ₹ ${item.gstAmount.toStringAsFixed(2)}",
                  //   style: const TextStyle(color: Colors.black54),
                  // ),

                  if (item.gstPercent > 0)
                    Row(
                      children: [
                        const SizedBox(
                          width: 90,
                          child: Text(
                            "Tax",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),

                        Text(
                          "${item.gstPercent.toStringAsFixed(1)}% = ₹ ${item.gstAmount.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text(
              //   "₹ ${item.lineTotal.toStringAsFixed(0)}",
              //   style: const TextStyle(fontWeight: FontWeight.bold),
              // ),
              Text(
                "₹ ${item.lineTotal.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: _openItems,
                child: const Text("EDIT"),
              )
            ],
          )
        ],
      ),
    );
  }

  void _openItems() async {
    final result = await Navigator.push<List<InvoiceItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemsScreen(
          existingItems: items,
          isPurchase: true,
        ),
      ),
    );

    if (result != null) {
      // setState(() {
      //   items = result;
      //
      //   totalAmount = items.fold(
      //     0,
      //         (sum, item) => sum + item.lineTotal,
      //   );
      // });

      // setState(() {
      //   items = result;
      //
      //   totalAmount = items.fold(
      //     0,
      //         (sum, item) => sum + item.lineTotal,
      //   );
      //
      //   // ✅ AUTO SET PAID
      //   // double finalTotal = totalAmount +
      //   //     additionalCharges.fold(0, (s, e) => s + e.amount) -
      //   //     discountAmount +
      //   //     roundOff +
      //   //     tcsAmount;
      //   double finalTotal = getFinalTotal();
      //
      //   showReceived = true;
      //   receivedCtrl.text = finalTotal.toString();
      //   receivedAmount = finalTotal;
      //   balanceAmount = 0;
      // });

      setState(() {
        items = result;

        totalAmount = items.fold(
          0,
              (sum, item) => sum + ((item.qty * item.price)), // ✅ WITHOUT TAX
        );

        totalTax = items.fold(
          0,
              (sum, item) => sum + item.gstAmount, // ✅ TAX SEPARATE
        );

        double finalTotal = getFinalTotal();

        showReceived = true;
        receivedCtrl.text = finalTotal.toString();
        receivedAmount = finalTotal;
        balanceAmount = 0;
      });
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}