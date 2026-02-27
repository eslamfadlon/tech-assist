import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'technicians_map_screen.dart';

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

  // ===============================
  // ✅ SEARCH BY DAY (NEW)
  // ===============================
  Future<void> searchByDay() async {

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    final startOfDay =
    DateTime(pickedDate.year, pickedDate.month, pickedDate.day);

    final endOfDay =
    DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);

    setState(() {
      isLoading = true;
      visits.clear();
    });

    final snapshot = await FirebaseFirestore
        .instance
        .collection("visits")
        .where("technicianId", isEqualTo: widget.technicianId)
        .where("createdAt",
        isGreaterThanOrEqualTo:
        Timestamp.fromDate(startOfDay))
        .where("createdAt",
        isLessThanOrEqualTo:
        Timestamp.fromDate(endOfDay))
        .orderBy("createdAt", descending: true)
        .get();

    for (var doc in snapshot.docs) {

      var visitData = doc.data();

      var userDoc = await FirebaseFirestore
          .instance
          .collection("users")
          .doc(widget.technicianId)
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

  String normalizeStatus(dynamic status) {
    if (status == null) return "Not Done";

    String s = status.toString().trim().toLowerCase();
    String clean =
    s.replaceAll("_", "").replaceAll(" ", "");

    if (clean == "done") return "Done";
    if (clean == "donebefore") return "Done Before";
    if (clean == "notdone") return "Not Done";

    return "Not Done";
  }

  Widget buildStatusWidget(String status, {int? count}) {
    String normalized = normalizeStatus(status);

    Color color;
    IconData icon;

    if (normalized == "Done") {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (normalized == "Done Before") {
      color = Colors.orange;
      icon = Icons.history;
    } else {
      color = Colors.red;
      icon = Icons.cancel;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          count != null
              ? "$normalized: $count"
              : normalized,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

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
        isEqualTo:
        searchController.text.trim())
        .get();

    for (var doc in snapshot.docs) {
      var visitData = doc.data();

      var userDoc = await FirebaseFirestore
          .instance
          .collection("users")
          .doc(visitData["technicianId"])
          .get();

      String technicianName =
          userDoc.data()?["name"] ??
              "غير معروف";

      visits.add({
        "technicianName": technicianName,
        ...visitData
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkTodayUpdates() async {
    final now = DateTime.now();

    final startOfDay =
    DateTime(now.year, now.month, now.day);

    final endOfDay = DateTime(
        now.year, now.month, now.day, 23, 59, 59);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator()),
    );

    final snapshot = await FirebaseFirestore
        .instance
        .collection("visits")
        .where("technicianId",
        isEqualTo: widget.technicianId)
        .where("createdAt",
        isGreaterThanOrEqualTo:
        Timestamp.fromDate(startOfDay))
        .where("createdAt",
        isLessThanOrEqualTo:
        Timestamp.fromDate(endOfDay))
        .orderBy("createdAt",
        descending: true)
        .get();

    Navigator.pop(context);

    int done = 0;
    int doneBefore = 0;
    int notDone = 0;

    Map<String, int> visitTypeCount = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      String status =
      normalizeStatus(data["status"]);

      if (status == "Done") {
        done++;
      } else if (status == "Done Before") {
        doneBefore++;
      } else {
        notDone++;
      }

      String visitType =
          data["visitType"] ?? "غير محدد";

      visitTypeCount[visitType] =
          (visitTypeCount[visitType] ?? 0) + 1;
    }

    int total = snapshot.docs.length;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
        const Text("ملخص تحديثات اليوم"),
        content: SizedBox(
          width: double.maxFinite,
          child: snapshot.docs.isEmpty
              ? const Text(
              "لا توجد زيارات اليوم")
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                buildStatusWidget("Done",
                    count: done),
                buildStatusWidget(
                    "Done Before",
                    count: doneBefore),
                buildStatusWidget(
                    "Not Done",
                    count: notDone),
                const SizedBox(height: 6),
                Text(
                  "Total: $total",
                  style: const TextStyle(
                      fontWeight:
                      FontWeight.bold),
                ),
                const Divider(height: 25),
                const Text(
                  "تفصيل أنواع الزيارات:",
                  style: TextStyle(
                      fontWeight:
                      FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...visitTypeCount.entries
                    .map(
                      (entry) => Text(
                    "${entry.key} : ${entry.value}",
                    style: const TextStyle(
                        fontWeight:
                        FontWeight.w600),
                  ),
                ),
                const Divider(height: 25),
                ...snapshot.docs.map((doc) {
                  final data =
                  doc.data();
                  return Container(
                    margin:
                    const EdgeInsets
                        .only(bottom: 12),
                    padding:
                    const EdgeInsets
                        .all(10),
                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius
                          .circular(8),
                      border: Border.all(
                          color:
                          Colors.grey
                              .shade300),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          "رقم العميل: ${data["landline"]}",
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                        Text(
                            "نوع الزيارة: ${data["visitType"] ?? "غير محدد"}"),
                        buildStatusWidget(
                            data["status"]),
                        Text(
                            "تفاصيل الابديت: ${data["notes"] ?? "-"}"),
                        Text(
                            "الوقت: ${formatDate(data["createdAt"])}"),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
            const Text("إغلاق"),
          )
        ],
      ),
    );
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null)
      return "غير متوفر";

    DateTime date =
    (timestamp as Timestamp).toDate();

    return DateFormat(
        'dd/MM/yyyy - hh:mm a', 'ar')
        .format(date);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE60000),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE60000),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "بحث عن زيارات",
          style: TextStyle(
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [

            // ===============================
            // SEARCH BY LANDLINE
            // ===============================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: TextField(
                controller:
                searchController,
                keyboardType:
                TextInputType.phone,
                decoration:
                InputDecoration(
                  labelText:
                  "ادخل الرقم الأرضي",
                  labelStyle:
                  const TextStyle(
                      color:
                      Colors.black),
                  border:
                  const OutlineInputBorder(),
                  suffixIcon:
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color:
                      Colors.black,
                    ),
                    onPressed:
                    searchVisits,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===============================
            // CHECK TODAY BUTTON
            // ===============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  Colors.black,
                ),
                onPressed:
                checkTodayUpdates,
                child:
                const Text(
                  "CHECK UPDATE TODAY",
                  style: TextStyle(
                      fontWeight:
                      FontWeight
                          .bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===============================
            // SEARCH BY DAY BUTTON (NEW)
            // ===============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  Colors.white,
                  foregroundColor:
                  Colors.black,
                ),
                onPressed:
                searchByDay,
                icon: const Icon(
                    Icons.calendar_today),
                label: const Text(
                  "SEARCH BY DAY",
                  style: TextStyle(
                      fontWeight:
                      FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(
                  color: Colors.white),

            if (!isLoading)
              Expanded(
                child: visits.isEmpty
                    ? const Center(
                    child: Text(
                      "لا توجد زيارات",
                      style: TextStyle(
                          color:
                          Colors.white),
                    ))
                    : ListView.builder(
                  itemCount:
                  visits.length,
                  itemBuilder:
                      (context,
                      index) {

                    var visit =
                    visits[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                TechniciansMapScreen(
                                  focusTechnicianId:
                                  visit[
                                  "technicianId"],
                                ),
                          ),
                        );
                      },
                      child: Card(
                        margin:
                        const EdgeInsets
                            .symmetric(
                            vertical:
                            8),
                        elevation: 4,
                        child: Padding(
                          padding:
                          const EdgeInsets
                              .all(12),
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
                                  FontWeight
                                      .bold,
                                  fontSize:
                                  16,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                  6),

                              Text(
                                  "الرقم الوظيفى: ${visit["technicianId"]}"),

                              Text(
                                  "رقم العميل: ${visit["landline"]}"),

                              Text(
                                  "نوع الزيارة: ${visit["visitType"]}"),

                              Row(
                                children: [
                                  const Text(
                                      "حالة الابديت: "),
                                  buildStatusWidget(
                                      visit[
                                      "status"]),
                                ],
                              ),

                              Text(
                                  "تفاصيل الابديت: ${visit["notes"] ?? "-"}"),

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