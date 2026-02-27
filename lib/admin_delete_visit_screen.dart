import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDeleteVisitScreen extends StatefulWidget {
  const AdminDeleteVisitScreen({super.key});

  @override
  State<AdminDeleteVisitScreen> createState() =>
      _AdminDeleteVisitScreenState();
}

class _AdminDeleteVisitScreenState
    extends State<AdminDeleteVisitScreen> {

  final TextEditingController landlineController =
  TextEditingController();

  bool isLoading = false;
  List<QueryDocumentSnapshot> visits = [];

  String? selectedTechnicianId;
  String? selectedTechnicianName;

  /// ===============================
  /// 🔎 البحث بالرقم الأرضي
  /// ===============================
  Future<void> searchByLandline() async {
    if (landlineController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      visits.clear();
      selectedTechnicianId = null;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection("visits")
        .where("landline",
        isEqualTo: landlineController.text.trim())
        .orderBy("createdAt", descending: true)
        .get();

    setState(() {
      visits = snapshot.docs;
      isLoading = false;
    });
  }

  /// ===============================
  /// 🔎 البحث بكل زيارات الفني
  /// ===============================
  Future<void> searchByTechnician(
      String technicianId) async {

    setState(() {
      isLoading = true;
      visits.clear();
      landlineController.clear();
    });

    final snapshot = await FirebaseFirestore.instance
        .collection("visits")
        .where("technicianId",
        isEqualTo: technicianId)
        .orderBy("createdAt", descending: true)
        .get();

    setState(() {
      visits = snapshot.docs;
      isLoading = false;
    });
  }

  /// ===============================
  /// 🗑 حذف زيارة واحدة
  /// ===============================
  Future<void> deleteVisit(String docId) async {

    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text(
            "هل أنت متأكد من حذف هذا التحديث؟"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirm) return;

    await FirebaseFirestore.instance
        .collection("visits")
        .doc(docId)
        .delete();

    visits.removeWhere((v) => v.id == docId);
    setState(() {});
  }

  /// ===============================
  /// 🗑 حذف كل زيارات الفني
  /// ===============================
  Future<void> deleteAllTechnicianVisits() async {

    if (selectedTechnicianId == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تحذير"),
        content: Text(
            "سيتم حذف جميع زيارات $selectedTechnicianName"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text("حذف الكل"),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirm) return;

    for (var doc in visits) {
      await FirebaseFirestore.instance
          .collection("visits")
          .doc(doc.id)
          .delete();
    }

    setState(() {
      visits.clear();
    });
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "غير متوفر";

    DateTime date =
    (timestamp as Timestamp).toDate();

    return DateFormat(
        'dd/MM/yyyy - hh:mm a', 'ar')
        .format(date);
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("حذف تحديث زيارة"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔎 البحث بالرقم الأرضي
            TextField(
              controller: landlineController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "بحث بالرقم الأرضي",
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchByLandline,
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// 🔽 اختيار فني من القائمة
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
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

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText:
                    "اختيار فني لعرض زياراته",
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                          12),
                    ),
                  ),
                  value: selectedTechnicianId,
                  items: technicians.map((doc) {

                    final data =
                    doc.data() as Map<
                        String,
                        dynamic>;

                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                          data["name"] ?? ""),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final selectedDoc =
                    technicians.firstWhere(
                            (d) =>
                        d.id == value);

                    final data =
                    selectedDoc.data()
                    as Map<
                        String,
                        dynamic>;

                    selectedTechnicianId =
                        value;
                    selectedTechnicianName =
                    data["name"];

                    searchByTechnician(value);
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            if (!isLoading)
              Expanded(
                child: visits.isEmpty
                    ? const Center(
                  child: Text(
                      "لا توجد زيارات"),
                )
                    : Column(
                  children: [

                    if (selectedTechnicianId !=
                        null)
                      ElevatedButton.icon(
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          Colors.black,
                        ),
                        icon: const Icon(
                            Icons.delete_sweep),
                        label: const Text(
                            "حذف جميع زيارات الفني"),
                        onPressed:
                        deleteAllTechnicianVisits,
                      ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount:
                        visits.length,
                        itemBuilder:
                            (context, index) {

                          final doc =
                          visits[index];
                          final data =
                          doc.data()
                          as Map<
                              String,
                              dynamic>;

                          return Card(
                            margin:
                            const EdgeInsets
                                .symmetric(
                                vertical:
                                8),
                            child: ListTile(
                              title: Text(
                                  "رقم أرضي: ${data["landline"] ?? "-"}"),
                              subtitle: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                      "نوع الزيارة: ${data["visitType"] ?? "-"}"),
                                  Text(
                                      "الحالة: ${data["status"] ?? "-"}"),
                                  Text(
                                      "التاريخ: ${formatDate(data["createdAt"])}"),
                                ],
                              ),
                              trailing:
                              IconButton(
                                icon: const Icon(
                                    Icons.delete,
                                    color: Colors
                                        .red),
                                onPressed: () =>
                                    deleteVisit(
                                        doc.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}