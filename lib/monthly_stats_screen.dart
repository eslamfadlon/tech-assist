import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyStatsScreen extends StatefulWidget {
  final String technicianId;

  const MonthlyStatsScreen({
    super.key,
    required this.technicianId,
  });

  @override
  State<MonthlyStatsScreen> createState() =>
      _MonthlyStatsScreenState();
}

class _MonthlyStatsScreenState
    extends State<MonthlyStatsScreen> {

  int selectedYear = DateTime.now().year;

  final List<String> monthNames = const [
    "يناير",
    "فبراير",
    "مارس",
    "أبريل",
    "مايو",
    "يونيو",
    "يوليو",
    "أغسطس",
    "سبتمبر",
    "أكتوبر",
    "نوفمبر",
    "ديسمبر",
  ];

  /// 🔥 توحيد شكل الحالة
  String normalizeStatus(String? status) {
    return (status ?? "").toString().trim().toLowerCase();
  }

  Map<String, dynamic> calculateStats(
      QuerySnapshot snapshot) {

    Map<int, int> donePerMonth = {};
    Map<int, int> notDonePerMonth = {};
    Map<int, int> doneBeforePerMonth = {};

    for (var doc in snapshot.docs) {

      final data = doc.data() as Map<String, dynamic>;

      if (!data.containsKey("createdAt") ||
          data["createdAt"] == null) continue;

      DateTime date =
      (data["createdAt"] as Timestamp).toDate();

      if (date.year != selectedYear) continue;

      int month = date.month;

      String status =
      normalizeStatus(data["status"]);

      /// ✅ DONE
      if (status == "done") {
        donePerMonth[month] =
            (donePerMonth[month] ?? 0) + 1;
      }

      /// ✅ NOT DONE (بكل أشكاله)
      if (status == "not_done" ||
          status == "not done") {
        notDonePerMonth[month] =
            (notDonePerMonth[month] ?? 0) + 1;
      }

      /// ✅ DONE BEFORE
      if (status == "done_before" ||
          status == "done before") {
        doneBeforePerMonth[month] =
            (doneBeforePerMonth[month] ?? 0) + 1;
      }
    }

    Map<int, double> percentagePerMonth = {};

    for (int i = 1; i <= 12; i++) {

      int done = donePerMonth[i] ?? 0;
      int notDone = notDonePerMonth[i] ?? 0;

      int evaluated = done + notDone;

      percentagePerMonth[i] =
      evaluated == 0
          ? 0
          : (done / evaluated) * 100;
    }

    int totalDone =
    donePerMonth.values.fold(0, (a, b) => a + b);

    int totalNotDone =
    notDonePerMonth.values.fold(0, (a, b) => a + b);

    int totalEvaluated =
        totalDone + totalNotDone;

    double yearlyPercent =
    totalEvaluated == 0
        ? 0
        : (totalDone / totalEvaluated) * 100;

    return {
      "monthly": percentagePerMonth,
      "yearly": yearlyPercent,
      "done": totalDone,
      "notDone": totalNotDone,
      "donePerMonth": donePerMonth,
      "notDonePerMonth": notDonePerMonth,
      "doneBeforePerMonth": doneBeforePerMonth,
    };
  }

  Color getColor(double percent) {
    if (percent < 50) {
      return Colors.red;
    } else if (percent < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إحصائيات الفني"),
        backgroundColor: Colors.red.shade400,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("visits")
            .where("technicianId",
            isEqualTo: widget.technicianId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final stats =
          calculateStats(snapshot.data!);

          final monthly =
          stats["monthly"] as Map<int, double>;

          final yearly =
          stats["yearly"] as double;

          final done =
          stats["done"] as int;

          final notDone =
          stats["notDone"] as int;

          final donePerMonth =
          stats["donePerMonth"] as Map<int, int>;

          final notDonePerMonth =
          stats["notDonePerMonth"] as Map<int, int>;

          final doneBeforePerMonth =
          stats["doneBeforePerMonth"] as Map<int, int>;

          Color yearlyColor = getColor(yearly);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: "اختر السنة",
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) {
                  int year =
                      DateTime.now().year - index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      const Text(
                        "النسبة السنوية",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Stack(
                        alignment: Alignment.center,
                        children: [

                          SizedBox(
                            width: 120,
                            height: 120,
                            child:
                            CircularProgressIndicator(
                              value: yearly / 100,
                              strokeWidth: 10,
                              backgroundColor:
                              Colors.grey[300],
                              valueColor:
                              AlwaysStoppedAnimation(
                                  yearlyColor),
                            ),
                          ),

                          Text(
                            "${yearly.toStringAsFixed(1)} %",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                              color: yearlyColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Text("done: $done"),
                      Text("not done: $notDone"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "النسبة الشهرية",
                style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 16),
              ),

              const SizedBox(height: 10),

              ...List.generate(12, (index) {
                int month = index + 1;
                double percent =
                    monthly[month] ?? 0;

                int doneCount =
                    donePerMonth[month] ?? 0;

                int notDoneCount =
                    notDonePerMonth[month] ?? 0;

                int doneBeforeCount =
                    doneBeforePerMonth[month] ?? 0;

                Color progressColor =
                getColor(percent);

                return Card(
                  margin:
                  const EdgeInsets.symmetric(
                      vertical: 6),
                  child: Padding(
                    padding:
                    const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text(
                              monthNames[index],
                              style: const TextStyle(
                                  fontWeight:
                                  FontWeight.bold),
                            ),
                            Text(
                              "${percent.toStringAsFixed(1)} %",
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                color:
                                progressColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        ClipRRect(
                          borderRadius:
                          BorderRadius
                              .circular(8),
                          child:
                          LinearProgressIndicator(
                            value:
                            percent / 100,
                            minHeight: 10,
                            backgroundColor:
                            Colors.grey[300],
                            valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                                progressColor),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text(
                              "done: $doneCount",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 12),
                            ),
                            Text(
                              "done_before: $doneBeforeCount",
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 12),
                            ),
                            Text(
                              "not done: $notDoneCount",
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}