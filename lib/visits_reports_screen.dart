import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VisitsReportsScreen extends StatefulWidget {
  const VisitsReportsScreen({super.key});

  @override
  State<VisitsReportsScreen> createState() =>
      _VisitsReportsScreenState();
}

class _VisitsReportsScreenState
    extends State<VisitsReportsScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  String? selectedTechnician;
  String selectedStatus = "all";

  String searchLandline = "";
  DateTime? fromDate;
  DateTime? toDate;
  bool todayOnly = false;

  Query _buildQuery() {
    Query query = firestore.collection("visits");

    /// فلترة فني
    if (selectedTechnician != null &&
        selectedTechnician!.isNotEmpty) {
      query = query.where("technicianId",
          isEqualTo: selectedTechnician);
    }

    /// فلترة حالة
    if (selectedStatus != "all") {
      query =
          query.where("status", isEqualTo: selectedStatus);
    }

    /// بحث رقم العميل
    if (searchLandline.isNotEmpty) {
      query = query.where("landline",
          isEqualTo: searchLandline);
    }

    /// فلترة تاريخ (واحدة بس)
    if (todayOnly) {
      final now = DateTime.now();
      final start =
      DateTime(now.year, now.month, now.day);
      final end =
      DateTime(now.year, now.month, now.day, 23, 59, 59);

      query = query
          .where("createdAt",
          isGreaterThanOrEqualTo:
          Timestamp.fromDate(start))
          .where("createdAt",
          isLessThanOrEqualTo:
          Timestamp.fromDate(end));
    } else if (fromDate != null && toDate != null) {
      final start =
      DateTime(fromDate!.year, fromDate!.month,
          fromDate!.day);

      final end = DateTime(
          toDate!.year,
          toDate!.month,
          toDate!.day,
          23,
          59,
          59);

      query = query
          .where("createdAt",
          isGreaterThanOrEqualTo:
          Timestamp.fromDate(start))
          .where("createdAt",
          isLessThanOrEqualTo:
          Timestamp.fromDate(end));
    }

    /// الترتيب في الآخر دايماً
    query =
        query.orderBy("createdAt", descending: true);

    return query;
  }

  @override
  Widget build(BuildContext context) {
    final visitsQuery = _buildQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text("تقارير الزيارات"),
      ),
      body: Column(
        children: [

          /// 🔽 الفلاتر
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [

                /// اختيار الفني
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("users")
                      .where("role",
                      isEqualTo: "technician")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final technicians =
                        snapshot.data!.docs;

                    return DropdownButtonFormField<
                        String?>(
                      value: selectedTechnician,
                      hint: const Text(
                          "كل الفنيين"),
                      items: [
                        const DropdownMenuItem<
                            String?>(
                          value: null,
                          child:
                          Text("كل الفنيين"),
                        ),
                        ...technicians.map<
                            DropdownMenuItem<
                                String?>>((doc) {
                          final data = doc.data()
                          as Map<String, dynamic>;

                          return DropdownMenuItem<
                              String?>(
                            value: doc.id,
                            child: Text(
                                data["name"] ?? ""),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedTechnician =
                              value;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),

                /// الحالة
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(
                        value: "all",
                        child:
                        Text("كل الحالات")),
                    DropdownMenuItem(
                        value: "done",
                        child: Text("Done")),
                    DropdownMenuItem(
                        value: "not_done",
                        child:
                        Text("Not Done")),
                    DropdownMenuItem(
                        value: "done_before",
                        child:
                        Text("Done Before")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),

                const SizedBox(height: 10),

                /// بحث رقم العميل
                TextField(
                  decoration:
                  const InputDecoration(
                    labelText:
                    "بحث برقم العميل",
                    border:
                    OutlineInputBorder(),
                  ),
                  keyboardType:
                  TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      searchLandline =
                          value.trim();
                    });
                  },
                ),

                const SizedBox(height: 10),

                /// تقرير اليوم
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      todayOnly = true;
                      fromDate = null;
                      toDate = null;
                    });
                  },
                  child:
                  const Text("تقرير اليوم"),
                ),

                const SizedBox(height: 10),

                /// من / إلى
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final picked =
                          await showDatePicker(
                            context: context,
                            initialDate:
                            DateTime.now(),
                            firstDate:
                            DateTime(2023),
                            lastDate:
                            DateTime.now(),
                          );

                          if (picked != null) {
                            setState(() {
                              fromDate = picked;
                              todayOnly = false;
                            });
                          }
                        },
                        child: Text(
                          fromDate == null
                              ? "من تاريخ"
                              : DateFormat(
                              "yyyy-MM-dd")
                              .format(
                              fromDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final picked =
                          await showDatePicker(
                            context: context,
                            initialDate:
                            DateTime.now(),
                            firstDate:
                            DateTime(2023),
                            lastDate:
                            DateTime.now(),
                          );

                          if (picked != null) {
                            setState(() {
                              toDate = picked;
                              todayOnly = false;
                            });
                          }
                        },
                        child: Text(
                          toDate == null
                              ? "إلى تاريخ"
                              : DateFormat(
                              "yyyy-MM-dd")
                              .format(
                              toDate!),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedTechnician =
                      null;
                      selectedStatus = "all";
                      searchLandline = "";
                      fromDate = null;
                      toDate = null;
                      todayOnly = false;
                    });
                  },
                  child: const Text(
                      "إعادة تعيين الفلترة"),
                )
              ],
            ),
          ),

          /// عرض البيانات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: visitsQuery.snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          "خطأ: ${snapshot.error}"));
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child:
                      CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child:
                      Text("لا يوجد نتائج"));
                }

                final visits =
                    snapshot.data!.docs;

                int done = 0;
                int notDone = 0;
                int doneBefore = 0;

                for (var doc in visits) {
                  final data = doc.data()
                  as Map<String, dynamic>;

                  if (data["status"] == "done")
                    done++;
                  if (data["status"] ==
                      "not_done") notDone++;
                  if (data["status"] ==
                      "done_before")
                    doneBefore++;
                }

                return Column(
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceAround,
                        children: [
                          _statBox("Done",
                              done, Colors.green),
                          _statBox(
                              "Not Done",
                              notDone,
                              Colors.orange),
                          _statBox(
                              "Done Before",
                              doneBefore,
                              Colors.blue),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child:
                      ListView.builder(
                        itemCount:
                        visits.length,
                        itemBuilder:
                            (context, index) {
                          final data =
                          visits[index]
                              .data()
                          as Map<String,
                              dynamic>;

                          final ts =
                          data["createdAt"]
                          as Timestamp?;

                          String date = "";
                          if (ts != null) {
                            date = DateFormat(
                                "yyyy-MM-dd HH:mm")
                                .format(
                                ts.toDate());
                          }

                          return Card(
                            margin:
                            const EdgeInsets
                                .all(8),
                            child: ListTile(
                              title: Text(
                                  "عميل: ${data["landline"] ?? ""}"),
                              subtitle:
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                      "الفني: ${data["technicianName"] ?? "غير معروف"}"),
                                  Text(
                                      "نوع: ${data["visitType"] ?? ""}"),
                                  Text(
                                      "الحالة: ${_translateStatus(data["status"])}"),
                                  Text(
                                      "ملاحظات: ${data["notes"] ?? ""}"),
                                  Text(
                                      "التاريخ: $date"),
                                ],
                              ),
                              trailing: Icon(
                                _getStatusIcon(
                                    data["status"]),
                                color:
                                _getStatusColor(
                                    data[
                                    "status"]),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  String _translateStatus(String? status) {
    switch (status) {
      case "done":
        return "تم التنفيذ";
      case "not_done":
        return "لم يتم";
      case "done_before":
        return "منفذ مسبقاً";
      default:
        return status ?? "";
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == "done") {
      return Icons.check_circle;
    } else if (status == "done_before") {
      return Icons.verified;
    } else {
      return Icons.cancel;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == "done") {
      return Colors.green;
    } else if (status == "done_before") {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  Widget _statBox(
      String title,
      int count,
      Color color) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight:
                FontWeight.bold)),
        const SizedBox(height: 5),
        CircleAvatar(
          radius: 22,
          backgroundColor: color,
          child: Text(
            count.toString(),
            style: const TextStyle(
                color: Colors.white),
          ),
        )
      ],
    );
  }
}