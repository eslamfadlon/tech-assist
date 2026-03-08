import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custody_details_screen.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:excel/excel.dart';

class AdminInventoryDashboardScreen extends StatefulWidget {
  const AdminInventoryDashboardScreen({super.key});

  @override
  State<AdminInventoryDashboardScreen> createState() =>
      _AdminInventoryDashboardScreenState();
}

class _AdminInventoryDashboardScreenState
    extends State<AdminInventoryDashboardScreen> {

  String? selectedTechnician;

  int selectedYear = 2026;
  int selectedMonth = DateTime.now().month;

  List<DropdownMenuItem<String>> technicians = [];
  Map<String,String> techNames = {};

  final List<String> monthNames = const [
    "يناير","فبراير","مارس","أبريل","مايو","يونيو",
    "يوليو","أغسطس","سبتمبر","أكتوبر","نوفمبر","ديسمبر"
  ];

  @override
  void initState() {
    super.initState();
    loadTechnicians();
  }

  /// ===============================
  /// تحميل الفنيين + حفظ الاسم
  /// ===============================
  Future<void> loadTechnicians() async {

    technicians.clear();
    techNames.clear();

    technicians.add(
      const DropdownMenuItem(
        value: "ALL",
        child: Text("كل الفنيين",
            style: TextStyle(color: Colors.white)),
      ),
    );

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "technician")
        .get();

    for (var doc in snapshot.docs) {

      techNames[doc.id] = doc["name"];

      technicians.add(
        DropdownMenuItem(
          value: doc.id,
          child: Text(
            doc["name"],
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    setState(() {});
  }

  /// ===============================
  /// قراءة البيانات من فايربيز (FIX ROOT)
  /// ===============================
  Future<List<List<dynamic>>> buildRows() async {

    List<List<dynamic>> rows = [
      [
        "الفني",
        "السنة",
        "الشهر",
        "بداية الشهر",
        "المستلم",
        "Adapter",
        "Splitter",
        "Contracts",
        "Damaged",
        "المتبقي بالنظام",
        "المتبقي الفعلي",
        "الفرق"
      ]
    ];

    Query query = FirebaseFirestore.instance
        .collection("inventory_reports")
        .where("year", isEqualTo: selectedYear)
        .where("month", isEqualTo: selectedMonth);

    if (selectedTechnician != null &&
        selectedTechnician != "ALL") {

      query = query.where(
          "technicianId",
          isEqualTo: selectedTechnician);
    }

    final snapshot = await query.get();

    for (var doc in snapshot.docs) {

      final d = doc.data() as Map<String, dynamic>;

      rows.add([
        d["technicianId"],
        d["year"],
        d["month"],
        d["totalStart"],
        d["received"],
        d["adapter"],
        d["splitter"],
        d["contracts"],
        d["damaged"],
        d["systemRemaining"],
        d["actualRemaining"],
        d["difference"],
      ]);
    }

    return rows;
  }

  /// ===============================
  /// توليد CSV
  /// ===============================
  Future<String?> generateCSV() async {

    final rows = await buildRows();

    if (rows.length <= 1) return null;

    return const ListToCsvConverter().convert(rows);
  }

  /// ===============================
  /// مشاركة التقرير
  /// ===============================
  Future<void> exportCSV() async {

    final csv = await generateCSV();

    if (csv == null) {
      _msg("لا توجد بيانات للتصدير");
      return;
    }

    final dir = await getTemporaryDirectory();

    final file = File("${dir.path}/inventory.csv");

    await file.writeAsString(
      '\uFEFF$csv',
      encoding: utf8,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "تقرير الجرد",
    );
  }

  /// ===============================
  /// تحميل حقيقى Download
  /// ===============================
  Future<void> downloadCSV() async {

    var status =
    await Permission.manageExternalStorage.request();

    if (!status.isGranted) {
      _msg("يجب السماح بالوصول للتخزين");
      return;
    }

    final csv = await generateCSV();

    if (csv == null) {
      _msg("لا توجد بيانات للحفظ");
      return;
    }

    final dir =
    Directory("/storage/emulated/0/Download");

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(
        "${dir.path}/inventory_${DateTime.now().millisecondsSinceEpoch}.csv");

    await file.writeAsString(
      '\uFEFF$csv',
      encoding: utf8,
    );

    _msg("✅ تم حفظ التقرير داخل Download");
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  /// ===============================
  /// فتح الجرد
  /// ===============================
  void openInventoryScreen() {

    if (selectedTechnician == null ||
        selectedTechnician == "ALL") {

      _msg("اختر فني أولاً");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustodyDetailsScreen(
          technicianId: selectedTechnician!,
          year: selectedYear,
          month: selectedMonth,
          monthName: monthNames[selectedMonth - 1],
          isAdmin: true,
        ),
      ),
    );
  }

  InputDecoration fieldDecoration(String title) {
    return InputDecoration(
      labelText: title,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("إدارة الجرد"),
        backgroundColor: const Color(0xFFE60000),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1E1E1E),
              value: selectedTechnician,
              decoration: fieldDecoration("اختيار الفني"),
              style: const TextStyle(color: Colors.white),
              items: technicians.toList(),
              onChanged: (v) {
                selectedTechnician = v;
                setState(() {});
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<int>(
              value: selectedYear,
              dropdownColor: const Color(0xFF1E1E1E),
              decoration: fieldDecoration("السنة"),
              style: const TextStyle(color: Colors.white),
              items: List.generate(
                5,
                    (i)=>DropdownMenuItem(
                  value: 2026+i,
                  child: Text("${2026+i}"),
                ),
              ),
              onChanged:(v){
                selectedYear=v!;
                setState(() {});
              },
            ),

            const SizedBox(height:15),

            DropdownButtonFormField<int>(
              value:selectedMonth,
              dropdownColor:const Color(0xFF1E1E1E),
              decoration:fieldDecoration("الشهر"),
              style:const TextStyle(color:Colors.white),
              items:List.generate(
                12,
                    (i)=>DropdownMenuItem(
                  value:i+1,
                  child:Text(monthNames[i]),
                ),
              ),
              onChanged:(v){
                selectedMonth=v!;
                setState(() {});
              },
            ),

            const SizedBox(height:25),

            ElevatedButton.icon(
              icon:const Icon(Icons.share),
              label:const Text("تصدير ومشاركة CSV"),
              onPressed:exportCSV,
            ),

            const SizedBox(height:12),

            ElevatedButton.icon(
              icon:const Icon(Icons.download),
              label:const Text("تحميل التقرير"),
              onPressed:downloadCSV,
            ),

            const SizedBox(height:15),

            ElevatedButton.icon(
              icon:const Icon(Icons.inventory),
              label:const Text("فتح جرد الفني"),
              onPressed:openInventoryScreen,
            ),
          ],
        ),
      ),
    );
  }
}