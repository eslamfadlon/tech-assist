import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'rating_screen.dart';

class CoordinatorSearchScreen extends StatefulWidget {
  final String technicianId;
  final String technicianName;

  const CoordinatorSearchScreen({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  State<CoordinatorSearchScreen> createState() =>
      _CoordinatorSearchScreenState();
}

class _CoordinatorSearchScreenState
    extends State<CoordinatorSearchScreen> {

  String? selectedCoordinator;
  bool isLoading = false;
  Map<String, dynamic>? coordinatorData;

  Future<void> searchCoordinator() async {
    if (selectedCoordinator == null) return;

    setState(() {
      isLoading = true;
      coordinatorData = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection("coordinators")
          .doc(selectedCoordinator)
          .get();

      if (doc.exists) {
        setState(() {
          coordinatorData = doc.data();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    var status = await Permission.phone.request();

    if (status.isGranted) {
      final Uri callUri = Uri.parse("tel:$phoneNumber");
      await launchUrl(callUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> sendEmail(String email) async {
    final Uri emailUri = Uri.parse("mailto:$email");
    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  }

  void copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// ⭐ هنا أهم تعديل
  void openRatingScreen() {
    if (selectedCoordinator == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          coordinatorUsername: selectedCoordinator!.trim(),
          technicianId: widget.technicianId.trim(),
          technicianName: widget.technicianName.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade400,
        title: const Text("بحث عن بيانات الكوردينيتور"),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade400,
              Colors.red.shade300,
              Colors.red.shade200,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              /// Dropdown
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("coordinators")
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var docs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedCoordinator,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: "اختر الكوردينيتور",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc.id),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCoordinator = value;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 15),

              /// زرار بحث
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: searchCoordinator,
                  child: const Text(
                    "بحث",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (isLoading)
                const CircularProgressIndicator(),

              if (!isLoading && coordinatorData != null)
                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          buildInfo("الاسم بالعربي:",
                              coordinatorData!["name_ar"] ?? ""),

                          buildInfo("الاسم بالإنجليزي:",
                              coordinatorData!["name_en"] ?? ""),

                          buildCopyRow(
                              "رقم الموبايل:",
                              coordinatorData!["phone"]
                                  ?.toString() ?? "",
                              "تم نسخ رقم الموبايل"),

                          buildCopyRow(
                              "البريد الإلكتروني:",
                              coordinatorData!["email"] ?? "",
                              "تم نسخ البريد الإلكتروني"),

                          const Spacer(),

                          /// ⭐ زرار التقييم
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: openRatingScreen,
                              child: const Text(
                                "تقييم الكوردينيتور",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    makePhoneCall(
                                      coordinatorData!["phone"].toString(),
                                    );
                                  },
                                  icon: const Icon(Icons.phone, color: Colors.white),
                                  label: const Text(
                                    "اتصال",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  onPressed: () {
                                    sendEmail(coordinatorData!["email"]);
                                  },
                                  icon: const Icon(Icons.email, color: Colors.white),
                                  label: const Text(
                                    "إيميل",
                                    style: TextStyle(color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700])),
          Text(value,
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget buildCopyRow(
      String title, String value, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700])),
          Row(
            children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (value.isNotEmpty) {
                    copyToClipboard(value, message);
                  }
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}