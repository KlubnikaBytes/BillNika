// --------------------------------------------------------------
// FULL UPDATED FILE WITH IMEI / SERIAL NO (placed ABOVE UNIT)
// --------------------------------------------------------------
import 'dart:convert';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;

import 'create_invoice_screen.dart'; // ⬅️ IMPORTANT (Added)
import 'scan_imei_screen.dart';
import 'unit_picker_sheet.dart';
import 'package:flutter/foundation.dart'; // ✅ REQUIRED


import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:math';

import 'package:flutter_project/widgets/app_background.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';





const String baseUrl = 'http://192.168.1.12:8000/api';
// const String baseUrl = "http://10.0.2.2:8000/api";


class CreateNewItemScreen extends StatefulWidget {
  final Color primary;
  final Map? item; // ✅ ADD THIS

  const CreateNewItemScreen({
    super.key,
    required this.primary,
    this.item, // ✅ ADD THIS
  });


  @override
  State<CreateNewItemScreen> createState() => _CreateNewItemScreenState();
}

// class _CreateNewItemScreenState extends State<CreateNewItemScreen>
//     with SingleTickerProviderStateMixin {
class _CreateNewItemScreenState extends State<CreateNewItemScreen>
    with TickerProviderStateMixin {



  // ------------------------------------------------------------------
  // REQUIRED VARIABLES (FIXED THE RED ERROR)
  // ------------------------------------------------------------------
  bool showImeiRow = false;        // ← now IMEI section appears only after click
  List<String> imeiList = [];      // ← stores IMEI numbers
  String inventoryTracking = "Qty";
  bool barcodeGenerated = false;

  bool lowStockAlert = false;
  TextEditingController lowStockQtyCtrl = TextEditingController();

  bool showInOnlineStore = true; // ✅ default checked




// ADD HERE 👇
  final ScreenshotController _barcodeShot = ScreenshotController();

  // IMAGE PICKER
  File? _itemImage;
  final ImagePicker _picker = ImagePicker();



  //late TabController _tabController;
  TabController? _tabController;


  // BASIC
  TextEditingController nameCtrl = TextEditingController();
  String itemType = "product";

  // PRICING
  String selectedUnit = "PCS";
  TextEditingController salesPriceCtrl = TextEditingController();
  TextEditingController purchasePriceCtrl = TextEditingController();
  String gstPercent = "None";
  TextEditingController hsnCtrl = TextEditingController();

  // STOCK
  TextEditingController openingStockCtrl = TextEditingController();
  DateTime stockAsOfDate = DateTime.now();
  TextEditingController itemCodeCtrl = TextEditingController();
  TextEditingController barcodeCtrl = TextEditingController();


  // CATEGORY
  List<ItemCategory> categories = [];
  // String? selectedCategoryId;
  String? selectedCategoryName;


  // OTHER
  TextEditingController descriptionCtrl = TextEditingController();

  bool saving = false;

  // 👇 ADD HERE
  bool get isEdit => widget.item != null;

  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: 4, vsync: this);
  //   _loadCategories();
  //
  //   // 🔥 LISTEN TO LOW STOCK QTY CHANGES
  //   lowStockQtyCtrl.addListener(() {
  //     setState(() {}); // forces text update below input
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _loadCategories();

    lowStockQtyCtrl.addListener(() {
      setState(() {});
    });

    // =======================
    // ✅ PREFILL FOR EDIT MODE
    // =======================
    if (widget.item != null) {
      final item = widget.item!;

      nameCtrl.text = item['name'] ?? '';
      itemType = item['item_type'] ?? 'product';

      selectedUnit = item['unit'] ?? 'PCS';
      salesPriceCtrl.text = item['sales_price']?.toString() ?? '';
      purchasePriceCtrl.text = item['purchase_price']?.toString() ?? '';

      gstPercent = item['gst_percent'] != null
          ? "GST @ ${item['gst_percent']}%"
          : "None";

      hsnCtrl.text = item['hsn_code'] ?? '';
      openingStockCtrl.text = item['opening_stock']?.toString() ?? '';
      itemCodeCtrl.text = item['item_code'] ?? '';
      barcodeCtrl.text = item['barcode'] ?? '';
      descriptionCtrl.text = item['description'] ?? '';

      lowStockAlert = item['low_stock_alert'] == true;
      lowStockQtyCtrl.text =
          item['low_stock_quantity']?.toString() ?? '';

      showInOnlineStore = item['show_in_online_store'] == true;

      if (item['item_categories'] != null &&
          item['item_categories'].isNotEmpty) {
        selectedCategoryName = item['item_categories'][0];
      }
    }
  }


  // void _initTabs() {
  //   _tabController?.dispose();
  //
  //   final tabCount = itemType == "service" ? 3 : 4;
  //
  //   _tabController = TabController(
  //     length: tabCount,
  //     vsync: this,
  //   );
  // }


  // LOAD CATEGORIES
  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final res = await http.get(
      Uri.parse("$baseUrl/items"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);

      // 🔥 collect unique categories from items
      final Set<String> cats = {};

      for (final item in json["data"]) {
        if (item["item_categories"] != null) {
          for (final c in item["item_categories"]) {
            cats.add(c.toString());
          }
        }
      }

      setState(() {
        categories = cats
            .map((e) => ItemCategory(id: 0, name: e))
            .toList();
      });
    }
  }

  Future<File> compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.path,
      quality: 70,
    );

    final newFile = File(file.path)
      ..writeAsBytesSync(result!);

    return newFile;
  }


  // SAVE ITEM
  Future<void> saveItem() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item name is required")),
      );
      return;
    }
    // ✅ ADD THIS
    if (openingStockCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Opening Stock")),
      );
      return;
    }

    // If inventoryTracking is IMEI, prefer opening stock = number of IMEIs
    if (inventoryTracking == "IMEI") {
      final count = imeiList.length;
      if (openingStockCtrl.text.trim().isEmpty) {
        openingStockCtrl.text = count.toString();
      }
    }

    setState(() => saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final uri = isEdit
          ? Uri.parse("$baseUrl/items/${widget.item!['id']}")
          : Uri.parse("$baseUrl/items");


      // ======================================================
      // 🌐 WEB → JSON (NO IMAGE)
      // 📱 MOBILE → MULTIPART (WITH IMAGE)
      // ======================================================

      if (kIsWeb) {
        // ---------------- WEB ----------------
        final body = {
          "name": nameCtrl.text.trim(),
          "item_type": itemType,
          "inventory_tracking_by":
          inventoryTracking == "IMEI" ? "IMEI" : "Qty",
          "imei_list": imeiList,
          "unit": selectedUnit,
          "sales_price": salesPriceCtrl.text,
          "purchase_price": purchasePriceCtrl.text,
          "gst_percent":
          gstPercent == "None" ? "0" : _extractNumberFromGst(gstPercent),
          "hsn_code": hsnCtrl.text,
          "opening_stock": openingStockCtrl.text,
          "stock_as_of_date":
          DateFormat("yyyy-MM-dd").format(stockAsOfDate),
          "item_code": itemCodeCtrl.text,
          "barcode": barcodeCtrl.text,
          "description": descriptionCtrl.text,
          "low_stock_alert": lowStockAlert,
          "low_stock_quantity":
          lowStockAlert ? lowStockQtyCtrl.text : null,
          "show_in_online_store": showInOnlineStore,

          "item_categories":
          selectedCategoryName != null ? [selectedCategoryName] : [],
        };

        // final res = await http.post(
        //   uri,
        //   headers: {
        //     "Authorization": "Bearer $token",
        //     "Content-Type": "application/json",
        //   },
        //   body: jsonEncode(body),
        // );

        // final res = isEdit
        //     ? await http.put(
        //   uri,
        //   headers: {
        //     "Authorization": "Bearer $token",
        //     "Content-Type": "application/json",
        //   },
        //   body: jsonEncode(body),
        // )
        //     : await http.post(
        //   uri,
        //   headers: {
        //     "Authorization": "Bearer $token",
        //     "Content-Type": "application/json",
        //   },
        //   body: jsonEncode(body),
        // );

        final res = isEdit
            ? await http.put(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
            "Accept": "application/json", // ✅ ADD HERE
          },
          body: jsonEncode(body),
        )
            : await http.post(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
            "Accept": "application/json", // ✅ ADD HERE
          },
          body: jsonEncode(body),
        );

