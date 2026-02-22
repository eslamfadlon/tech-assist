import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'technicians_map_screen.dart'; // 👈 مهم

class SearchVisitsScreen extends StatefulWidget {
  final String technicianId;

  const SearchVisitsScreen({
    super.key,
    required this.technicianId,
  });

  @override
  State<SearchVisitsScreen> createState() =>
      _SearchVisitsScreenState();
}

class _SearchVisitsScreenState
    extends State<SearchVisitsScreen> {
  final TextEditingController searchController =
  TextEditingController();

  bool isLoading = false;
  List<Map<String, dynamic>> visits = [];

  Future<void> searchVisits() async {
    if (searchController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      visits.clear();
    });

    final snapshot = await FirebaseFirestore
        .instance
        .collection("visits")
        .where("landline",
        isEqualTo: searchController.text.trim())
        .get();

    for (var doc in snapshot.docs) {
      var visitData = doc.data();

      var userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(visitData["technicianId"])
          .get();

      String technicianName =
          userDoc.data()?["name"] ?? "غير معروف";

      visits.add({
        "technicianName": technicianName,
        ...visitData
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "غير متوفر";

    DateTime date = (timestamp as Timestamp).toDate();

    return DateFormat(
        'dd/MM/yyyy - hh:mm a', 'ar')
        .format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("بحث عن زيارات"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔎 مربع البحث
            TextField(
              controller: searchController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "ادخل الرقم الأرضي",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchVisits,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            if (!isLoading)
              Expanded(
                child: visits.isEmpty
                    ? const Center(
                  child:
                  Text("لا توجد زيارات لهذا الرقم"),
                )
                    : ListView.builder(
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    var visit = visits[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TechniciansMapScreen(
                                  focusTechnicianId:
                                  visit["technicianId"],
                                ),
                          ),
                        );
                      },
                      child: Card(
                        margin:
                        const EdgeInsets.symmetric(
                            vertical: 8),
                        elevation: 4,
                        child: Padding(
                          padding:
                          const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [

                              Text(
                                "اسم الفني: ${visit["technicianName"]}",
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                  "الرقم الوظيفى: ${visit["technicianId"]}"),

                              Text(
                                  "نوع الزيارة: ${visit["visitType"]}"),

                              Text(
                                  "حالة الابديت: ${visit["status"]}"),

                              Text(
                                  "تفاصيل الابديت: ${visit["notes"]}"),

                              Text(
                                  "التاريخ: ${formatDate(visit["createdAt"])}"),

                              Text(
                                  "location: ${visit["latitude"]}, ${visit["longitude"]}"),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}