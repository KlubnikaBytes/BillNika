import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/app_background.dart';


class ImeiListScreen extends StatefulWidget {
  final List<String>? initial;

  const ImeiListScreen({super.key, this.initial});

  @override
  State<ImeiListScreen> createState() => _ImeiListScreenState();
}

class _ImeiListScreenState extends State<ImeiListScreen> {
  List<TextEditingController> controllers = [];
  List<bool> showError = [];

  bool startedManual = false;

  @override
  void initState() {
    super.initState();

    // If IMEIs already exist → show inline fields immediately
    if (widget.initial != null && widget.initial!.isNotEmpty) {
      startedManual = true;
      for (var imei in widget.initial!) {
        controllers.add(TextEditingController(text: imei));
        showError.add(false);
      }
    }
  }

  // -------------------------------
  // Add new empty IMEI field
  // -------------------------------
  void addManual() {
    setState(() {
      startedManual = true;
      controllers.add(TextEditingController());
      showError.add(false);
    });
  }

  // -------------------------------
  // Delete individual IMEI field
  // -------------------------------
  void deleteField(int i) {
    setState(() {
      controllers.removeAt(i);
      showError.removeAt(i);
    });
  }

  // -------------------------------
  // Validate all IMEI fields
  // -------------------------------
  bool validateFields() {
    bool ok = true;

    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.trim().isEmpty) {
        showError[i] = true;
        ok = false;
      } else {
        showError[i] = false;
      }
    }

    setState(() {});
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add IMEI/Serial No"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.4,
      ),

        body: AppBackground(
          child: Column(
            children: [
              const SizedBox(height: 20),

          // -------------------------
          // BUTTON ROW
          // -------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: addManual,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Manually"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Scan feature not implemented")),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Scan to Add"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // PLACEHOLDER (show before user adds IMEI manually)
          // ----------------------------------------------------
          if (!startedManual)
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.qr_code, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    "Your IMEI/Serial No will appear here",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You can add IMEI/Serial No by scanning numbers or manually typing",
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text("No IMEI/Serial added yet",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // ----------------------------------------------------
          // INLINE INPUT FIELDS
          // ----------------------------------------------------
          if (startedManual)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controllers.length,
                itemBuilder: (context, i) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controllers[i],
                              decoration: InputDecoration(
                                hintText: "Enter IMEI / Serial No",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (_) {
                                if (controllers[i].text.trim().isNotEmpty) {
                                  setState(() => showError[i] = false);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteField(i),
                          ),
                        ],
                      ),

                      if (showError[i])
                        const Padding(
                          padding: EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            "IMEI/Serial No is required",
                            style:
                            TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),

          // ----------------------------------------------------
          // BOTTOM: COUNT + SAVE BUTTON
          // ----------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Text(
                  "${controllers.length}.0 PCS",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (!validateFields()) return;

                    final imeiList =
                    controllers.map((c) => c.text.trim()).toList();

                    Navigator.pop(context, imeiList);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size(120, 45),
                  ),
                  child: const Text("Save"),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
    );
  }
}
