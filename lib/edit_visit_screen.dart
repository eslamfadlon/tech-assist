import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVisitScreen extends StatefulWidget {
  final String technicianId;

  const EditVisitScreen({
    super.key,
    required this.technicianId,
  });

  @override
  State<EditVisitScreen> createState() => _EditVisitScreenState();
}

class _EditVisitScreenState extends State<EditVisitScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController landlineController =
  TextEditingController();
  final TextEditingController detailsController =
  TextEditingController();

  String selectedType = "Support";
  String selectedStatus = "done";

  bool isEditable = false;
  bool isLoading = false;

  String? currentDocId;

  final List<String> visitTypes = ["Support", "Installation"];
  final List<String> statusTypes = [
    "done",
    "not_done",
    "done_before"
  ];

  @override
  void initState() {
    super.initState();

    landlineController.addListener(() {
      final text = landlineController.text.trim();

      if (text.length >= 8) {
        _loadVisitAutomatically(text);
      } else {
        _resetForm();
      }
    });
  }

  void _resetForm() {
    setState(() {
      isEditable = false;
      currentDocId = null;
      selectedType = "Support";
      selectedStatus = "done";
      detailsController.clear();
    });
  }

  Future<void> _loadVisitAutomatically(String landline) async {
    setState(() => isLoading = true);

    try {
      final now = DateTime.now();
      final startOfDay =
      DateTime(now.year, now.month, now.day);
      final endOfDay =
      DateTime(now.year, now.month, now.day, 23, 59, 59);

      final query = await _firestore
          .collection("visits")
          .where("technicianId",
          isEqualTo: widget.technicianId)
          .where("landline", isEqualTo: landline)
          .where("createdAt",
          isGreaterThanOrEqualTo:
          Timestamp.fromDate(startOfDay))
          .where("createdAt",
          isLessThanOrEqualTo:
          Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _resetForm();
        setState(() => isLoading = false);
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();

      setState(() {
        currentDocId = doc.id;
        selectedType =
        visitTypes.contains(data["visitType"])
            ? data["visitType"]
            : "Support";

        selectedStatus =
        statusTypes.contains(data["status"])
            ? data["status"]
            : "done";

        detailsController.text = data["notes"] ?? "";
        isEditable = true;
      });
    } catch (e) {
      _resetForm();
    }

    setState(() => isLoading = false);
  }

  Future<void> _updateVisit() async {
    if (currentDocId == null) return;

    setState(() => isLoading = true);

    try {
      await _firestore
          .collection("visits")
          .doc(currentDocId)
          .update({
        "visitType": selectedType,
        "status": selectedStatus,
        "notes": detailsController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم تعديل الزيارة بنجاح"),
          backgroundColor: Colors.green,
        ),
      );

      _resetForm();
      landlineController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  InputDecoration customInput(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle mainButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade300,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل زيارة"),
        backgroundColor: Colors.red.shade400,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [

              TextField(
                controller: landlineController,
                keyboardType: TextInputType.phone,
                decoration: customInput("رقم أرضي"),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedType,
                items: visitTypes
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: isEditable
                    ? (val) {
                  setState(() {
                    selectedType = val!;
                  });
                }
                    : null,
                decoration:
                customInput("نوع الزيارة"),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: statusTypes
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: isEditable
                    ? (val) {
                  setState(() {
                    selectedStatus = val!;
                  });
                }
                    : null,
                decoration:
                customInput("حالة التحديث"),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: detailsController,
                enabled: isEditable,
                maxLines: 4,
                decoration:
                customInput("تفاصيل الزيارة"),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: mainButtonStyle(),
                onPressed:
                isEditable && !isLoading
                    ? _updateVisit
                    : null,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("تعديل"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    landlineController.dispose();
    detailsController.dispose();
    super.dispose();
  }
}