import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  State<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState
    extends State<AttendanceReportsScreen> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<String> selectedTechnicians = [];
  DateTime? fromDate;
  DateTime? toDate;

  bool isLoading = false;

  List<Map<String, dynamic>> attendanceList = [];
  List<QueryDocumentSnapshot> technicians = [];

  @override
  void initState() {
    super.initState();
    loadTechnicians();
  }

  Future<void> loadTechnicians() async {
    final snapshot = await firestore
        .collection("users")
        .where("role", isEqualTo: "technician")
        .get();

    setState(() {
      technicians = snapshot.docs;
    });
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> loadAttendance() async {
    setState(() {
      isLoading = true;
      attendanceList.clear();
    });

    Query query = firestore.collection("visits");

    if (fromDate != null) {
      query = query.where(
        "createdAt",
        isGreaterThanOrEqualTo:
        Timestamp.fromDate(fromDate!),
      );
    }

    if (toDate != null) {
      query = query.where(
        "createdAt",
        isLessThanOrEqualTo:
        Timestamp.fromDate(
          DateTime(
            toDate!.year,
            toDate!.month,
            toDate!.day,
            23,
            59,
            59,
          ),
        ),
      );
    }

    final snapshot =
    await query.orderBy("createdAt").get();

    List<QueryDocumentSnapshot> filteredDocs =
        snapshot.docs;

    if (selectedTechnicians.isNotEmpty) {
      filteredDocs = filteredDocs.where((doc) {
        return selectedTechnicians
            .contains(doc["technicianId"]);
      }).toList();
    }

    Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (var doc in filteredDocs) {
      final data =
      doc.data() as Map<String, dynamic>;
      final date =
      (data["createdAt"] as Timestamp)
          .toDate();

      final key =
          "${data["technicianName"]}_${DateFormat("yyyy-MM-dd").format(date)}";

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(doc);
    }

    grouped.forEach((key, group) {
      group.sort((a, b) =>
          a["createdAt"]
              .compareTo(b["createdAt"]));

      final first = group.first;
      final last = group.last;

      DateTime checkInTime =
      first["createdAt"].toDate();

      DateTime commitmentLimit = DateTime(
        checkInTime.year,
        checkInTime.month,
        checkInTime.day,
        11,
        30,
      );

      bool isCommitted =
      !checkInTime.isAfter(commitmentLimit);

      attendanceList.add({
        "technician":
        first["technicianName"],
        "date": DateFormat("yyyy-MM-dd")
            .format(checkInTime),
        "checkIn": DateFormat("hh:mm a")
            .format(checkInTime),
        "checkOut": DateFormat("hh:mm a")
            .format(last["createdAt"]
            .toDate()),
        "visits": group.length,
        "committed": isCommitted,
      });
    });

    setState(() {
      isLoading = false;
    });
  }

  Future<void> exportToExcel() async {

    if (attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا يوجد بيانات للتصدير")),
      );
      return;
    }

    StringBuffer csvData = StringBuffer();

    csvData.writeln("الفني,التاريخ,الحضور,الانصراف,عدد الزيارات,الحالة");

    for (var item in attendanceList) {
      csvData.writeln(
        "${item["technician"]},"
            "${item["date"]},"
            "${item["checkIn"]},"
            "${item["checkOut"]},"
            "${item["visits"]},"
            "${item["committed"] ? "ملتزم" : "غير ملتزم"}",
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("اختيار طريقة التصدير"),
        content: const Text("هل تريد حفظ الملف أم مشاركته؟"),
        actions: [

          TextButton(
            onPressed: () async {

              Navigator.pop(context);

              Directory directory;

              if (Platform.isAndroid) {
                directory = Directory("/storage/emulated/0/Download");
              } else {
                directory = await getApplicationDocumentsDirectory();
              }

              final file = File("${directory.path}/attendance_report.csv");

              await file.writeAsString(
                csvData.toString(),
                encoding: utf8,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("تم حفظ الملف في مجلد Download")),
              );
            },
            child: const Text("📁 حفظ"),
          ),

          TextButton(
            onPressed: () async {

              Navigator.pop(context);

              final dir = await getTemporaryDirectory();
              final file = File("${dir.path}/attendance_report.csv");

              await file.writeAsString(
                csvData.toString(),
                encoding: utf8,
              );

              await Share.shareXFiles(
                [XFile(file.path)],
                text: "تقرير الحضور والانصراف",
              );
            },
            child: const Text("📤 مشاركة"),
          ),
        ],
      ),
    );
  }

  void resetFilters() {
    setState(() {
      selectedTechnicians.clear();
      fromDate = null;
      toDate = null;
      attendanceList.clear();
    });
  }

  void showTechnicianSelector() {
    List<String> tempSelected =
    List.from(selectedTechnicians);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(20)),
              title: const Text("اختيار الفنيين"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: technicians.map((tech) {
                    final data =
                    tech.data()
                    as Map<String, dynamic>;

                    return CheckboxListTile(
                      activeColor: Colors.red,
                      value: tempSelected
                          .contains(tech.id),
                      title:
                      Text(data["name"]),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (!tempSelected
                                .contains(
                                tech.id)) {
                              tempSelected
                                  .add(
                                  tech.id);
                            }
                          } else {
                            tempSelected
                                .remove(
                                tech.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedTechnicians =
                          tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("تم"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            elevation: 8,
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
        const Text("تقارير الحضور والانصراف"),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFCDD2),
              Color(0xFFEF5350),
              Color(0xFFE53935),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [

            const SizedBox(height: 20),

            buildButton(
              selectedTechnicians.isEmpty
                  ? "كل الفنيين"
                  : "تم اختيار ${selectedTechnicians.length} فني",
              showTechnicianSelector,
            ),

            Row(
              children: [
                Expanded(
                  child: buildButton(
                    fromDate == null
                        ? "من تاريخ"
                        : DateFormat("yyyy-MM-dd")
                        .format(fromDate!),
                        () => pickDate(true),
                  ),
                ),
                Expanded(
                  child: buildButton(
                    toDate == null
                        ? "إلى تاريخ"
                        : DateFormat("yyyy-MM-dd")
                        .format(toDate!),
                        () => pickDate(false),
                  ),
                ),
              ],
            ),

            buildButton("عرض التقرير", loadAttendance),
            buildButton("تصدير CSV", exportToExcel),
            buildButton("إعادة تعيين", resetFilters),

            const SizedBox(height: 10),

            Expanded(
              child: isLoading
                  ? const Center(
                  child:
                  CircularProgressIndicator(color: Colors.white))
                  : ListView.builder(
                itemCount:
                attendanceList.length,
                itemBuilder:
                    (context, index) {

                  final item =
                  attendanceList[index];

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["technician"],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          Text("📅 ${item["date"]}"),
                          Text("🟢 حضور: ${item["checkIn"]}"),
                          Text("🔴 انصراف: ${item["checkOut"]}"),
                          Text("عدد الزيارات: ${item["visits"]}"),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: item["committed"]
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              item["committed"]
                                  ? "✅ ملتزم"
                                  : "❌ غير ملتزم",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item["committed"]
                                      ? Colors.green
                                      : Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}