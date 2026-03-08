import 'package:flutter/material.dart';
import 'services/attendance_service.dart';
import 'package:geolocator/geolocator.dart';
import 'search_visits_screen.dart';
import 'monthly_stats_screen.dart';
import 'coordinator_search_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'edit_visit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custody_months_screen.dart';
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('خدمة الموقع غير مفعلة');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('تم رفض إذن الموقع');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('إذن الموقع مرفوض نهائياً');
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

class TechnicianDashboard extends StatefulWidget {
  final String technicianId;
  final String technicianName;

  const TechnicianDashboard({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  State<TechnicianDashboard> createState() =>
      _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController landlineController =
  TextEditingController();

  final TextEditingController detailsController =
  TextEditingController();

  String selectedType = "Support";
  String selectedUpdate = "done";

  bool isLoading = false;

  Stream<DocumentSnapshot>? _userStream;

  bool isVisitTimeAllowed() {
    final now = DateTime.now();

    final startAllowed =
    DateTime(now.year, now.month, now.day, 8, 0);

    final endAllowed =
    DateTime(now.year, now.month, now.day, 23, 59, 59);

    return now.isAfter(startAllowed.subtract(const Duration(seconds: 1))) &&
        now.isBefore(endAllowed.add(const Duration(seconds: 1)));
  }

  @override
  void initState() {
    super.initState();

    _userStream = _firestore
        .collection("users")
        .doc(widget.technicianId)
        .snapshots();

    _userStream!.listen((doc) {
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final isActive = data["isActive"] ?? true;

      if (isActive == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم إيقاف الحساب من الإدارة"),
              backgroundColor: Colors.red,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
                (route) => false,
          );
        }
      }
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide:
        BorderSide(color: Colors.red.shade400, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle mainButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade300,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 15),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red.shade400,
        centerTitle: true,
        title: Text(
          "لوحة تحكم الفني - ${widget.technicianName}",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [



              const SizedBox(height: 20),

              TextField(
                controller: landlineController,
                keyboardType: TextInputType.phone,
                decoration:
                customInputDecoration("رقم أرضي"),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedType,
                decoration:
                customInputDecoration("نوع الزيارة"),
                items: ["Support", "Installation"]
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type,
                      style: const TextStyle(
                          color: Colors.black)),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedUpdate,
                decoration:
                customInputDecoration("حالة التحديث"),
                items: ["done", "not_done", "done_before"]
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status,
                      style: const TextStyle(
                          color: Colors.black)),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUpdate = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: detailsController,
                maxLines: 4,
                decoration:
                customInputDecoration("تفاصيل الزيارة"),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                style: mainButtonStyle(),
                onPressed: isLoading
                    ? null
                    : () async {
                  if (!isVisitTimeAllowed()) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                            "⛔ تسجيل الزيارات متاح من 8 صباحًا حتى 12 منتصف الليل فقط"),
                        backgroundColor:
                        Colors.red,
                      ),
                    );
                    return;
                  }

                  if (landlineController.text
                      .trim()
                      .isEmpty ||
                      detailsController.text
                          .trim()
                          .isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                            "من فضلك املأ كل البيانات أولاً"),
                        backgroundColor:
                        Colors.orange,
                      ),
                    );
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    Position position =
                    await _determinePosition();

                    await _attendanceService
                        .registerVisit(
                      technicianId:
                      widget.technicianId,
                      landline:
                      landlineController.text
                          .trim(),
                      visitType: selectedType,
                      updateStatus:
                      selectedUpdate,
                      details:
                      detailsController.text
                          .trim(),
                      latitude:
                      position.latitude,
                      longitude:
                      position.longitude,
                    );

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                            "تم تسجيل الزيارة بنجاح"),
                        backgroundColor:
                        Colors.green,
                      ),
                    );

                    landlineController.clear();
                    detailsController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content:
                        Text(e.toString()),
                        backgroundColor:
                        Colors.red,
                      ),
                    );
                  }

                  setState(
                          () => isLoading = false);
                },
                child: const Text("تسجيل زيارة"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                style: mainButtonStyle(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditVisitScreen(
                        technicianId:
                        widget.technicianId,
                      ),
                    ),
                  );
                },
                child:
                const Text("تعديل زيارة"),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: mainButtonStyle(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SearchVisitsScreen(
                            technicianId:
                            widget.technicianId,
                          ),
                    ),
                  );
                },
                child:
                const Text("بحث عن زيارة"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                style: mainButtonStyle(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MonthlyStatsScreen(
                            technicianId:
                            widget.technicianId,
                          ),
                    ),
                  );
                },
                child: const Text(
                    "حساب النسبة الشهرية والسنوية"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                style: mainButtonStyle(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CoordinatorSearchScreen(
                            technicianId:
                            widget.technicianId,
                            technicianName:
                            widget.technicianName,
                          ),
                    ),
                  );
                },
                child:
                const Text("بحث عن الكوردينيتور"),
              ),
              const SizedBox(height: 15), // ✅ فصل بين الزرين
              // 👇👇👇 زرار الجرد الشهري الجديد 👇👇👇
              ElevatedButton(
                style: mainButtonStyle(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustodyMonthsScreen(
                        technicianId: widget.technicianId,
                        isAdmin: false,
                      ),
                    ),
                  );
                },
                child: const Text("الجرد الشهري"),
              ),

              const SizedBox(height: 20),

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