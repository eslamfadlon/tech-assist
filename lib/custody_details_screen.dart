import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustodyDetailsScreen extends StatefulWidget {
  final String technicianId;
  final int year;
  final int month;
  final String monthName;
  final bool isAdmin;

  const CustodyDetailsScreen({
    super.key,
    required this.technicianId,
    required this.year,
    required this.month,
    required this.monthName,
    required this.isAdmin,
  });

  @override
  State<CustodyDetailsScreen> createState() =>
      _CustodyDetailsScreenState();
}

class _CustodyDetailsScreenState
    extends State<CustodyDetailsScreen> {

  final totalStartController = TextEditingController();
  final receivedController = TextEditingController();
  final contractsController = TextEditingController();
  final damagedController = TextEditingController();
  final splitterController = TextEditingController();
  final adapterController = TextEditingController();
  final remainingController = TextEditingController();
  final notesController = TextEditingController();

  String resultMessage = "";
  bool isLocked = false;

  /// ===============================
  /// قفل الجرد
  /// ===============================
  void checkLock() {

    if (widget.isAdmin) {
      isLocked = false;
      return;
    }

    DateTime now = DateTime.now();

    DateTime lastDay =
    DateTime(widget.year, widget.month + 1, 0);

    DateTime lockDate =
    DateTime(lastDay.year, lastDay.month + 1, 5);

    if (now.isBefore(lastDay) ||
        now.isAfter(lockDate)) {
      isLocked = true;
    }
  }

  /// ===============================
  /// ترحيل الشهر السابق
  /// ===============================
  Future<void> loadPreviousMonthBalance() async {

    int prevMonth = widget.month - 1;
    int prevYear = widget.year;

    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }

    var prevDoc = await FirebaseFirestore.instance
        .collection("monthly_inventory")
        .doc(widget.technicianId)
        .collection("months")
        .doc("${prevYear}_${prevMonth}")
        .get();

    if (prevDoc.exists) {
      int previousRemaining =
          prevDoc.data()?["actualRemaining"] ?? 0;

      totalStartController.text =
          previousRemaining.toString();
    }
  }

  /// ===============================
  /// تحميل البيانات
  /// ===============================
  Future<void> loadData() async {

    checkLock();

    var doc = await FirebaseFirestore.instance
        .collection("monthly_inventory")
        .doc(widget.technicianId)
        .collection("months")
        .doc("${widget.year}_${widget.month}")
        .get();

    if (!doc.exists) {
      await loadPreviousMonthBalance();
      setState(() {});
      return;
    }

    var d = doc.data()!;

    totalStartController.text =
        (d["totalStart"] ?? 0).toString();
    receivedController.text =
        (d["received"] ?? 0).toString();
    contractsController.text =
        (d["contracts"] ?? 0).toString();
    damagedController.text =
        (d["damaged"] ?? 0).toString();
    splitterController.text =
        (d["splitter"] ?? 0).toString();
    adapterController.text =
        (d["adapter"] ?? 0).toString();
    remainingController.text =
        (d["actualRemaining"] ?? 0).toString();
    notesController.text =
        d["notes"] ?? "";

    setState(() {});
  }

  /// ===============================
  /// الحساب
  /// ===============================
  void calculate() {

    int totalStart =
        int.tryParse(totalStartController.text) ?? 0;

    int received =
        int.tryParse(receivedController.text) ?? 0;

    int contracts =
        int.tryParse(contractsController.text) ?? 0;

    int damaged =
        int.tryParse(damagedController.text) ?? 0;

    int remaining =
        int.tryParse(remainingController.text) ?? 0;

    int systemResult =
        (totalStart + received) -
            (contracts + damaged);

    if (remaining == systemResult) {
      resultMessage = "الجرد سليم ✅";
    } else if (remaining < systemResult) {
      resultMessage =
      "⚠ يوجد عجز ${systemResult - remaining}";
    } else {
      resultMessage =
      "⚠ يوجد زيادة ${remaining - systemResult}";
    }

    setState(() {});
  }

  /// ===============================
  /// ✅ حفظ الجرد + تقرير التصدير
  /// ===============================
  Future<void> saveInventory() async {

    if (isLocked && !widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("تم غلق الجرد")),
      );
      return;
    }

    int totalStart =
        int.tryParse(totalStartController.text) ?? 0;

    int received =
        int.tryParse(receivedController.text) ?? 0;

    int contracts =
        int.tryParse(contractsController.text) ?? 0;

    int damaged =
        int.tryParse(damagedController.text) ?? 0;

    int splitter =
        int.tryParse(splitterController.text) ?? 0;

    int adapter =
        int.tryParse(adapterController.text) ?? 0;

    int remaining =
        int.tryParse(remainingController.text) ?? 0;

    int systemRemaining =
        (totalStart + received) -
            (contracts + damaged);

    int difference =
        remaining - systemRemaining;

    /// ===============================
    /// النظام الأساسي
    /// ===============================
    await FirebaseFirestore.instance
        .collection("monthly_inventory")
        .doc(widget.technicianId)
        .collection("months")
        .doc("${widget.year}_${widget.month}")
        .set({

      "year": widget.year,
      "month": widget.month,
      "totalStart": totalStart,
      "received": received,
      "contracts": contracts,
      "damaged": damaged,
      "splitter": splitter,
      "adapter": adapter,
      "actualRemaining": remaining,
      "systemRemaining": systemRemaining,
      "difference": difference,
      "notes": notesController.text,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    /// ===============================
    /// ✅ تقرير التصدير المباشر
    /// ===============================
    await FirebaseFirestore.instance
        .collection("inventory_reports")
        .doc(
        "${widget.technicianId}_${widget.year}_${widget.month}")
        .set({

      "technicianId": widget.technicianId,
      "year": widget.year,
      "month": widget.month,

      "totalStart": totalStart,
      "received": received,
      "contracts": contracts,
      "damaged": damaged,
      "splitter": splitter,
      "adapter": adapter,

      "systemRemaining": systemRemaining,
      "actualRemaining": remaining,
      "difference": difference,

      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("تم حفظ الجرد والتقرير ✅")),
    );
  }

  Widget buildField(
      String title,
      TextEditingController controller,
      {bool enabled = true}) {

    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: enabled && !isLocked,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor:
        const Color(0xFFE60000),
        title:
        Text("جرد ${widget.monthName} ${widget.year}"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [

            buildField(
              "إجمالي بداية الشهر",
              totalStartController,
              enabled: widget.isAdmin,
            ),

            buildField(
              "المستلم",
              receivedController,
              enabled: widget.isAdmin,
            ),

            buildField("العقود",
                contractsController),

            buildField("التالف",
                damagedController),

            buildField("Splitter",
                splitterController),

            buildField("Adapter",
                adapterController),

            buildField("المتبقي",
                remainingController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
              isLocked && !widget.isAdmin
                  ? null
                  : calculate,
              child:
              const Text("حساب الجرد"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed:
              isLocked && !widget.isAdmin
                  ? null
                  : saveInventory,
              child:
              const Text("حفظ الجرد"),
            ),

            if (resultMessage.isNotEmpty)
              Text(resultMessage),
          ],
        ),
      ),
    );
  }
}