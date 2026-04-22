
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'party_flow_screens.dart';
import 'add_items_screen.dart';
import 'invoice_preview_screen.dart';
import '../models/party_model.dart';
import 'package:flutter_project/widgets/app_background.dart';



const String baseUrl = 'http://192.168.1.12:8000/api';
// const String baseUrl = "http://10.0.2.2:8000/api";


class CreateInvoiceScreen extends StatefulWidget {
  // const CreateInvoiceScreen({super.key});
  final PartyModel? preselectedParty; // ✅ ADD

  const CreateInvoiceScreen({
    super.key,
    this.preselectedParty,
  });


  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final Color primary = const Color(0xFF4C3FF0);

  String invoiceNumberDisplay = "Invoice #1";
  String invoiceCode = "INV-1";
  DateTime invoiceDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));

  PartyModel? selectedParty;

  List<InvoiceItem> items = [];
  double subtotal = 0;
  double totalTax = 0;
  double grandTotal = 0;

  List<AdditionalCharge> additionalCharges = [];


  double discountPercent = 0; // ✅ NEW

  double discountAmount = 0;
  double roundOff = 0;
  double tcsAmount = 0;

  final TextEditingController roundOffCtrl = TextEditingController();
  final TextEditingController receivedCtrl = TextEditingController();

  bool isAutoRoundOff = false; // 🔁 toggle
  double autoRoundStep = 1.0;  // 1.0 or 0.5


  double receivedAmount=0;
  double balanceAmount=0;
  String paymentMode = "Cash";


  String placeOfSupply = "West Bengal";

  bool _loading = false;

  bool showAdditionalCharges = false;

  bool showDiscount = false; // 👈 ADD

  bool showRoundOff = false;

  bool showReceivedAmount = false;

  bool showNotes = false;
  final TextEditingController notesCtrl = TextEditingController();






  final dateFormatter = DateFormat('dd MMM yyyy');

  final List<String> indiaStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",

    // Union Territories
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Jammu and Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry"
  ];

  // ------------------------------------------------------------------
  // ⭐ UPDATE PART → AUTO FETCH LAST INVOICE NUMBER
  // ------------------------------------------------------------------


  @override
  void initState() {
    super.initState();
    _fetchLastInvoiceNumber();

    receivedCtrl.text = "0.00"; // ✅ ADD THIS

    if (widget.preselectedParty != null) {
      selectedParty = widget.preselectedParty; // ✅ AUTO SELECT
    }
  }


  Future<void> _fetchLastInvoiceNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/invoices/last-number"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        int lastNo = data["last_number"] ?? 0;
        int newNo = lastNo + 1;

        setState(() {
          invoiceCode = "INV-$newNo";
          invoiceNumberDisplay = "Invoice #$newNo";
        });
      }
    } catch (e) {
      debugPrint("Error fetching invoice number: $e");
    }
  }
  // ------------------------------------------------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        foregroundColor: Colors.black,
        title: const Text(
          "Create Bill / Invoice",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // body: Column(
      //   children: [
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildInvoiceHeader(),
                  const SizedBox(height: 20),
                  _buildPartySection(),
                  const SizedBox(height: 24),
                  _buildItemsSection(),
                  _buildTotalSection(),
                ],
              ),
            ),

            // Bottom button
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.of(context).padding.bottom + 10, // ✅ FIX HERE
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white, // ✅ ADD THIS
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _loading ? null : _generateBill,
                      child: _loading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Generate Bill",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        "Your data is safe.",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        " Only you can see this data",
                        style: TextStyle(color: Colors.black54),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------ UI pieces ------------------------

  Widget _buildInvoiceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice number + edit button
        Row(
          children: [
            Text(
              invoiceNumberDisplay,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3F3D56)),
            ),
            const Spacer(),
            SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: _editInvoiceDates,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "EDIT",
                  style: TextStyle(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "${dateFormatter.format(invoiceDate)}  -  7 day(s) to due",
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildPartySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PARTY NAME *",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openSelectPartySheet,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.black54),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedParty?.partyName ?? "Search/Create Party",
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedParty == null
                          ? Colors.black38
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed:
            selectedParty == null ? null : () => _editExistingParty(),
            child: const Text(
              "+ Edit Party",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4C3FF0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Place of supply row (like your later screenshot)
        if (selectedParty != null) ...[
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                "Place of Supply",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Text(
                "- $placeOfSupply",
                style: const TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              TextButton(
                onPressed: _editPlaceOfSupply,
                child: const Text(
                  "EDIT",
                  style: TextStyle(
                    color: Color(0xFF4C3FF0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          )
        ],
      ],
    );
  }


  Widget _buildItemsSection() {
    final bool hasItems = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= HEADER =================
        Row(
          children: [
            Text(
              hasItems ? "ITEMS (${items.length})" : "ITEMS",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),

            // ✅ Show +Item ONLY when items already exist
            if (hasItems)
              TextButton(
                onPressed: _openItemsPlaceholder,
                child: const Text(
                  "+ Item",
                  style: TextStyle(
                    color: Color(0xFF4C3FF0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // ================= ADD ITEMS BUTTON =================
        // ✅ Show only when NO items exist
        if (!hasItems)
          GestureDetector(
            onTap: _openItemsPlaceholder,
            child: Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Add Items",
                style: TextStyle(
                  color: Color(0xFF4C3FF0),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),

        // ================= ITEM LIST =================
        if (hasItems) ...[
          const Divider(),

          ...items.map((item) => _invoiceItemTile(item)).toList(),
        ],
      ],
    );
  }


  Widget _invoiceItemTile(InvoiceItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Qty x Rate   ${item.qty} ${item.unit} x ${item.price}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),

                // ✅ TAX LINE (LIKE SCREENSHOT 2)
                if (item.gstPercent > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Tax ${item.gstPercent}% = ₹ ${item.gstAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // RIGHT
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹ ${item.lineTotal.toStringAsFixed(2)}", // ✅ WITH TAX
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: _openItemsPlaceholder,
                child: const Text("EDIT"),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTotalSection() {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),

        _row("Item Subtotal Without Tax", subtotal),

        const SizedBox(height: 8),

        // ================= RIGHT SIDE "+ Additional Charges" =================
        if (!showAdditionalCharges)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  showAdditionalCharges = true;
                  if (additionalCharges.isEmpty) {
                    additionalCharges.add(AdditionalCharge());
                  }
                });
              },
              child: const Text(
                "+ Additional Charges",
                style: TextStyle(
                  color: Color(0xFF4C3FF0),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        // ================= DROPDOWN HEADER (AFTER CLICK) =================
        if (showAdditionalCharges) ...[
          const SizedBox(height: 10),

          InkWell(
            onTap: () {
              setState(() {
                showAdditionalCharges = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                  const SizedBox(width: 6),
                  const Text(
                    "ADD ADDITIONAL CHARGES",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.add, color: Color(0xFF4C3FF0)),
                ],
              ),
            ),
          ),

          // ================= EXPANDED CONTENT =================
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                ...additionalCharges.asMap().entries.map((entry) {
                  final index = entry.key;
                  final charge = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              additionalCharges.removeAt(index);
                              recalculateTotal();
                              if (additionalCharges.isEmpty) {
                                showAdditionalCharges = false;
                              }
                            });
                          },
                        ),


                        Expanded(
                          child: TextField(
                            controller: charge.nameCtrl, // ✅ ADD HERE
                            decoration: const InputDecoration(
                              hintText: "Charge Name",
                              isDense: true,
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: charge.amountCtrl, // ✅ ADD HERE
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixText: "₹ ",
                              isDense: true,
                              border: UnderlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setState(() {
                                recalculateTotal();
                              });
                            },
                          ),
                        ),

                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        additionalCharges.add(AdditionalCharge());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Additional Charge"),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // ================= RIGHT ACTIONS =================
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [


              // ================= DISCOUNT =================
              if (!showDiscount)
                _rightAction("+ Discount", () {
                  setState(() {
                    showDiscount = true;
                  });
                }),

              if (showDiscount)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ❌ Remove discount
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            showDiscount = false;
                            discountPercent = 0;
                            discountAmount = 0;
                            recalculateTotal();
                          });
                        },
                      ),

                      // Label (left side)
                      const Expanded(
                        flex: 2,
                        child: Text(
                          "Discount After Tax",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // % input
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: "%",
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setState(() {
                              discountPercent = double.tryParse(v) ?? 0;
                              discountAmount = subtotal * (discountPercent / 100);
                              recalculateTotal();
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ₹ auto-calculated (right side)
                      SizedBox(
                        width: 90,
                        child: TextField(
                          readOnly: true,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: "₹",
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                          controller: TextEditingController(
                            text: discountAmount == 0
                                ? ""
                                : discountAmount.toStringAsFixed(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),



              if (!showRoundOff)
                _rightAction("+ Round Off", () {
                  setState(() {
                    showRoundOff = true;
                    roundOff = 0;
                    roundOffCtrl.text = "0";
                    recalculateTotal();
                  });
                }),



              // ================= ROUND OFF (INLINE) =================
              if (showRoundOff)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // ❌ remove round off
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            showRoundOff = false;
                            roundOff = 0;
                            roundOffCtrl.clear();
                            recalculateTotal();
                          });
                        },

                      ),

                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            const Text(
                              "Round Off",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: isAutoRoundOff,
                              onChanged: (v) {
                                setState(() {
                                  isAutoRoundOff = v;
                                  recalculateTotal();
                                });
                              },
                            ),
                            // ✅ ADD THIS DROPDOWN RIGHT HERE
                            if (isAutoRoundOff)
                              DropdownButton<double>(
                                value: autoRoundStep,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 1.0,
                                    child: Text("₹1"),
                                  ),
                                  DropdownMenuItem(
                                    value: 0.5,
                                    child: Text("₹0.5"),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      autoRoundStep = v;
                                      recalculateTotal();
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                      ),



                      // ➖ minus
                      GestureDetector(

                        onTap: isAutoRoundOff ? null : () {
                          setState(() {
                            roundOff -= 1;
                            roundOffCtrl.text = roundOff.toStringAsFixed(2);
                            recalculateTotal();
                          });
                        },


                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.remove),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ➕ plus
                      GestureDetector(


                        onTap: isAutoRoundOff ? null : () {
                          setState(() {
                            roundOff += 1;
                            roundOffCtrl.text = roundOff.toStringAsFixed(2);
                            recalculateTotal();
                          });
                        },


                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),

                      const SizedBox(width: 10),

                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: roundOffCtrl,
                          enabled: !isAutoRoundOff,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            prefixText: "₹ ",
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setState(() {
                              roundOff = double.tryParse(v) ?? 0;
                              recalculateTotal();
                            });
                          },
                        ),
                      ),

                    ],
                  ),
                ),


              _rightAction("+ Apply TCS", _editTcs),
            ],
          ),
        ),


        const Divider(),

        _row("Total Amount", grandTotal, bold: true),

        const SizedBox(height: 6),

        // ================= AMOUNT RECEIVED =================
        if (!showReceivedAmount)
          Align(
            alignment: Alignment.centerRight,
            child: _rightAction("+ Amount Received", () {
              setState(() {
                showReceivedAmount = true;
                receivedAmount = grandTotal; // default full payment
                balanceAmount = 0;
                receivedCtrl.text = grandTotal.toStringAsFixed(2); // ✅ ADD THIS
              });
            }),
          ),

        // Align(
        //   alignment: Alignment.centerRight,
        //   child: _rightAction("+ Notes", () {
        //     setState(() {
        //       showNotes = true;
        //     });
        //   }),
        // ),

        // + Notes button
        Align(
          alignment: Alignment.centerRight,
          child: _rightAction("+ Notes", () {
            setState(() {
              showNotes = true;
            });
          }),
        ),

