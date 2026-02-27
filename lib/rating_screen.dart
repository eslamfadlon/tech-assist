import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingScreen extends StatefulWidget {
  final String coordinatorUsername;
  final String technicianId;
  final String technicianName;

  const RatingScreen({
    super.key,
    required this.coordinatorUsername,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {

  double responseSpeed = 3;
  double communication = 3;
  double problemSolving = 3;

  final TextEditingController commentController = TextEditingController();

  bool isSaving = false;
  bool isLoading = true;

  late String ratingDocId;

  @override
  void initState() {
    super.initState();

    /// document id ثابت = فني + كوردينيتور
    ratingDocId =
    "${widget.technicianId}_${widget.coordinatorUsername}";

    loadExistingRating();
  }

  /// تحميل التقييم لو موجود
  Future<void> loadExistingRating() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("coordinator_ratings")
          .doc(ratingDocId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          responseSpeed =
              (data["response_speed"] ?? 3).toDouble();
          communication =
              (data["communication"] ?? 3).toDouble();
          problemSolving =
              (data["problem_solving"] ?? 3).toDouble();
          commentController.text =
              data["comment"] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Load error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  /// حفظ أو تعديل التقييم
  Future<void> saveRating() async {
    if (isSaving) return;

    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("من فضلك اكتب تعليقك قبل الحفظ"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final now = DateTime.now();

      final averageRating =
      ((responseSpeed + communication + problemSolving) / 3);

      await FirebaseFirestore.instance
          .collection("coordinator_ratings")
          .doc(ratingDocId) // 👈 هنا السر
          .set({
        "coordinator_username":
        widget.coordinatorUsername,
        "technician_id": widget.technicianId,
        "technician_name": widget.technicianName,
        "response_speed": responseSpeed.toInt(),
        "communication": communication.toInt(),
        "problem_solving": problemSolving.toInt(),
        "average_rating": averageRating,
        "comment": commentController.text.trim(),
        "created_at": Timestamp.now(),
        "date":
        "${now.year}-${now.month}-${now.day}",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم حفظ / تحديث التقييم بنجاح ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isSaving = false;
    });
  }

  Widget buildSlider(
      String title,
      double value,
      Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title (${value.toInt()})",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.toInt().toString(),
          activeColor: Colors.black,
          inactiveColor: Colors.grey,
          onChanged: onChanged,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade400,
        title: Text("تقييم ${widget.coordinatorUsername}"),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade400,
              Colors.red.shade300,
              Colors.red.shade200,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    buildSlider(
                      "سرعة الاستجابة",
                      responseSpeed,
                          (value) {
                        setState(() {
                          responseSpeed = value;
                        });
                      },
                    ),

                    buildSlider(
                      "طريقة التواصل",
                      communication,
                          (value) {
                        setState(() {
                          communication = value;
                        });
                      },
                    ),

                    buildSlider(
                      "حل المشاكل الفنية",
                      problemSolving,
                          (value) {
                        setState(() {
                          problemSolving = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "تعليقك:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText:
                        "اكتب رأيك في الكوردينيتور...",
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 14),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                14),
                          ),
                        ),
                        onPressed:
                        isSaving ? null : saveRating,
                        child: isSaving
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "حفظ / تحديث التقييم",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}