// 🚨 ADD THIS IMMEDIATELY AFTER API CALL
        final contentType = res.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          debugPrint("HTML RESPONSE RECEIVED:");
          debugPrint(res.body);
          throw Exception("API returned HTML instead of JSON");
        }



        // if (res.statusCode == 200 || res.statusCode == 201) {
        //   Navigator.pop(context, true);
        // }
        if (res.statusCode == 200 || res.statusCode == 201) {
          final decoded = jsonDecode(res.body);
          Navigator.pop(context, decoded['data']); // ✅ RETURN UPDATED ITEM
        }

        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.body)),
          );
        }
      } else {
        // ---------------- MOBILE (ANDROID / IOS) ----------------
        final request = http.MultipartRequest("POST", uri);
        request.headers["Accept"] = "application/json"; // ✅ ADD HERE

        if (isEdit) {
          request.fields["_method"] = "PUT"; // ✅ REQUIRED FOR LARAVEL
        }

        request.headers["Authorization"] = "Bearer $token";

        // BASIC
        request.fields["name"] = nameCtrl.text.trim();
        request.fields["item_type"] = itemType;
        request.fields["inventory_tracking_by"] =
        inventoryTracking == "IMEI" ? "IMEI" : "Qty";
        request.fields["unit"] = selectedUnit;
        request.fields["sales_price"] = salesPriceCtrl.text;
        request.fields["purchase_price"] = purchasePriceCtrl.text;
        request.fields["gst_percent"] =
        gstPercent == "None" ? "0" : _extractNumberFromGst(gstPercent);
        request.fields["hsn_code"] = hsnCtrl.text;

        // STOCK
        request.fields["opening_stock"] = openingStockCtrl.text;
        request.fields["stock_as_of_date"] =
            DateFormat("yyyy-MM-dd").format(stockAsOfDate);
        request.fields["item_code"] = itemCodeCtrl.text;
        request.fields["barcode"] = barcodeCtrl.text;

        // OTHER
        request.fields["description"] = descriptionCtrl.text;
        request.fields["low_stock_alert"] = lowStockAlert ? "1" : "0";
        request.fields["show_in_online_store"] =
        showInOnlineStore ? "1" : "0";


        if (lowStockAlert) {
          request.fields["low_stock_quantity"] = lowStockQtyCtrl.text;
        }

        if (selectedCategoryName != null) {
          request.fields["item_categories[0]"] = selectedCategoryName!;
        }

        for (int i = 0; i < imeiList.length; i++) {
          request.fields["imei_list[$i]"] = imeiList[i];
        }

        // if (_itemImage != null) {
        //   request.files.add(
        //     await http.MultipartFile.fromPath(
        //       "image",
        //       _itemImage!.path,
        //     ),
        //   );
        // }
        if (_itemImage != null) {
          final compressed = await compressImage(_itemImage!);

          request.files.add(
            await http.MultipartFile.fromPath(
              "image",
              compressed.path,
            ),
          );
        }

        final streamedRes = await request.send();
        final res = await http.Response.fromStream(streamedRes);

        final contentType = res.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          debugPrint("HTML RESPONSE RECEIVED:");
          debugPrint(res.body);
          throw Exception("API returned HTML instead of JSON");
        }


        // if (res.statusCode == 200 || res.statusCode == 201) {
        //   Navigator.pop(context, true);
        //
        // }
        if (res.statusCode == 200 || res.statusCode == 201) {
          final decoded = jsonDecode(res.body);
          Navigator.pop(context, decoded['data']); // ✅ RETURN UPDATED ITEM
        }

        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.body)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => saving = false);
    }
  }


  // small helper to extract numeric percent from GST label "GST @ 5%" -> "5"
  String _extractNumberFromGst(String label) {
    final regex = RegExp(r'[-+]?\d*\.?\d+');
    final match = regex.firstMatch(label);
    return match?.group(0) ?? "0";
  }

  // ----------------------------------------------------------