// Notes input (independent of Amount Received)
        if (showNotes)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      showNotes = false;
                      notesCtrl.clear();
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Type your notes here",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),



        if (showReceivedAmount) ...[
          const SizedBox(height: 10),

          // Received Amount row
          Row(
            children: [
              const Text(
                "Received Amount",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    prefixText: "₹ ",
                    isDense: true,
                    border: UnderlineInputBorder(),
                  ),
                  // controller: TextEditingController(
                  //   text: receivedAmount.toStringAsFixed(2),
                  // ),
                  controller: receivedCtrl,
                  // onChanged: (v) {
                  //   setState(() {
                  //     receivedAmount = double.tryParse(v) ?? 0;
                  //     balanceAmount = grandTotal - receivedAmount;
                  //   });
                  // },
                  onChanged: (v) {
                    receivedAmount = double.tryParse(v) ?? 0;
                    balanceAmount = grandTotal - receivedAmount;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Balance Amount row
          Row(
            children: [
              const Text(
                "Balance Amount",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Text(
                "₹ ${balanceAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const SizedBox(height: 12),

// ===== PAYMENT MODE (LABEL LEFT, DROPDOWN RIGHT) =====
          Row(
            children: [
              const Text(
                "Payment Mode",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),

              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: paymentMode,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: const [
                      DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      DropdownMenuItem(value: "UPI", child: Text("UPI")),
                      DropdownMenuItem(value: "Card", child: Text("Card")),
                      DropdownMenuItem(value: "Net Banking", child: Text("Net Banking")),
                      DropdownMenuItem(value: "Cheque", child: Text("Cheque")),
                      DropdownMenuItem(value: "Bank transfer", child: Text("Bank transfer")),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => paymentMode = v);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),


        ],

      ],
    );
  }




  Widget _actionLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4C3FF0), // same purple
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }



  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            "₹ ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableRow(
      String label,
      double value, {
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              "+ $label",
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text("₹ ${value.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
// EDIT METHODS FOR TOTAL SECTION (FIX RED ERRORS)
// ------------------------------------------------------------

  Future<void> _editDiscount() async {
    final percentCtrl =
    TextEditingController(text: discountPercent.toStringAsFixed(0));

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Discount"),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: percentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Discount %",
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text("%"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("APPLY"),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        discountPercent = double.tryParse(percentCtrl.text) ?? 0;

        // ✅ CALCULATE DISCOUNT AMOUNT FROM SUBTOTAL
        discountAmount = subtotal * (discountPercent / 100);

        recalculateTotal();
      });
    }
  }


  Future<void> _editTcs() async {
    final controller = TextEditingController(text: tcsAmount.toString());

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("TCS"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "TCS Amount",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                double.tryParse(controller.text) ?? 0,
              );
            },
            child: const Text("APPLY"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        tcsAmount = result;
        recalculateTotal();
      });
    }
  }


  // ------------------------ Actions ------------------------

  Future<void> _editInvoiceDates() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        invoiceDate = picked;
        dueDate = picked.add(const Duration(days: 7));
      });
    }
  }

  Future<void> _openSelectPartySheet() async {
    final PartyModel? result = await showModalBottomSheet<PartyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SelectPartySheet(primary: primary),
    );

    if (result != null) {
      setState(() {
        selectedParty = result;
      });
    }
  }

  // editing existing party can simply reopen CreateNewPartyScreen with initial data
  Future<void> _editExistingParty() async {
    if (selectedParty == null) return;

    final updated = await Navigator.push<PartyModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateNewPartyScreen(
          primary: primary,
          initialParty: selectedParty,
        ),
      ),
    );

    if (updated != null) {
      setState(() => selectedParty = updated);
    }
  }

  Future<void> _editPlaceOfSupply() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: indiaStates.length,
          itemBuilder: (context, index) {
            final state = indiaStates[index];

            return ListTile(
              title: Text(state),
              trailing: state == placeOfSupply
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context, state);
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        placeOfSupply = result;
      });
    }
  }

  void _openItemsPlaceholder() async {
    final updatedItems = await Navigator.push<List<InvoiceItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemsScreen(
          // 🔴 PASS CURRENT ITEMS ONLY ONCE
          existingItems: items,
        ),
      ),
    );


    if (updatedItems != null) {
      setState(() {
        items = updatedItems; // ✅ DIRECT ASSIGN — NO MERGE
        recalculateTotal();
      });
    }

  }



  // void recalculateTotal() {
  //   // subtotal = items.fold(0.0, (sum, e) => sum + (e.qty * e.price));
  //   // subtotal = items.fold(0.0, (sum, e) => sum + e.lineTotal);
  //   subtotal = items.fold(0.0, (sum, e) => sum + ((e.qty * e.price) - e.discount),);
  //   totalTax = items.fold(0.0, (sum, e) => sum + e.gstAmount);
  //
  //
  //
  //
  //   final double extraChargesTotal =
  //   additionalCharges.fold(0.0, (sum, c) => sum + c.amount);
  //
  //
  //   double total = subtotal;
  //   total += extraChargesTotal;
  //   total -= discountAmount;
  //
  //   if (isAutoRoundOff) {
  //     final rounded = calculateAutoRound(total, autoRoundStep);
  //     roundOff = rounded - total;
  //     roundOffCtrl.text = roundOff.toStringAsFixed(2);
  //     total = rounded;
  //   } else {
  //     total += roundOff;
  //   }
  //
  //   total += tcsAmount;
  //
  //
  //   setState(() {
  //     grandTotal = total;
  //   });
  // }

  void recalculateTotal() {
    subtotal = items.fold(
      0.0,
          (sum, e) => sum + ((e.qty * e.price) - e.discount),
    );

    totalTax = items.fold(0.0, (sum, e) => sum + e.gstAmount);

    final double extraChargesTotal =
    additionalCharges.fold(0.0, (sum, c) => sum + c.amount);

    double total = subtotal + totalTax;
    total += extraChargesTotal;
    total -= discountAmount;

    if (isAutoRoundOff) {
      final rounded = calculateAutoRound(total, autoRoundStep);
      roundOff = rounded - total;
      roundOffCtrl.text = roundOff.toStringAsFixed(2);
      total = rounded;
    } else {
      total += roundOff;
    }

    total += tcsAmount;

    grandTotal = double.parse(total.toStringAsFixed(2));

    balanceAmount =
        double.parse((grandTotal - receivedAmount).toStringAsFixed(2));

    setState(() {});
  }


  double calculateAutoRound(double amount, double step) {
    return (amount / step).round() * step;
  }


  Future<void> _generateBill() async {
    if (selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a party first.")),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add items")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      // ================= PAYMENT FIX =================
      double finalReceivedAmount;
      double finalBalanceAmount;
      String? finalPaymentMode;

      if (showReceivedAmount) {
        finalReceivedAmount = receivedAmount;
        finalBalanceAmount = balanceAmount;
        finalPaymentMode = paymentMode;
      } else {
        // ❌ User did NOT click "+ Amount Received"
        finalReceivedAmount = 0;
        finalBalanceAmount = grandTotal;
        finalPaymentMode = null;
      }


      final body = {
        "invoice_number": invoiceCode,
        "invoice_date": DateFormat('yyyy-MM-dd').format(invoiceDate),
        "due_date": DateFormat('yyyy-MM-dd').format(dueDate),
        "party_id": selectedParty!.id,
        "place_of_supply": placeOfSupply,

        "subtotal": subtotal,
        "additional_charges":
        additionalCharges.map((e) => e.toApiJson()).toList(),

        "discount_percent": discountPercent,


        "discount_amount": discountAmount,
        "round_off": roundOff,
        "tcs_amount": tcsAmount,

        // // ✅ PAYMENT DATA
        // "received_amount": receivedAmount,
        // "balance_amount": balanceAmount,
        // "payment_mode": paymentMode,

        // ✅ CORRECT (SAFE)
        "received_amount": finalReceivedAmount,
        "balance_amount": finalBalanceAmount,
        "payment_mode": finalPaymentMode,


        "notes": notesCtrl.text, // ✅ ADDED

        "grand_total": grandTotal,

        "items": items.map((e) => e.toApiJson()).toList(),
      };


      final res = await http.post(
        Uri.parse("$baseUrl/invoices"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {

        // SUCCESS → GO TO INVOICE PREVIEW
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoicePreviewScreen(invoiceData: data["data"]),
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

}

// ------------------------------------------------------------
// Models used by invoice & parties
// ------------------------------------------------------------

class InvoiceItem {
  final int itemId;
  final String description;
  final double qty;
  final String unit;
  final double price;
  final double discount;
  final double gstPercent;

  InvoiceItem({
    required this.itemId,
    required this.description,
    required this.qty,
    required this.unit,
    required this.price,
    this.discount = 0,
    this.gstPercent = 0,
  });

  // 👇 ADD HERE
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      itemId: json['item_id'] ?? 0,
      description: json['description'] ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'PCS',
      price: (json['price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      gstPercent: (json['gst_percent'] ?? 0).toDouble(),
    );
  }



  // ✅ TAX AMOUNT
  double get gstAmount {
    final taxable = (qty * price) - discount;
    return taxable * (gstPercent / 100);
  }

  // ✅ FINAL LINE TOTAL (WITH TAX)
  double get lineTotal {
    return ((qty * price) - discount) + gstAmount;
  }

  Map<String, dynamic> toApiJson() {
    return {
      "item_id": itemId,
      "qty": qty,
      "unit": unit,
      "price": price,
      "discount": discount,
      "gst_percent": gstPercent,
    };
  }

  InvoiceItem copyWith({
    double? qty,
  }) {
    return InvoiceItem(
      itemId: itemId,
      description: description,
      qty: qty ?? this.qty,
      unit: unit,
      price: price,
      discount: discount,
      gstPercent: gstPercent,
    );
  }

}


// ================= ADD THIS BELOW InvoiceItem =================

class AdditionalCharge {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;

  AdditionalCharge({
    String name = '',
    double amount = 0,
  })  : nameCtrl = TextEditingController(text: name),
        amountCtrl = TextEditingController(
          text: amount == 0 ? '' : amount.toString(),
        );

  double get amount =>
      double.tryParse(amountCtrl.text) ?? 0;

  Map<String, dynamic> toApiJson() {
    return {
      "name": nameCtrl.text,
      "amount": amount,
    };
  }
}


// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'party_flow_screens.dart';
// import 'add_items_screen.dart';
// import 'invoice_preview_screen.dart';
// import '../models/party_model.dart';
// import 'package:flutter_project/widgets/app_background.dart';
//
//
//
// const String baseUrl = 'http://192.168.1.12:8000/api';
// // const String baseUrl = "http://10.0.2.2:8000/api";
//
//
// class CreateInvoiceScreen extends StatefulWidget {
//   // const CreateInvoiceScreen({super.key});
//   final PartyModel? preselectedParty; // ✅ ADD
//   // ✅ ADD THIS
//   final String type; // "sale" or "purchase"
//
//   const CreateInvoiceScreen({
//     super.key,
//     this.preselectedParty,
//     // ✅ ADD DEFAULT
//     this.type = "sale",
//   });
//
//
//   @override
//   State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
// }
//
// class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
//   final Color primary = const Color(0xFF4C3FF0);
//
//   String invoiceNumberDisplay = "Invoice #1";
//   String invoiceCode = "INV-1";
//   DateTime invoiceDate = DateTime.now();
//   DateTime dueDate = DateTime.now().add(const Duration(days: 7));
//
//   PartyModel? selectedParty;
//
//   List<InvoiceItem> items = [];
//   double subtotal = 0;
//   double totalTax = 0;
//   double grandTotal = 0;
//
//   List<AdditionalCharge> additionalCharges = [];
//
//
//   double discountPercent = 0; // ✅ NEW
//
//   double discountAmount = 0;
//   double roundOff = 0;
//   double tcsAmount = 0;
//
//   final TextEditingController roundOffCtrl = TextEditingController();
//   final TextEditingController receivedCtrl = TextEditingController();
//
//   bool isAutoRoundOff = false; // 🔁 toggle
//   double autoRoundStep = 1.0;  // 1.0 or 0.5
//
//
//   double receivedAmount=0;
//   double balanceAmount=0;
//   String paymentMode = "Cash";
//
//
//   String placeOfSupply = "West Bengal";
//
//   bool _loading = false;
//
//   bool showAdditionalCharges = false;
//
//   bool showDiscount = false; // 👈 ADD
//
//   bool showRoundOff = false;
//
//   bool showReceivedAmount = false;
//
//   bool showNotes = false;
//   final TextEditingController notesCtrl = TextEditingController();
//
//
//
//
//
//
//
//   final dateFormatter = DateFormat('dd MMM yyyy');
//
//   final List<String> indiaStates = [
//     "Andhra Pradesh",
//     "Arunachal Pradesh",
//     "Assam",
//     "Bihar",
//     "Chhattisgarh",
//     "Goa",
//     "Gujarat",
//     "Haryana",
//     "Himachal Pradesh",
//     "Jharkhand",
//     "Karnataka",
//     "Kerala",
//     "Madhya Pradesh",
//     "Maharashtra",
//     "Manipur",
//     "Meghalaya",
//     "Mizoram",
//     "Nagaland",
//     "Odisha",
//     "Punjab",
//     "Rajasthan",
//     "Sikkim",
//     "Tamil Nadu",
//     "Telangana",
//     "Tripura",
//     "Uttar Pradesh",
//     "Uttarakhand",
//     "West Bengal",
//
//     // Union Territories
//     "Andaman and Nicobar Islands",
//     "Chandigarh",
//     "Dadra and Nagar Haveli and Daman and Diu",
//     "Delhi",
//     "Jammu and Kashmir",
//     "Ladakh",
//     "Lakshadweep",
//     "Puducherry"
//   ];
//
//   // ------------------------------------------------------------------
//   // ⭐ UPDATE PART → AUTO FETCH LAST INVOICE NUMBER
//   // ------------------------------------------------------------------
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _fetchLastInvoiceNumber();
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchLastInvoiceNumber();
//
//     receivedCtrl.text = "0.00"; // ✅ ADD THIS
//
//     if (widget.preselectedParty != null) {
//       selectedParty = widget.preselectedParty; // ✅ AUTO SELECT
//     }
//   }
//
//
//   Future<void> _fetchLastInvoiceNumber() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("token") ?? "";
//
//     try {
//       final res = await http.get(
//         Uri.parse("$baseUrl/invoices/last-number"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Accept": "application/json",
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//
//         int lastNo = data["last_number"] ?? 0;
//         int newNo = lastNo + 1;
//
//         setState(() {
//           invoiceCode = "INV-$newNo";
//           invoiceNumberDisplay = "Invoice #$newNo";
//         });
//       }
//     } catch (e) {
//       debugPrint("Error fetching invoice number: $e");
//     }
//   }
//   // ------------------------------------------------------------------
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: Colors.white,
//
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.4,
//         foregroundColor: Colors.black,
//         // title: const Text(
//         //   "Create Bill / Invoice",
//         //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//         // ),
//
//         title: Text(
//           widget.type == "purchase"
//               ? "Create Purchase"
//               : "Create Bill / Invoice",
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {},
//             icon: const Icon(Icons.receipt_long_outlined),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//
//       // body: Column(
//       //   children: [
//       body: AppBackground(
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 children: [
//                   _buildInvoiceHeader(),
//                   const SizedBox(height: 20),
//                   _buildPartySection(),
//                   const SizedBox(height: 24),
//                   _buildItemsSection(),
//                   _buildTotalSection(),
//                 ],
//               ),
//             ),
//
//             // Bottom button
//             Container(
//               color: Colors.white,
//               padding: EdgeInsets.fromLTRB(
//                 16,
//                 10,
//                 16,
//                 MediaQuery.of(context).padding.bottom + 10, // ✅ FIX HERE
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(
//                     width: double.infinity,
//                     height: 52,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primary,
//                         foregroundColor: Colors.white, // ✅ ADD THIS
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       onPressed: _loading ? null : _generateBill,
//                       child: _loading
//                           ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.4,
//                           color: Colors.white,
//                         ),
//                       )
//                           : Text(
//                         widget.type == "purchase"
//                             ? "Save Purchase"
//                             : "Generate Bill",
//                       )
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.lock_outline, size: 16, color: Colors.green),
//                       SizedBox(width: 6),
//                       Text(
//                         "Your data is safe.",
//                         style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
//                       ),
//                       Text(
//                         " Only you can see this data",
//                         style: TextStyle(color: Colors.black54),
//                       )
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ------------------------ UI pieces ------------------------
//
//   Widget _buildInvoiceHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Invoice number + edit button
//         Row(
//           children: [
//             Text(
//               invoiceNumberDisplay,
//               style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF3F3D56)),
//             ),
//             const Spacer(),
//             SizedBox(
//               height: 34,
//               child: OutlinedButton(
//                 onPressed: _editInvoiceDates,
//                 style: OutlinedButton.styleFrom(
//                   side: BorderSide(color: Colors.grey.shade300),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//                 child: const Text(
//                   "EDIT",
//                   style: TextStyle(
//                       letterSpacing: 0.5,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87),
//                 ),
//               ),
//             )
//           ],
//         ),
//         const SizedBox(height: 6),
//         Text(
//           "${dateFormatter.format(invoiceDate)}  -  7 day(s) to due",
//           style: const TextStyle(
//             color: Colors.black54,
//             fontSize: 14,
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Divider(height: 1),
//       ],
//     );
//   }
//
//   Widget _buildPartySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "PARTY NAME *",
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.3,
//           ),
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: _openSelectPartySheet,
//           child: Container(
//             height: 56,
//             padding: const EdgeInsets.symmetric(horizontal: 14),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.grey.shade300),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.person_outline, color: Colors.black54),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     selectedParty?.partyName ?? "Search/Create Party",
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: selectedParty == null
//                           ? Colors.black38
//                           : Colors.black87,
//                     ),
//                   ),
//                 ),
//                 const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Align(
//           alignment: Alignment.centerRight,
//           child: TextButton(
//             onPressed:
//             selectedParty == null ? null : () => _editExistingParty(),
//             child: const Text(
//               "+ Edit Party",
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF4C3FF0),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//
//         // Place of supply row (like your later screenshot)
//         if (selectedParty != null) ...[
//           const Divider(height: 1),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               const Text(
//                 "Place of Supply",
//                 style: TextStyle(
//                     fontWeight: FontWeight.w600, color: Colors.black87),
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 "- $placeOfSupply",
//                 style: const TextStyle(color: Colors.black54),
//               ),
//               const Spacer(),
//               TextButton(
//                 onPressed: _editPlaceOfSupply,
//                 child: const Text(
//                   "EDIT",
//                   style: TextStyle(
//                     color: Color(0xFF4C3FF0),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               )
//             ],
//           )
//         ],
//       ],
//     );
//   }
//
//
//   Widget _buildItemsSection() {
//     final bool hasItems = items.isNotEmpty;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ================= HEADER =================
//         Row(
//           children: [
//             Text(
//               hasItems ? "ITEMS (${items.length})" : "ITEMS",
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const Spacer(),
//
//             // ✅ Show +Item ONLY when items already exist
//             if (hasItems)
//               TextButton(
//                 onPressed: _openItemsPlaceholder,
//                 child: const Text(
//                   "+ Item",
//                   style: TextStyle(
//                     color: Color(0xFF4C3FF0),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//
//         const SizedBox(height: 10),
//
//         // ================= ADD ITEMS BUTTON =================
//         // ✅ Show only when NO items exist
//         if (!hasItems)
//           GestureDetector(
//             onTap: _openItemsPlaceholder,
//             child: Container(
//               height: 60,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF3F1FF),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Text(
//                 "Add Items",
//                 style: TextStyle(
//                   color: Color(0xFF4C3FF0),
//                   fontWeight: FontWeight.w600,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//
//         // ================= ITEM LIST =================
//         if (hasItems) ...[
//           const Divider(),
//
//           ...items.map((item) => _invoiceItemTile(item)).toList(),
//         ],
//       ],
//     );
//   }
//
//   // Widget _invoiceItemTile(InvoiceItem item) {
//   //   return Padding(
//   //     padding: const EdgeInsets.symmetric(vertical: 10),
//   //     child: Row(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         // LEFT
//   //         Expanded(
//   //           child: Column(
//   //             crossAxisAlignment: CrossAxisAlignment.start,
//   //             children: [
//   //               Text(
//   //                 item.description,
//   //                 style: const TextStyle(
//   //                   fontSize: 15,
//   //                   fontWeight: FontWeight.w600,
//   //                 ),
//   //               ),
//   //               const SizedBox(height: 4),
//   //               Text(
//   //                 "Qty x Rate   ${item.qty} ${item.unit} x ${item.price}",
//   //                 style: const TextStyle(
//   //                   fontSize: 13,
//   //                   color: Colors.black54,
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //
//   //         // RIGHT
//   //         Column(
//   //           crossAxisAlignment: CrossAxisAlignment.end,
//   //           children: [
//   //             Text(
//   //               "₹ ${(item.qty * item.price).toStringAsFixed(2)}",
//   //               style: const TextStyle(
//   //                 fontSize: 15,
//   //                 fontWeight: FontWeight.w600,
//   //               ),
//   //             ),
//   //             const SizedBox(height: 6),
//   //             OutlinedButton(
//   //               onPressed: _openItemsPlaceholder,
//   //               style: OutlinedButton.styleFrom(
//   //                 padding:
//   //                 const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//   //                 shape: RoundedRectangleBorder(
//   //                   borderRadius: BorderRadius.circular(20),
//   //                 ),
//   //               ),
//   //               child: const Text("EDIT"),
//   //             )
//   //           ],
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   Widget _invoiceItemTile(InvoiceItem item) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // LEFT
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   item.description,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//
//                 const SizedBox(height: 4),
//
//                 Text(
//                   "Qty x Rate   ${item.qty} ${item.unit} x ${item.price}",
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.black54,
//                   ),
//                 ),
//
//                 // ✅ TAX LINE (LIKE SCREENSHOT 2)
//                 if (item.gstPercent > 0)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2),
//                     child: Text(
//                       "Tax ${item.gstPercent}% = ₹ ${item.gstAmount.toStringAsFixed(2)}",
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//
//           // RIGHT
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 "₹ ${item.lineTotal.toStringAsFixed(2)}", // ✅ WITH TAX
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               OutlinedButton(
//                 onPressed: _openItemsPlaceholder,
//                 child: const Text("EDIT"),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildTotalSection() {
//     if (items.isEmpty) return const SizedBox.shrink();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Divider(),
//
//         _row("Item Subtotal Without Tax", subtotal),
//
//         const SizedBox(height: 8),
//
//         // ================= RIGHT SIDE "+ Additional Charges" =================
//         if (!showAdditionalCharges)
//           Align(
//             alignment: Alignment.centerRight,
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   showAdditionalCharges = true;
//                   if (additionalCharges.isEmpty) {
//                     additionalCharges.add(AdditionalCharge());
//                   }
//                 });
//               },
//               child: const Text(
//                 "+ Additional Charges",
//                 style: TextStyle(
//                   color: Color(0xFF4C3FF0),
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ),
//
//         // ================= DROPDOWN HEADER (AFTER CLICK) =================
//         if (showAdditionalCharges) ...[
//           const SizedBox(height: 10),
//
//           InkWell(
//             onTap: () {
//               setState(() {
//                 showAdditionalCharges = false;
//               });
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
//                   const SizedBox(width: 6),
//                   const Text(
//                     "ADD ADDITIONAL CHARGES",
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const Spacer(),
//                   const Icon(Icons.add, color: Color(0xFF4C3FF0)),
//                 ],
//               ),
//             ),
//           ),
//
//           // ================= EXPANDED CONTENT =================
//           Padding(
//             padding: const EdgeInsets.only(top: 10),
//             child: Column(
//               children: [
//                 ...additionalCharges.asMap().entries.map((entry) {
//                   final index = entry.key;
//                   final charge = entry.value;
//
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6),
//                     child: Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.close, size: 18),
//                           onPressed: () {
//                             setState(() {
//                               additionalCharges.removeAt(index);
//                               recalculateTotal();
//                               if (additionalCharges.isEmpty) {
//                                 showAdditionalCharges = false;
//                               }
//                             });
//                           },
//                         ),
//
//
//                         Expanded(
//                           child: TextField(
//                             controller: charge.nameCtrl, // ✅ ADD HERE
//                             decoration: const InputDecoration(
//                               hintText: "Charge Name",
//                               isDense: true,
//                               border: UnderlineInputBorder(),
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(width: 8),
//                         SizedBox(
//                           width: 90,
//                           child: TextField(
//                             controller: charge.amountCtrl, // ✅ ADD HERE
//                             keyboardType: TextInputType.number,
//                             decoration: const InputDecoration(
//                               prefixText: "₹ ",
//                               isDense: true,
//                               border: UnderlineInputBorder(),
//                             ),
//                             onChanged: (_) {
//                               setState(() {
//                                 recalculateTotal();
//                               });
//                             },
//                           ),
//                         ),
//
//                       ],
//                     ),
//                   );
//                 }),
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: TextButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         additionalCharges.add(AdditionalCharge());
//                       });
//                     },
//                     icon: const Icon(Icons.add),
//                     label: const Text("Add Additional Charge"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//
//         const SizedBox(height: 12),
//
//         // ================= RIGHT ACTIONS =================
//         Align(
//           alignment: Alignment.centerRight,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//
//
//               // ================= DISCOUNT =================
//               if (!showDiscount)
//                 _rightAction("+ Discount", () {
//                   setState(() {
//                     showDiscount = true;
//                   });
//                 }),
//
//               if (showDiscount)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       // ❌ Remove discount
//                       IconButton(
//                         icon: const Icon(Icons.close, size: 18, color: Colors.grey),
//                         onPressed: () {
//                           setState(() {
//                             showDiscount = false;
//                             discountPercent = 0;
//                             discountAmount = 0;
//                             recalculateTotal();
//                           });
//                         },
//                       ),
//
//                       // Label (left side)
//                       const Expanded(
//                         flex: 2,
//                         child: Text(
//                           "Discount After Tax",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//
//                       // % input
//                       SizedBox(
//                         width: 60,
//                         child: TextField(
//                           keyboardType: TextInputType.number,
//                           textAlign: TextAlign.center,
//                           decoration: const InputDecoration(
//                             hintText: "%",
//                             isDense: true,
//                             border: UnderlineInputBorder(),
//                           ),
//                           onChanged: (v) {
//                             setState(() {
//                               discountPercent = double.tryParse(v) ?? 0;
//                               discountAmount = subtotal * (discountPercent / 100);
//                               recalculateTotal();
//                             });
//                           },
//                         ),
//                       ),
//
//                       const SizedBox(width: 8),
//
//                       // ₹ auto-calculated (right side)
//                       SizedBox(
//                         width: 90,
//                         child: TextField(
//                           readOnly: true,
//                           textAlign: TextAlign.right,
//                           decoration: const InputDecoration(
//                             hintText: "₹",
//                             isDense: true,
//                             border: UnderlineInputBorder(),
//                           ),
//                           controller: TextEditingController(
//                             text: discountAmount == 0
//                                 ? ""
//                                 : discountAmount.toStringAsFixed(2),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//
//
//               if (!showRoundOff)
//                 _rightAction("+ Round Off", () {
//                   setState(() {
//                     showRoundOff = true;
//                     roundOff = 0;
//                     roundOffCtrl.text = "0";
//                     recalculateTotal();
//                   });
//                 }),
//
//
//
//               // ================= ROUND OFF (INLINE) =================
//               if (showRoundOff)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: Row(
//                     children: [
//                       // ❌ remove round off
//                       IconButton(
//                         icon: const Icon(Icons.close, size: 18, color: Colors.grey),
//                         onPressed: () {
//                           setState(() {
//                             showRoundOff = false;
//                             roundOff = 0;
//                             roundOffCtrl.clear();
//                             recalculateTotal();
//                           });
//                         },
//
//                       ),
//
//                       Expanded(
//                         flex: 2,
//                         child: Row(
//                           children: [
//                             const Text(
//                               "Round Off",
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                             const SizedBox(width: 8),
//                             Switch(
//                               value: isAutoRoundOff,
//                               onChanged: (v) {
//                                 setState(() {
//                                   isAutoRoundOff = v;
//                                   recalculateTotal();
//                                 });
//                               },
//                             ),
//                             // ✅ ADD THIS DROPDOWN RIGHT HERE
//                             if (isAutoRoundOff)
//                               DropdownButton<double>(
//                                 value: autoRoundStep,
//                                 underline: const SizedBox(),
//                                 items: const [
//                                   DropdownMenuItem(
//                                     value: 1.0,
//                                     child: Text("₹1"),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 0.5,
//                                     child: Text("₹0.5"),
//                                   ),
//                                 ],
//                                 onChanged: (v) {
//                                   if (v != null) {
//                                     setState(() {
//                                       autoRoundStep = v;
//                                       recalculateTotal();
//                                     });
//                                   }
//                                 },
//                               ),
//                           ],
//                         ),
//                       ),
//
//
//
//                       // ➖ minus
//                       GestureDetector(
//
//                         onTap: isAutoRoundOff ? null : () {
//                           setState(() {
//                             roundOff -= 1;
//                             roundOffCtrl.text = roundOff.toStringAsFixed(2);
//                             recalculateTotal();
//                           });
//                         },
//
//
//                         child: Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade200,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.remove),
//                         ),
//                       ),
//
//                       const SizedBox(width: 10),
//
//                       // ➕ plus
//                       GestureDetector(
//
//
//                         onTap: isAutoRoundOff ? null : () {
//                           setState(() {
//                             roundOff += 1;
//                             roundOffCtrl.text = roundOff.toStringAsFixed(2);
//                             recalculateTotal();
//                           });
//                         },
//
//
//                         child: Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: primary,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.add, color: Colors.white),
//                         ),
//                       ),
//
//                       const SizedBox(width: 10),
//
//                       SizedBox(
//                         width: 80,
//                         child: TextField(
//                           controller: roundOffCtrl,
//                           enabled: !isAutoRoundOff,
//                           keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
//                           textAlign: TextAlign.right,
//                           decoration: const InputDecoration(
//                             prefixText: "₹ ",
//                             isDense: true,
//                             border: UnderlineInputBorder(),
//                           ),
//                           onChanged: (v) {
//                             setState(() {
//                               roundOff = double.tryParse(v) ?? 0;
//                               recalculateTotal();
//                             });
//                           },
//                         ),
//                       ),
//
//                     ],
//                   ),
//                 ),
//
//
//               _rightAction("+ Apply TCS", _editTcs),
//             ],
//           ),
//         ),
//
//
//         const Divider(),
//
//         _row("Total Amount", grandTotal, bold: true),
//
//         const SizedBox(height: 6),
//
//         // ================= AMOUNT RECEIVED =================
//         if (!showReceivedAmount)
//           Align(
//             alignment: Alignment.centerRight,
//             child: _rightAction("+ Amount Received", () {
//               setState(() {
//                 showReceivedAmount = true;
//                 receivedAmount = grandTotal; // default full payment
//                 balanceAmount = 0;
//                 receivedCtrl.text = grandTotal.toStringAsFixed(2); // ✅ ADD THIS
//               });
//             }),
//           ),
//
//         // Align(
//         //   alignment: Alignment.centerRight,
//         //   child: _rightAction("+ Notes", () {
//         //     setState(() {
//         //       showNotes = true;
//         //     });
//         //   }),
//         // ),
//
//         // + Notes button
//         Align(
//           alignment: Alignment.centerRight,
//           child: _rightAction("+ Notes", () {
//             setState(() {
//               showNotes = true;
//             });
//           }),
//         ),
//
// // Notes input (independent of Amount Received)
//         if (showNotes)
//           Padding(
//             padding: const EdgeInsets.only(top: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.close, size: 18, color: Colors.grey),
//                   onPressed: () {
//                     setState(() {
//                       showNotes = false;
//                       notesCtrl.clear();
//                     });
//                   },
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: notesCtrl,
//                     maxLines: 3,
//                     decoration: InputDecoration(
//                       hintText: "Type your notes here",
//                       filled: true,
//                       fillColor: Colors.grey.shade100,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//
//
//         if (showReceivedAmount) ...[
//           const SizedBox(height: 10),
//
//           // Received Amount row
//           Row(
//             children: [
//               const Text(
//                 "Received Amount",
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//               const Spacer(),
//               SizedBox(
//                 width: 120,
//                 child: TextField(
//                   keyboardType: TextInputType.number,
//                   textAlign: TextAlign.right,
//                   decoration: const InputDecoration(
//                     prefixText: "₹ ",
//                     isDense: true,
//                     border: UnderlineInputBorder(),
//                   ),
//                   // controller: TextEditingController(
//                   //   text: receivedAmount.toStringAsFixed(2),
//                   // ),
//                   controller: receivedCtrl,
//                   // onChanged: (v) {
//                   //   setState(() {
//                   //     receivedAmount = double.tryParse(v) ?? 0;
//                   //     balanceAmount = grandTotal - receivedAmount;
//                   //   });
//                   // },
//                   onChanged: (v) {
//                     receivedAmount = double.tryParse(v) ?? 0;
//                     balanceAmount = grandTotal - receivedAmount;
//                     setState(() {});
//                   },
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 6),
//
//           // Balance Amount row
//           Row(
//             children: [
//               const Text(
//                 "Balance Amount",
//                 style: TextStyle(
//                   fontWeight: FontWeight.w700,
//                   color: Colors.green,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 "₹ ${balanceAmount.toStringAsFixed(2)}",
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                   color: Colors.green,
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 10),
//
//           const SizedBox(height: 12),
//
// // ===== PAYMENT MODE (LABEL LEFT, DROPDOWN RIGHT) =====
//           Row(
//             children: [
//               const Text(
//                 "Payment Mode",
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black54,
//                 ),
//               ),
//               const Spacer(),
//
//               Container(
//                 height: 42,
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                   color: Colors.white,
//                 ),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     value: paymentMode,
//                     icon: const Icon(Icons.keyboard_arrow_down),
//                     items: const [
//                       DropdownMenuItem(value: "Cash", child: Text("Cash")),
//                       DropdownMenuItem(value: "UPI", child: Text("UPI")),
//                       DropdownMenuItem(value: "Card", child: Text("Card")),
//                       DropdownMenuItem(value: "Net Banking", child: Text("Net Banking")),
//                       DropdownMenuItem(value: "Cheque", child: Text("Cheque")),
//                       DropdownMenuItem(value: "Bank transfer", child: Text("Bank transfer")),
//                     ],
//                     onChanged: (v) {
//                       if (v != null) {
//                         setState(() => paymentMode = v);
//                       }
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//
//         ],
//
//       ],
//     );
//   }
//
//
//
//
//   Widget _actionLink(String text, VoidCallback onTap) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: GestureDetector(
//         onTap: onTap,
//         child: Align(
//           alignment: Alignment.centerLeft,
//           child: Text(
//             text,
//             style: const TextStyle(
//               color: Color(0xFF4C3FF0), // same purple
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _rightAction(String text, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Text(
//           text,
//           style: const TextStyle(
//             color: Color(0xFF4C3FF0),
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
//
//
//
//   Widget _row(String label, double value, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
//             ),
//           ),
//           const Spacer(),
//           Text(
//             "₹ ${value.toStringAsFixed(2)}",
//             style: TextStyle(
//               fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _editableRow(
//       String label,
//       double value, {
//         required VoidCallback onTap,
//       }) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Row(
//           children: [
//             Text(
//               "+ $label",
//               style: const TextStyle(
//                 color: Colors.deepPurple,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const Spacer(),
//             Text("₹ ${value.toStringAsFixed(2)}"),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ------------------------------------------------------------
// // EDIT METHODS FOR TOTAL SECTION (FIX RED ERRORS)
// // ------------------------------------------------------------
//
//   Future<void> _editDiscount() async {
//     final percentCtrl =
//     TextEditingController(text: discountPercent.toStringAsFixed(0));
//
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Discount"),
//         content: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: percentCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: "Discount %",
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             const Text("%"),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("CANCEL"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("APPLY"),
//           ),
//         ],
//       ),
//     );
//
//     if (result == true) {
//       setState(() {
//         discountPercent = double.tryParse(percentCtrl.text) ?? 0;
//
//         // ✅ CALCULATE DISCOUNT AMOUNT FROM SUBTOTAL
//         discountAmount = subtotal * (discountPercent / 100);
//
//         recalculateTotal();
//       });
//     }
//   }
//
//
//   Future<void> _editTcs() async {
//     final controller = TextEditingController(text: tcsAmount.toString());
//
//     final result = await showDialog<double>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("TCS"),
//         content: TextField(
//           controller: controller,
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(
//             labelText: "TCS Amount",
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("CANCEL"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(
//                 context,
//                 double.tryParse(controller.text) ?? 0,
//               );
//             },
//             child: const Text("APPLY"),
//           ),
//         ],
//       ),
//     );
//
//     if (result != null) {
//       setState(() {
//         tcsAmount = result;
//         recalculateTotal();
//       });
//     }
//   }
//
//
//   // ------------------------ Actions ------------------------
//
//   Future<void> _editInvoiceDates() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: invoiceDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         invoiceDate = picked;
//         dueDate = picked.add(const Duration(days: 7));
//       });
//     }
//   }
//
//   Future<void> _openSelectPartySheet() async {
//     final PartyModel? result = await showModalBottomSheet<PartyModel>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
//       ),
//       builder: (_) => SelectPartySheet(primary: primary),
//     );
//
//     if (result != null) {
//       setState(() {
//         selectedParty = result;
//       });
//     }
//   }
//
//   // editing existing party can simply reopen CreateNewPartyScreen with initial data
//   Future<void> _editExistingParty() async {
//     if (selectedParty == null) return;
//
//     final updated = await Navigator.push<PartyModel>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CreateNewPartyScreen(
//           primary: primary,
//           initialParty: selectedParty,
//         ),
//       ),
//     );
//
//     if (updated != null) {
//       setState(() => selectedParty = updated);
//     }
//   }
//
//   Future<void> _editPlaceOfSupply() async {
//     final result = await showModalBottomSheet<String>(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (_) {
//         return ListView.builder(
//           padding: const EdgeInsets.all(10),
//           itemCount: indiaStates.length,
//           itemBuilder: (context, index) {
//             final state = indiaStates[index];
//
//             return ListTile(
//               title: Text(state),
//               trailing: state == placeOfSupply
//                   ? const Icon(Icons.check, color: Colors.green)
//                   : null,
//               onTap: () {
//                 Navigator.pop(context, state);
//               },
//             );
//           },
//         );
//       },
//     );
//
//     if (result != null) {
//       setState(() {
//         placeOfSupply = result;
//       });
//     }
//   }
//
//   void _openItemsPlaceholder() async {
//     final updatedItems = await Navigator.push<List<InvoiceItem>>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => AddItemsScreen(
//           // 🔴 PASS CURRENT ITEMS ONLY ONCE
//           existingItems: items,
//         ),
//       ),
//     );
//
//
//     if (updatedItems != null) {
//       setState(() {
//         items = updatedItems; // ✅ DIRECT ASSIGN — NO MERGE
//         recalculateTotal();
//       });
//     }
//
//   }
//
//
//
//   // void recalculateTotal() {
//   //   // subtotal = items.fold(0.0, (sum, e) => sum + (e.qty * e.price));
//   //   // subtotal = items.fold(0.0, (sum, e) => sum + e.lineTotal);
//   //   subtotal = items.fold(0.0, (sum, e) => sum + ((e.qty * e.price) - e.discount),);
//   //   totalTax = items.fold(0.0, (sum, e) => sum + e.gstAmount);
//   //
//   //
//   //
//   //
//   //   final double extraChargesTotal =
//   //   additionalCharges.fold(0.0, (sum, c) => sum + c.amount);
//   //
//   //
//   //   double total = subtotal;
//   //   total += extraChargesTotal;
//   //   total -= discountAmount;
//   //
//   //   if (isAutoRoundOff) {
//   //     final rounded = calculateAutoRound(total, autoRoundStep);
//   //     roundOff = rounded - total;
//   //     roundOffCtrl.text = roundOff.toStringAsFixed(2);
//   //     total = rounded;
//   //   } else {
//   //     total += roundOff;
//   //   }
//   //
//   //   total += tcsAmount;
//   //
//   //
//   //   setState(() {
//   //     grandTotal = total;
//   //   });
//   // }
//
//   void recalculateTotal() {
//     subtotal = items.fold(
//       0.0,
//           (sum, e) => sum + ((e.qty * e.price) - e.discount),
//     );
//
//     totalTax = items.fold(0.0, (sum, e) => sum + e.gstAmount);
//
//     final double extraChargesTotal =
//     additionalCharges.fold(0.0, (sum, c) => sum + c.amount);
//
//     double total = subtotal + totalTax;
//     total += extraChargesTotal;
//     total -= discountAmount;
//
//     if (isAutoRoundOff) {
//       final rounded = calculateAutoRound(total, autoRoundStep);
//       roundOff = rounded - total;
//       roundOffCtrl.text = roundOff.toStringAsFixed(2);
//       total = rounded;
//     } else {
//       total += roundOff;
//     }
//
//     total += tcsAmount;
//
//     grandTotal = double.parse(total.toStringAsFixed(2));
//
//     balanceAmount =
//         double.parse((grandTotal - receivedAmount).toStringAsFixed(2));
//
//     setState(() {});
//   }
//
//
//   double calculateAutoRound(double amount, double step) {
//     return (amount / step).round() * step;
//   }
//
//
//   Future<void> _generateBill() async {
//     if (selectedParty == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select a party first.")),
//       );
//       return;
//     }
//
//     if (items.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please add items")),
//       );
//       return;
//     }
//
//     setState(() => _loading = true);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? "";
//
//       // ================= PAYMENT FIX =================
//       double finalReceivedAmount;
//       double finalBalanceAmount;
//       String? finalPaymentMode;
//
//       if (showReceivedAmount) {
//         finalReceivedAmount = receivedAmount;
//         finalBalanceAmount = balanceAmount;
//         finalPaymentMode = paymentMode;
//       } else {
//         // ❌ User did NOT click "+ Amount Received"
//         finalReceivedAmount = 0;
//         finalBalanceAmount = grandTotal;
//         finalPaymentMode = null;
//       }
//
//
//       final body = {
//         "invoice_number": invoiceCode,
//         "invoice_date": DateFormat('yyyy-MM-dd').format(invoiceDate),
//         "due_date": DateFormat('yyyy-MM-dd').format(dueDate),
//         "party_id": selectedParty!.id,
//         "place_of_supply": placeOfSupply,
//
//         "subtotal": subtotal,
//         "additional_charges":
//         additionalCharges.map((e) => e.toApiJson()).toList(),
//
//         "discount_percent": discountPercent,
//
//
//         "discount_amount": discountAmount,
//         "round_off": roundOff,
//         "tcs_amount": tcsAmount,
//
//         // // ✅ PAYMENT DATA
//         // "received_amount": receivedAmount,
//         // "balance_amount": balanceAmount,
//         // "payment_mode": paymentMode,
//
//         // ✅ CORRECT (SAFE)
//         "received_amount": finalReceivedAmount,
//         "balance_amount": finalBalanceAmount,
//         "payment_mode": finalPaymentMode,
//
//
//         "notes": notesCtrl.text, // ✅ ADDED
//
//         "grand_total": grandTotal,
//
//         "items": items.map((e) => e.toApiJson()).toList(),
//       };
//
//
//       final res = await http.post(
//         Uri.parse(
//           widget.type == "purchase"
//               ? "$baseUrl/purchases"
//               : "$baseUrl/invoices",
//         ),
//         headers: {
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       );
//
//       final data = jsonDecode(res.body);
//
//       if (res.statusCode == 200 || res.statusCode == 201) {
//
//         // SUCCESS → GO TO INVOICE PREVIEW
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => InvoicePreviewScreen(invoiceData: data["data"]),
//           ),
//         );
//
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed: ${res.body}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
// }
//
// // ------------------------------------------------------------
// // Models used by invoice & parties
// // ------------------------------------------------------------
//
// class InvoiceItem {
//   final int itemId;
//   final String description;
//   final double qty;
//   final String unit;
//   final double price;
//   final double discount;
//   final double gstPercent;
//
//   InvoiceItem({
//     required this.itemId,
//     required this.description,
//     required this.qty,
//     required this.unit,
//     required this.price,
//     this.discount = 0,
//     this.gstPercent = 0,
//   });
//
//
//
//   // ✅ TAX AMOUNT
//   double get gstAmount {
//     final taxable = (qty * price) - discount;
//     return taxable * (gstPercent / 100);
//   }
//
//   // ✅ FINAL LINE TOTAL (WITH TAX)
//   double get lineTotal {
//     return ((qty * price) - discount) + gstAmount;
//   }
//
//   Map<String, dynamic> toApiJson() {
//     return {
//       "item_id": itemId,
//       "qty": qty,
//       "unit": unit,
//       "price": price,
//       "discount": discount,
//       "gst_percent": gstPercent,
//     };
//   }
//
//   InvoiceItem copyWith({
//     double? qty,
//   }) {
//     return InvoiceItem(
//       itemId: itemId,
//       description: description,
//       qty: qty ?? this.qty,
//       unit: unit,
//       price: price,
//       discount: discount,
//       gstPercent: gstPercent,
//     );
//   }
//
// }
//
//
// // ================= ADD THIS BELOW InvoiceItem =================
//
// class AdditionalCharge {
//   final TextEditingController nameCtrl;
//   final TextEditingController amountCtrl;
//
//   AdditionalCharge({
//     String name = '',
//     double amount = 0,
//   })  : nameCtrl = TextEditingController(text: name),
//         amountCtrl = TextEditingController(
//           text: amount == 0 ? '' : amount.toString(),
//         );
//
//   double get amount =>
//       double.tryParse(amountCtrl.text) ?? 0;
//
//   Map<String, dynamic> toApiJson() {
//     return {
//       "name": nameCtrl.text,
//       "amount": amount,
//     };
//   }
// }












