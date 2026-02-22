import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class CoordinatorSearchScreen extends StatefulWidget {
  const CoordinatorSearchScreen({super.key});

  @override
  State<CoordinatorSearchScreen> createState() =>
      _CoordinatorSearchScreenState();
}

class _CoordinatorSearchScreenState
    extends State<CoordinatorSearchScreen> {

  final TextEditingController searchController =
  TextEditingController();

  bool isLoading = false;
  Map<String, dynamic>? coordinatorData;

  /// 🔍 البحث عن الكوردينيتور
  Future<void> searchCoordinator() async {

    if (searchController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      coordinatorData = null;
    });

    try {

      final username =
      searchController.text.trim().toUpperCase();

      final doc = await FirebaseFirestore.instance
          .collection("coordinators")
          .doc(username)
          .get();

      if (doc.exists) {
        setState(() {
          coordinatorData = doc.data();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("لم يتم العثور على الكوردينيتور"),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  /// 📞 اتصال مباشر مع Runtime Permission
  Future<void> makePhoneCall(String phoneNumber) async {

    var status = await Permission.phone.status;

    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {

      final Uri callUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );

      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      }

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم رفض إذن الاتصال"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📧 إرسال إيميل
  Future<void> sendEmail(String email) async {

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  InputDecoration customDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔎 مربع البحث
            TextField(
              controller: searchController,
              decoration:
              customDecoration("ادخل Username الكوردينيتور"),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: searchCoordinator,
                child: const Text(
                  "بحث",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            if (!isLoading && coordinatorData != null)
              Expanded(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          "الاسم بالعربي:",
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          coordinatorData!["name_ar"] ?? "",
                          style:
                          const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "الاسم بالإنجليزي:",
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          coordinatorData!["name_en"] ?? "",
                          style:
                          const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "رقم الموبايل:",
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          coordinatorData!["phone"]
                              ?.toString() ??
                              "",
                          style:
                          const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "البريد الإلكتروني:",
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          coordinatorData!["email"] ?? "",
                          style:
                          const TextStyle(fontSize: 16),
                        ),

                        const Spacer(),

                        /// أزرار الاتصال والإيميل
                        Row(
                          children: [

                            Expanded(
                              child:
                              ElevatedButton.icon(
                                style: ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                  Colors.green,
                                ),
                                onPressed: () {
                                  final phone =
                                      coordinatorData![
                                      "phone"]
                                          ?.toString() ??
                                          "";
                                  if (phone.isNotEmpty) {
                                    makePhoneCall(
                                        phone);
                                  }
                                },
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "اتصال مباشر",
                                  style: TextStyle(
                                      color:
                                      Colors.white),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child:
                              ElevatedButton.icon(
                                style: ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                  Colors.blue,
                                ),
                                onPressed: () {
                                  final email =
                                      coordinatorData![
                                      "email"] ??
                                          "";
                                  if (email
                                      .isNotEmpty) {
                                    sendEmail(email);
                                  }
                                },
                                icon: const Icon(
                                  Icons.email,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "إرسال إيميل",
                                  style: TextStyle(
                                      color:
                                      Colors.white),
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
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}