// BARCODE LOGIC (BillBook Style)
// ----------------------------------------------------------

  void _generateBarcode() {
    // If already generated → just view
    if (barcodeGenerated && itemCodeCtrl.text.isNotEmpty) {
      _showBarcodeSheet(itemCodeCtrl.text.trim());
      return;
    }

    // First time generate
    final random = Random();
    final code = (random.nextInt(900000000) + 100000000).toString();

    setState(() {
      itemCodeCtrl.text = code;
      barcodeGenerated = true;
    });

    _showBarcodeSheet(code);
  }


  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );

    if (result != null && result.toString().isNotEmpty) {
      setState(() {
        itemCodeCtrl.text = result.toString();
      });
      _showBarcodeSheet(result.toString());
    }
  }

  // ----------------------------------------------------------
// CAPTURE BARCODE IMAGE (USED BY PRINT / DOWNLOAD / SHARE)
// ----------------------------------------------------------
  Future<File> _captureBarcodeImage() async {
    // 🔥 allow widget to paint fully
    await Future.delayed(const Duration(milliseconds: 300));

    final image = await _barcodeShot.capture(pixelRatio: 3.0);

    if (image == null) {
      throw Exception("Barcode image capture failed");
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(image);
    return file;
  }

  void _showBarcodeSheet(String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F5FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Row(
                    children: [
                      const Text(
                        "View Barcode",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // BARCODE
                  Screenshot(
                    controller: _barcodeShot,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nameCtrl.text.isEmpty ? "ITEM BARCODE" : nameCtrl.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),

                          bw.BarcodeWidget(
                            barcode: bw.Barcode.code128(),
                            data: code,
                            height: 80,
                            drawText: false,
                          ),

                          const SizedBox(height: 6),
                          Text(
                            code,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),


                  const SizedBox(height: 8),
                  Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),

                  const SizedBox(height: 16),

                  // INPUT
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Number of rows to print",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Printing this barcode on your items speeds up your billing process.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 18),

                  // ✅ ACTION BUTTONS (NO OVERFLOW)
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      BarcodeActionButton(
                        icon: Icons.delete_outline,
                        label: "Delete",
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            itemCodeCtrl.clear();
                            barcodeGenerated = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Barcode deleted")),
                          );
                        },
                      ),
                      BarcodeActionButton(
                        icon: Icons.print_outlined,
                        label: "Print",
                        color: Colors.deepPurple,
                        onTap: () async {
                          final imageFile = await _captureBarcodeImage();

                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async {
                              return await Printing.convertHtml(
                                format: format,
                                html: '''
          <html>
            <body style="text-align:center;">
              <img src="data:image/png;base64,${base64Encode(await imageFile.readAsBytes())}" />
            </body>
          </html>
        ''',
                              );
                            },
                          );
                        },


                      ),
                      BarcodeActionButton(
                        icon: Icons.download_outlined,
                        label: "Download",
                        color: Colors.deepPurple,
                        onTap: () async {
                          final tempFile = await _captureBarcodeImage();

                          final dir = await getExternalStorageDirectory();
                          if (dir == null) return;

                          final savedFile = File(
                            '${dir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.png',
                          );

                          await savedFile.writeAsBytes(await tempFile.readAsBytes());

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Saved to ${savedFile.path}")),
                          );
                        },


                      ),
                      BarcodeActionButton(
                        icon: Icons.share_outlined,
                        label: "Share",
                        color: Colors.deepPurple,
                        onTap: () async {
                          final file = await _captureBarcodeImage();

                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: "Item Barcode: ${itemCodeCtrl.text}",
                          );
                        },

                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // ✅ UNIT PICKER (CORRECT PLACEMENT)
  // ----------------------------------------------------------
  void _openUnitPicker() async {
    final unit = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const UnitPickerSheet(),
    );

    if (unit != null) {
      setState(() => selectedUnit = unit);
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final img =
                  await _picker.pickImage(source: ImageSource.camera);
                  if (img != null) {
                    setState(() => _itemImage = File(img.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose photo from gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final img =
                  await _picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    setState(() => _itemImage = File(img.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TITLE
                const Text(
                  "Select Item Category",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 16),

                // ➕ ADD CATEGORY (PILL STYLE)
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Category"),
                    onPressed: () {
                      Navigator.pop(context);
                      _openCreateCategorySheet();
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // CATEGORY LIST
                if (categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No Category",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  ...categories.map((c) {
                    return RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        c.name,
                        style: const TextStyle(fontSize: 15),
                      ),
                      value: c.name,
                      groupValue: selectedCategoryName,
                      onChanged: (v) {
                        setState(() => selectedCategoryName = v);
                        Navigator.pop(context);
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }


  void _openCreateCategorySheet() {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create Category",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // INPUT
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: "Category Name",
                  filled: true,
                  fillColor: const Color(0xFFF6F6F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;

                    setState(() {
                      if (!categories.any(
                            (c) => c.name.toLowerCase() == name.toLowerCase(),
                      )) {
                        categories.add(ItemCategory(id: 0, name: name));
                      }
                      selectedCategoryName = name;
                    });

                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    // ✅ TAB CONTROLLER LOGIC (MUST BE HERE)
    final bool isProduct = itemType == "product";
    final int tabCount = isProduct ? 4 : 3;

    _tabController ??= TabController(length: tabCount, vsync: this);

    if (_tabController!.length != tabCount) {
      _tabController!.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ ADD THIS
      // backgroundColor: Colors.white,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
              backgroundColor: Colors.white,
              elevation: 0.4,
              foregroundColor: Colors.black,
              // title: const Text(
              //   "Create New Item",
              //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              // ),
              title: Text(isEdit ? "Edit Item Details" : "Create New Item",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),

            ),

            // ✅ ADD THIS LINE (FIXED HEADER)
            _itemHeader(primary),

            PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController!,
                  isScrollable: true,
                  labelColor: primary,
                  indicatorColor: primary,
                  unselectedLabelColor: Colors.black54,
                  tabs: [
                    const Tab(text: "Pricing"),
                    if (itemType == "product") const Tab(text: "Stock"),
                    const Tab(text: "Other"),
                    const Tab(text: "Party Wise Prices"),
                  ],

                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController!,
                children: [
                  pricingTab(primary),
                  if (itemType == "product") stockTab(primary),
                  otherTab(primary),
                  partyWiseTab(),
                ],

              ),
            ),
          ],
        ),
      ),
    ),

      // *********************************************************************
      // UPDATED BOTTOM BUTTONS (Add More Details → Invoice Screen)
      // *********************************************************************
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16, // ✅ KEY FIX
        ),
        child: ElevatedButton(
          onPressed: saving ? null : saveItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            "Save",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),

    );
  }

  // ----------------------------------------------------------
