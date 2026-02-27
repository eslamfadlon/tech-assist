import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CoordinatorRatingsAdminScreen extends StatefulWidget {
  const CoordinatorRatingsAdminScreen({super.key});

  @override
  State<CoordinatorRatingsAdminScreen> createState() =>
      _CoordinatorRatingsAdminScreenState();
}

class _CoordinatorRatingsAdminScreenState
    extends State<CoordinatorRatingsAdminScreen> {

  String reportType = "all";
  String selectedCoordinator = "الكل";

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  bool isExporting = false;

  final List<String> reportTypes = [
    "all",
    "top10",
    "monthly",
    "yearly",
  ];

  Query buildQuery() {
    Query query =
    FirebaseFirestore.instance.collection('coordinator_ratings');

    if (selectedCoordinator != "الكل") {
      query = query.where(
          'coordinator_username',
          isEqualTo: selectedCoordinator);
    }

    if (reportType == "top10") {
      query = query
          .orderBy('average_rating', descending: true)
          .limit(10);
    }

    if (reportType == "monthly") {
      DateTime start =
      DateTime(selectedYear, selectedMonth, 1);
      DateTime end =
      DateTime(selectedYear, selectedMonth + 1, 1);

      query = query
          .where('created_at',
          isGreaterThanOrEqualTo:
          Timestamp.fromDate(start))
          .where('created_at',
          isLessThan: Timestamp.fromDate(end));
    }

    if (reportType == "yearly") {
      DateTime start =
      DateTime(selectedYear, 1, 1);
      DateTime end =
      DateTime(selectedYear + 1, 1, 1);

      query = query
          .where('created_at',
          isGreaterThanOrEqualTo:
          Timestamp.fromDate(start))
          .where('created_at',
          isLessThan: Timestamp.fromDate(end));
    }

    return query;
  }

  Future<List<String>> getCoordinators() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('coordinator_ratings')
        .get();

    final names = snapshot.docs
        .map((e) =>
    e['coordinator_username'] as String? ?? "")
        .toSet()
        .where((e) => e.isNotEmpty)
        .toList();

    names.insert(0, "الكل");
    return names;
  }

  /// 🔥 دالة التصدير المحسنة
  Future<void> exportCSV() async {
    if (isExporting) return;

    try {
      setState(() => isExporting = true);

      final snapshot = await buildQuery().get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لا توجد بيانات للتصدير")),
        );
        return;
      }

      List<List<dynamic>> rows = [];

      rows.add([
        "Coordinator",
        "Technician",
        "Average Rating",
        "Communication",
        "Problem Solving",
        "Response Speed",
        "Date",
        "Comment"
      ]);

      for (var doc in snapshot.docs) {
        final data =
        doc.data() as Map<String, dynamic>;

        Timestamp? ts =
        data['created_at'] as Timestamp?;
        DateTime? date = ts?.toDate();

        rows.add([
          data['coordinator_username'] ?? '',
          data['technician_name'] ?? '',
          data['average_rating'] ?? 0,
          data['communication'] ?? 0,
          data['problem_solving'] ?? 0,
          data['response_speed'] ?? 0,
          date != null
              ? "${date.day}/${date.month}/${date.year}"
              : '',
          data['comment'] ?? '',
        ]);
      }

      String csvData =
      const ListToCsvConverter().convert(rows);

      final directory =
      await getApplicationDocumentsDirectory();

      String fileName = "report";

      if (reportType == "monthly") {
        fileName =
        "monthly_${selectedMonth}_$selectedYear";
      } else if (reportType == "yearly") {
        fileName = "yearly_$selectedYear";
      } else if (reportType == "top10") {
        fileName = "top10_report";
      } else if (selectedCoordinator != "الكل") {
        fileName =
        "report_$selectedCoordinator";
      }

      final path =
          "${directory.path}/$fileName.csv";

      final file = File(path);

      // UTF8 with BOM علشان العربي يفتح صح في Excel
      await file.writeAsString(
        '\uFEFF$csvData',
        flush: true,
      );

      await Share.shareXFiles(
        [XFile(path)],
        text: "تقرير تقييمات الكوردينيتور",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("تم تصدير التقرير بنجاح ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text("حدث خطأ أثناء التصدير: $e")),
      );
    } finally {
      setState(() => isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("تقييمات الكوردينيتور"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: isExporting
                ? const CircularProgressIndicator(
                color: Colors.white)
                : const Icon(Icons.download),
            onPressed: exportCSV,
          )
        ],
      ),
      body: Column(
        children: [

          /// 🔵 الفلاتر
          Padding(
            padding:
            const EdgeInsets.all(12),
            child: Column(
              children: [

                FutureBuilder<List<String>>(
                  future: getCoordinators(),
                  builder:
                      (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    return DropdownButtonFormField(
                      value:
                      selectedCoordinator,
                      items: snapshot.data!
                          .map((e) =>
                          DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCoordinator =
                          val!;
                        });
                      },
                      decoration:
                      const InputDecoration(
                          labelText:
                          "اختر الكوردينيتور"),
                    );
                  },
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField(
                  value: reportType,
                  items: reportTypes
                      .map((e) =>
                      DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      reportType = val!;
                    });
                  },
                  decoration:
                  const InputDecoration(
                      labelText:
                      "نوع التقرير"),
                ),

                const SizedBox(height: 10),

                if (reportType == "monthly")
                  Row(
                    children: [
                      Expanded(
                        child:
                        DropdownButtonFormField<int>(
                          value:
                          selectedMonth,
                          items: List.generate(
                            12,
                                (index) =>
                                DropdownMenuItem(
                                  value:
                                  index + 1,
                                  child: Text(
                                      "شهر ${index + 1}"),
                                ),
                          ),
                          onChanged:
                              (val) {
                            setState(() {
                              selectedMonth =
                              val!;
                            });
                          },
                          decoration:
                          const InputDecoration(
                              labelText:
                              "الشهر"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                        DropdownButtonFormField<int>(
                          value:
                          selectedYear,
                          items:
                          List.generate(
                            5,
                                (index) =>
                                DropdownMenuItem(
                                  value: DateTime
                                      .now()
                                      .year -
                                      2 +
                                      index,
                                  child: Text(
                                      "${DateTime.now().year - 2 + index}"),
                                ),
                          ),
                          onChanged:
                              (val) {
                            setState(() {
                              selectedYear =
                              val!;
                            });
                          },
                          decoration:
                          const InputDecoration(
                              labelText:
                              "السنة"),
                        ),
                      ),
                    ],
                  ),

                if (reportType == "yearly")
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    items: List.generate(
                      5,
                          (index) =>
                          DropdownMenuItem(
                            value: DateTime
                                .now()
                                .year -
                                2 +
                                index,
                            child: Text(
                                "${DateTime.now().year - 2 + index}"),
                          ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        selectedYear =
                        val!;
                      });
                    },
                    decoration:
                    const InputDecoration(
                        labelText:
                        "السنة"),
                  ),
              ],
            ),
          ),

          const Divider(),

          /// 🔥 عرض البيانات (بدون تغيير في الجوهر)
          Expanded(
            child: StreamBuilder<
                QuerySnapshot>(
              stream:
              buildQuery().snapshots(),
              builder:
                  (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                      CircularProgressIndicator());
                }

                final docs =
                    snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child:
                    Text("لا توجد بيانات"),
                  );
                }

                Map<String,
                    List<Map<String,
                        dynamic>>>
                grouped = {};

                for (var doc in docs) {
                  final data = doc.data()
                  as Map<String,
                      dynamic>;

                  String name =
                      data['coordinator_username'] ??
                          "غير معروف";

                  grouped.putIfAbsent(
                      name, () => []);
                  grouped[name]!
                      .add(data);
                }

                return ListView(
                  padding:
                  const EdgeInsets.all(
                      12),
                  children:
                  grouped.entries
                      .map((entry) {
                    String coordinator =
                        entry.key;
                    List<
                        Map<String,
                            dynamic>>
                    ratings =
                        entry.value;

                    double avg = 0;
                    for (var r in ratings) {
                      avg += (r[
                      'average_rating'] ??
                          0)
                          .toDouble();
                    }
                    avg = avg /
                        ratings.length;

                    return Card(
                      elevation: 4,
                      margin:
                      const EdgeInsets.only(
                          bottom: 15),
                      child: Padding(
                        padding:
                        const EdgeInsets.all(
                            14),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [

                            Text(
                              coordinator,
                              style:
                              const TextStyle(
                                  fontSize:
                                  18,
                                  fontWeight:
                                  FontWeight
                                      .bold),
                            ),

                            const SizedBox(
                                height: 6),

                            Text(
                                "متوسط التقييم: ${avg.toStringAsFixed(1)} ⭐"),
                            Text(
                                "عدد التقييمات: ${ratings.length}"),

                            const Divider(),

                            ...ratings
                                .map((r) {
                              Timestamp? ts =
                              r['created_at'];
                              DateTime? date =
                              ts?.toDate();

                              return Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [

                                  Text(
                                      "👨‍🔧 ${r['technician_name']}"),
                                  Text(
                                      "⭐ ${r['average_rating']}"),
                                  Text(
                                      "التواصل: ${r['communication']}"),
                                  Text(
                                      "حل المشاكل: ${r['problem_solving']}"),
                                  Text(
                                      "سرعة الاستجابة: ${r['response_speed']}"),
                                  if (date !=
                                      null)
                                    Text(
                                        "التاريخ: ${date.day}/${date.month}/${date.year}"),
                                  if (r['comment'] !=
                                      null &&
                                      r['comment']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                        "ملاحظة: ${r['comment']}"),

                                  const Divider(),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}