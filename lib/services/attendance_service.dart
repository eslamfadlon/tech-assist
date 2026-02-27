import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ تسجيل زيارة (وأول زيارة في اليوم = تسجيل حضور تلقائي)
  Future<void> registerVisit({
    required String technicianId,
    required String landline,
    required String visitType,
    required String updateStatus,
    required String details,
    required double latitude,
    required double longitude,
  }) async {

    final now = DateTime.now();

    final todayId =
        "${technicianId}_${now.year}-${now.month}-${now.day}";

    final attendanceRef =
    _firestore.collection("attendance").doc(todayId);

    /// 🔥 هنستخدم ID ثابت للزيارة علشان نمنع التكرار
    final visitId =
        "${technicianId}_${landline}_${now.year}${now.month}${now.day}";

    final visitRef =
    _firestore.collection("visits").doc(visitId);

    /// 🔥 Transaction علشان العملية تبقى آمنة
    await _firestore.runTransaction((transaction) async {

      final attendanceSnapshot =
      await transaction.get(attendanceRef);

      final visitSnapshot =
      await transaction.get(visitRef);

      /// ✅ 🔥 نجيب اسم الفني من users
      String technicianName = "";

      final userSnapshot = await _firestore
          .collection("users")
          .where("id", isEqualTo: technicianId)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        technicianName =
            userSnapshot.docs.first.data()["name"] ?? "";
      }

      /// ✅ لو أول زيارة في اليوم → سجل حضور
      if (!attendanceSnapshot.exists) {
        transaction.set(attendanceRef, {
          "technicianId": technicianId,
          "technicianName": technicianName,
          "date": FieldValue.serverTimestamp(),
          "checkInTime": FieldValue.serverTimestamp(),
          "checkInLat": latitude,
          "checkInLng": longitude,
          "isDayClosed": false,
        });
      }

      /// ❌ لو الزيارة موجودة بالفعل
      if (visitSnapshot.exists) {
        throw Exception(
            "تم تسجيل زيارة لهذا الرقم اليوم بالفعل — استخدم زر تعديل الزيارة");
      }

      /// 🔎 نتحقق لو فني تاني سجل نفس الرقم النهارده
      final startOfDay =
      DateTime(now.year, now.month, now.day);

      final endOfDay =
      DateTime(now.year, now.month, now.day, 23, 59, 59);

      final otherTechVisit = await _firestore
          .collection("visits")
          .where("landline", isEqualTo: landline)
          .where(
        "createdAt",
        isGreaterThanOrEqualTo:
        Timestamp.fromDate(startOfDay),
      )
          .where(
        "createdAt",
        isLessThanOrEqualTo:
        Timestamp.fromDate(endOfDay),
      )
          .limit(1)
          .get();

      if (otherTechVisit.docs.isNotEmpty) {
        throw Exception(
            "هذا العميل تم تسجيل زيارة له اليوم بواسطة فني آخر");
      }

      /// ➕ إنشاء زيارة جديدة (مرة واحدة فقط مستحيل تتكرر)
      transaction.set(visitRef, {
        "technicianId": technicianId,
        "technicianName": technicianName,
        "landline": landline,
        "visitType": visitType,
        "status": updateStatus,
        "notes": details,
        "latitude": latitude,
        "longitude": longitude,
        "createdAt": FieldValue.serverTimestamp(),
      });
    });
  }

  /// 🔴 إنهاء اليوم (تسجيل انصراف)
  Future<void> endDay(String technicianId) async {

    final position = await _getLocation();
    if (position == null) {
      throw Exception("تعذر الحصول على الموقع");
    }

    final now = DateTime.now();
    final todayId =
        "${technicianId}_${now.year}-${now.month}-${now.day}";

    final attendanceRef =
    _firestore.collection("attendance").doc(todayId);

    final snapshot = await attendanceRef.get();

    if (!snapshot.exists) {
      throw Exception("لم يتم تسجيل حضور اليوم");
    }

    if (snapshot.data()?["isDayClosed"] == true) {
      throw Exception("تم إنهاء اليوم بالفعل");
    }

    await attendanceRef.update({
      "checkOutTime": FieldValue.serverTimestamp(),
      "checkOutLat": position.latitude,
      "checkOutLng": position.longitude,
      "isDayClosed": true,
    });
  }

  /// 📍 جلب الموقع (مستخدم لإنهاء اليوم فقط)
  Future<Position?> _getLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled =
    await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}