// PRICING TAB (PERFECT BILLBOOK ALIGNMENT)
// ----------------------------------------------------------
  Widget pricingTab(Color primary) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // fieldLabel("Item Name *"),
        // textField(nameCtrl, "Ex:Kissan Fruit Jam 500 gm"),
        // const SizedBox(height: 25),
        //
        // fieldLabel("Item Type"),
        // Row(
        //   children: [
        //     typeBtn("Product"),
        //     const SizedBox(width: 12),
        //     typeBtn("Service"),
        //   ],
        // ),
        // const SizedBox(height: 25),

        // ---------------------------------------------------
        // INVENTORY TRACKING (button only first)
        // ---------------------------------------------------
        Row(
          children: [
            const Expanded(
              child: Text(
                "Inventory Tracking By",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // ---------- BUTTON (When click → show IMEI row) ----------
            InkWell(
              onTap: () {
                setState(() {
                  showImeiRow = true;
                  inventoryTracking = "IMEI"; // ✅ THIS WAS MISSING
                });
              },

              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary),
                ),
                child: Text(
                  "IMEI/Serial No",
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ---------------------------------------------------
        // SHOW THIS ONLY AFTER BUTTON CLICK
        // ---------------------------------------------------
        if (showImeiRow)
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push<List<String>>(
                context,
                MaterialPageRoute(
                  builder: (_) => ImeiListScreen(initial: imeiList),
                ),
              );
              if (updated != null) setState(() => imeiList = updated);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE7E4F8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    "IMEI/Serial No",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    "${imeiList.length} PCS",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
            ),
          ),

        if (showImeiRow) const SizedBox(height: 25),

        // ---------- UNIT ----------
        fieldLabel("Unit"),
        // safeDropdown(
        //   selectedUnit,
        //   ["PCS", "KG", "LTR", "BOX"],
        //       (v) => setState(() => selectedUnit = v!),
        // ),

        GestureDetector(
          onTap: _openUnitPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: boxBox(),
            child: Row(
              children: [
                Text(
                  selectedUnit,
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),

        const SizedBox(height: 25),

        fieldLabel("Sales Price"),
        textField(salesPriceCtrl, "₹ 130", number: true),
        const SizedBox(height: 25),

        fieldLabel("Purchase Price"),
        textField(purchasePriceCtrl, "₹ 115", number: true),
        const SizedBox(height: 25),

        fieldLabel("GST"),
        safeDropdown(
          gstPercent,
          [
            "None",
            "TAX Exempted",
            "GST @ 0%",
            "GST @ 0.1%",
            "GST @ 0.25%",
            "GST @ 1.5%",
            "GST @ 3%",
            "GST @ 5%",
            "GST @ 6%",
            "GST @ 8.9%",
            "GST @ 12% Not Applicable after 22 Sep'25",
            "GST @ 13.8%",
            "GST @ 14% + Cess @ 12%",
            "GST @ 18%",
            "GST @ 28% Not Applicable after 22 Sep'25",
            "GST @ 28% + Cess @5%",
            "GST @ 28% + Cess @ 36%",
            "GST @ 28% + Cess @ 60%",
            "GST @ 40%",
          ],
              (v) => setState(() => gstPercent = v!),
        ),
        const SizedBox(height: 25),

        fieldLabel("HSN"),
        textField(hsnCtrl, "Ex:6704"),
      ],
    );
  }


  // ----------------------------------------------------------
  // STOCK TAB
  // ----------------------------------------------------------


  Widget stockTab(Color primary) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ---------------- OPENING STOCK ----------------
        fieldLabel("Opening Stock"),
        openingStockField(),
        const SizedBox(height: 25),

        // ---------------- AS OF DATE ----------------
        fieldLabel("As of Date"),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: stockAsOfDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => stockAsOfDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: boxBox(),
            child: Row(
              children: [
                Text(DateFormat("dd MMM yyyy").format(stockAsOfDate)),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),

        // ---------------- ITEM CODE ----------------
        fieldLabel("Item Code"),
        textField(itemCodeCtrl, "Ex: 1189993849345"),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generateBarcode,
                icon: const Icon(Icons.qr_code),
                label: Text(
                  barcodeGenerated ? "View Barcode" : "Generate Barcode",
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan Barcode"),
              ),
            ),
          ],
        ),

        // ==================================================
        // 🔔 LOW STOCK ALERT
        // ==================================================
        const SizedBox(height: 22),

        Row(
          children: [
            const Icon(Icons.notifications_none, color: Colors.deepPurple),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Low stock alert",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Switch(
              value: lowStockAlert,
              activeColor: Colors.deepPurple,
              onChanged: (v) {
                setState(() => lowStockAlert = v);
              },
            ),
          ],
        ),

        if (lowStockAlert) ...[
          const SizedBox(height: 12),

          fieldLabel("Low Stock Quantity"),
          TextField(
            controller: lowStockQtyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Ex: 5",
              suffixText: "/$selectedUnit",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 🔥 LIVE UPDATING TEXT
          Text(
            lowStockQtyCtrl.text.isEmpty
                ? "You will be notified when stock goes below this value"
                : "You will be notified when stock goes below "
                "${lowStockQtyCtrl.text} $selectedUnit",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );
  }

  // ----------------------------------------------------------
// OTHER TAB (MATCHING SCREENSHOT UI)
// ----------------------------------------------------------
  Widget otherTab(Color primary) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ---------------- ADD IMAGE ----------------
        GestureDetector(
          onTap: _showImagePickerSheet,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              image: _itemImage != null
                  ? DecorationImage(
                image: FileImage(_itemImage!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _itemImage == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.camera_alt_outlined,
                    size: 28, color: Colors.black54),
                SizedBox(height: 6),
                Text("Add Image",
                    style: TextStyle(color: Colors.black54)),
              ],
            )
                : null,
          ),
        ),

        const SizedBox(height: 25),

        // ---------------- ITEM CATEGORY ----------------
        // ---------------- ITEM CATEGORY ----------------
        fieldLabel("Item Category"),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _openCategorySelector, // 👈 opens Select Category sheet
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  selectedCategoryName ?? "Select Category",
                  style: TextStyle(
                    color: selectedCategoryName == null
                        ? Colors.black54
                        : Colors.black,
                  ),
                ),

                const Spacer(),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),



        const SizedBox(height: 25),

        // ---------------- CUSTOM FIELDS ----------------
        fieldLabel("Custom Fields"),
        const SizedBox(height: 8),

        SizedBox(
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // TODO: open custom fields screen later
            },
            child: Text(
              "Add Fields to Item",
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 25),

        // ---------------- ITEM DESCRIPTION ----------------
        fieldLabel("Item Description"),
        const SizedBox(height: 8),

        TextField(
          controller: descriptionCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Ex: 100% Real Mixed Fruit Jam",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ---------------- SHOW IN ONLINE STORE ----------------
    Row(
    children: [
    Checkbox(
    value: showInOnlineStore,
    activeColor: primary,
    onChanged: (v) {
    setState(() {
    showInOnlineStore = v ?? true;
    });
    },
    ),
    const Text(
    "Show in Online Store",
    style: TextStyle(fontSize: 14),
    ),
    ],
    ),


      ],
    );
  }


  // PARTY WISE TAB
  Widget partyWiseTab() {
    return const Center(child: Text("Party wise pricing will be added later."));
  }

  // ----------------------------------------------------------
  // UI HELPERS
  // ----------------------------------------------------------

  // 🔥 Opening Stock field with dynamic unit
  Widget openingStockField() {
    return TextField(
      controller: openingStockCtrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "Ex:35",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixText: "/$selectedUnit", // ✅ PCS / KG / LTR auto
        suffixStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }



  // ----------------------------------------------------------
// FIXED ITEM HEADER (VISIBLE ON ALL TABS)
// ----------------------------------------------------------
  Widget _itemHeader(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldLabel("Item Name *"),
          const SizedBox(height: 6),
          textField(nameCtrl, "Ex: Kissan Fruit Jam 500 gm"),

          const SizedBox(height: 18),

          fieldLabel("Item Type"),
          const SizedBox(height: 8),
          Row(
            children: [
              typeBtn("Product"),
              const SizedBox(width: 12),
              // typeBtn("Service"),
            ],
          ),
        ],
      ),
    );
  }


  Widget fieldLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
  }

  Widget textField(TextEditingController c, String hint,
      {bool number = false, int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget typeBtn(String text) {
    final selected = itemType == text.toLowerCase();
    return Expanded(
      child: InkWell(
        // onTap: () => setState(() => itemType = text.toLowerCase()),
        onTap: () {
          final newType = text.toLowerCase();
          if (itemType == newType) return;

          setState(() {
            itemType = newType;
          });

          // 🔥 reset controller AFTER rebuild
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   _initTabs();
          // });
        },


        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.deepPurple.withOpacity(.1) : null,
            border: Border.all(
                color: selected ? Colors.deepPurple : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.deepPurple : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // SAFE DROPDOWN (FULLY FIXED – NEVER CRASHES)
  Widget safeDropdown(
      String? value, List<String> items, Function(String?) onChanged,
      {List<String>? labels}) {
    final String? fixedValue = value != null && items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: boxBox(),
      child: DropdownButton<String>(
        isExpanded: true,
        value: fixedValue,
        underline: const SizedBox(),
        hint: const Text("Select"),
        items: List.generate(items.length, (i) {
          return DropdownMenuItem(
            value: items[i],
            child: Text(labels != null ? labels[i] : items[i]),
          );
        }),
        onChanged: onChanged,
      ),
    );
  }

  BoxDecoration boxBox() {
    return BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(10),
    );
  }

  // ✅ ADD dispose() HERE
  @override
  void dispose() {
    _tabController?.dispose();
    lowStockQtyCtrl.dispose();
    nameCtrl.dispose();
    salesPriceCtrl.dispose();
    purchasePriceCtrl.dispose();
    hsnCtrl.dispose();
    openingStockCtrl.dispose();
    itemCodeCtrl.dispose();
    barcodeCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }
}

//Barcode
class BarcodeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const BarcodeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class BarcodeScanScreen extends StatelessWidget {
  const BarcodeScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) {
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}



// ----------------------------------------------------------
// IMEI / SERIAL NO SCREEN (NEW)
// ----------------------------------------------------------
class ImeiListScreen extends StatefulWidget {
  final List<String>? initial;
  const ImeiListScreen({super.key, this.initial});

  @override
  State<ImeiListScreen> createState() => _ImeiListScreenState();
}

class _ImeiListScreenState extends State<ImeiListScreen> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = (widget.initial ?? []).toList();
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
      body: Column(
        children: [
          const SizedBox(height: 20),
          // placeholder illustration area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Icon(Icons.qr_code, size: 70, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text("Your IMEI/Serial No will appear here", style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text("You can add IMEI/Serial No by scanning numbers or manually typing",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),

          const SizedBox(height: 18),
          // buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openAddManually,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Manually"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanToAdd,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Scan to Add"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text("No IMEI/Serial added yet"))
                : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final v = _items[i];
                return ListTile(
                  title: Text(v),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      setState(() => _items.removeAt(i));
                    },
                  ),
                );
              },
            ),
          ),
          // bottom bar with count and save
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text("${_items.length} PCS", style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _items);
                  },
                  // child: const Text("Save"),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),


                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // opens a dialog with a multi-line input - user can paste multiple IMEIs separated by newline
  void _openAddManually() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add IMEI/Serial (one per line)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.multiline,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "123456789012345\n987654321098765\n...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final text = ctrl.text.trim();
                          if (text.isEmpty) {
                            Navigator.pop(ctx);
                            return;
                          }
                          final lines = text
                              .split(RegExp(r'[\r\n]+'))
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          setState(() {
                            _items.addAll(lines);
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text("Add"),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // placeholder for scan; shows snackbar (implement scanner as needed)
  void _scanToAdd() async {
    final scannedValue = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanImeiScreen()),
    );

    if (scannedValue != null && scannedValue is String && scannedValue.trim().isNotEmpty) {
      setState(() {
        _items.add(scannedValue.trim());
      });
    }
  }

}

// ----------------------------------------------------------
// CATEGORY MODEL
// ----------------------------------------------------------
class ItemCategory {
  final int id;
  final String name;
  ItemCategory({required this.id, required this.name});

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

