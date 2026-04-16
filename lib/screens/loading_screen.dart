import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://192.168.1.11:8000/api';

class ScanUploadScreen extends StatefulWidget {
  const ScanUploadScreen({super.key});

  @override
  State<ScanUploadScreen> createState() => _ScanUploadScreenState();
}

class _ScanUploadScreenState extends State<ScanUploadScreen> {

  // ================= BOTTOM SHEET =================
  Widget _uploadOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Text(
            "Choose an action",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
            title: const Text("Take photo"),
            onTap: () => _pickImage(true),
          ),

          ListTile(
            leading: const Icon(Icons.image, color: Colors.deepPurple),
            title: const Text("Choose photo from gallery"),
            onTap: () => _pickImage(false),
          ),

          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
            title: const Text("Upload PDF"),
            onTap: _pickPDF,
          ),
        ],
      ),
    );
  }

  // ================= IMAGE PICK =================
  Future<void> _pickImage(bool fromCamera) async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (file != null) {
      Navigator.pop(context); // close bottom sheet

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanProcessingScreen(
            onProcess: () => _uploadToServer(file.path),
          ),
        ),
      );
    }
  }

  // ================= PDF PICK =================
  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      Navigator.pop(context); // close bottom sheet

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanProcessingScreen(
            onProcess: () => _uploadToServer(result.files.single.path!),
          ),
        ),
      );
    }
  }

  // ================= API =================
  Future<Map<String, dynamic>> _uploadToServer(String path) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/scan-bill"),
    );

    // ✅ ADD TOKEN (THIS WAS MISSING)
    request.headers.addAll({
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    });

    request.files.add(
      await http.MultipartFile.fromPath("file", path),
    );

    var response = await request.send();
    var res = await http.Response.fromStream(response);

    print("STATUS: ${response.statusCode}");
    print("BODY: ${res.body}");

    // if (response.statusCode >= 200 && response.statusCode < 300) {
    //   return jsonDecode(res.body);
    // }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(res.body);

      // ✅ ADD THIS (IMPORTANT FIX)
      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      return data;
    }
    else {
      throw Exception("Upload failed: ${res.body}");
    }
  }
  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

        body: SingleChildScrollView(
          child: Column(
            children: [

          // 🔵 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    "Scan / Upload bills to Instantly Create Purchase Bills.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.document_scanner, color: Colors.white, size: 60),
              ],
            ),
          ),

          const SizedBox(height: 40),

          const Icon(Icons.description, size: 80, color: Colors.grey),
          const SizedBox(height: 10),

          const Text(
            "No bills scanned yet",
            style: TextStyle(fontSize: 16),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => _uploadOptions(),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Bill"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 LOADING SCREEN (MATCHES YOUR SCREENSHOT)
////////////////////////////////////////////////////////////

class ScanProcessingScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() onProcess;

  const ScanProcessingScreen({super.key, required this.onProcess});

  @override
  State<ScanProcessingScreen> createState() => _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends State<ScanProcessingScreen> {

  @override
  void initState() {
    super.initState();
    _process();
  }

  void _process() async {
    try {
      final data = await widget.onProcess();

      Navigator.pop(context); // close loading
      Navigator.pop(context, data); // return data

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Icon(Icons.document_scanner, size: 80, color: Colors.grey),
          const SizedBox(height: 20),

          const Text(
            "Loading...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          const Text("Fetching Invoice Details"),
          const SizedBox(height: 8),

          const Text("Fetching Party Details"),
          const SizedBox(height: 8),

          const Text("Fetching Item Details"),
        ],
      ),
    );
  }
}