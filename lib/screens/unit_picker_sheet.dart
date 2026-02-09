import 'package:flutter/material.dart';

class UnitPickerSheet extends StatefulWidget {
  final String? initialUnit;
  const UnitPickerSheet({super.key, this.initialUnit});

  @override
  State<UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<UnitPickerSheet> {
  String? primaryUnit;
  String? alternateUnit;
  final TextEditingController conversionCtrl =
  TextEditingController(text: "1.0");

  final TextEditingController searchCtrl = TextEditingController();

  static const List<String> allUnits = [
    "PIECES (PCS)",
    "KILOGRAM (KG)",
    "LITRE (LTR)",
    "BOX (BOX)",
    "NOS (NOS)",
    "PAIR (PRS)",
    "QUINTAL (QTL)",
    "ROLLS (ROL)",
    "SETS (SET)",
    "SQUARE FEET (SQF)",
    "SQUARE METERS (SQM)",
    "TABLETS (TBS)",
    "TONNES (TON)",
    "TUBES (TUB)",
    "WATT (W)",
    "KILOWATT (KW)",
    "COURSE (COURSE)",
    "RUPEES (RS)",
    "COPY (COPY)",
    "CARAT (CT)",
  ];

  List<String> filteredUnits = List.from(allUnits);

  @override
  void initState() {
    super.initState();
    primaryUnit = widget.initialUnit ?? "PIECES (PCS)";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  "Measuring Unit",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, primaryUnit),
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // ================= CONTENT =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // -------- PRIMARY UNIT --------
                const Text("Primary Unit",
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                _selectField(
                  value: primaryUnit,
                  hint: "Select Unit",
                  removable: true,
                  onClear: () {
                    setState(() {
                      primaryUnit = null;
                      alternateUnit = null;
                      conversionCtrl.text = "1.0";
                    });
                  },
                  onTap: () => _openUnitList(isPrimary: true),
                ),

                const SizedBox(height: 14),

                // -------- + ALTERNATE UNIT --------
                if (primaryUnit != null && alternateUnit == null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openUnitList(isPrimary: false),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Alternate Unit"),
                    ),
                  ),

                // -------- ALTERNATE UNIT --------
                if (alternateUnit != null) ...[
                  const SizedBox(height: 10),
                  const Text("Alternate Unit",
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  _selectField(
                    value: alternateUnit,
                    hint: "Select Unit",
                    removable: true,
                    onClear: () {
                      setState(() {
                        alternateUnit = null;
                        conversionCtrl.text = "1.0";
                      });
                    },
                    onTap: () => _openUnitList(isPrimary: false),
                  ),

                  const SizedBox(height: 14),

                  // -------- CONVERSION RATE --------
                  const Text("Conversion Rate",
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text("1 ($primaryUnit) = "),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: conversionCtrl,
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        alternateUnit = null;
                        conversionCtrl.text = "1.0";
                      });
                    },
                    icon: const Icon(Icons.close),
                    label: const Text("Remove Alternate Units"),
                  ),
                ],
              ],
            ),
          ),

          // ================= SAVE =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, primaryUnit),
                child: const Text("Save"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // UNIT LIST WITH SEARCH
  // ===========================================================
  void _openUnitList({required bool isPrimary}) {
    filteredUnits = List.from(allUnits);
    searchCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    hintText: "Search Unit",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    setState(() {
                      filteredUnits = allUnits
                          .where((u) =>
                          u.toLowerCase().contains(v.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredUnits.length,
                  itemBuilder: (_, i) {
                    final unit = filteredUnits[i];
                    return ListTile(
                      title: Text(unit),
                      onTap: () {
                        setState(() {
                          if (isPrimary) {
                            primaryUnit = unit;
                            alternateUnit = null;
                            conversionCtrl.text = "1.0";
                          } else {
                            alternateUnit = unit;
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================
  // COMMON SELECT FIELD
  // ===========================================================
  Widget _selectField({
    String? value,
    required String hint,
    required VoidCallback onTap,
    bool removable = false,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              value ?? hint,
              style: TextStyle(
                  color: value == null ? Colors.grey : Colors.black),
            ),
            const Spacer(),
            if (removable && value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18),
              )
            else
              const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
