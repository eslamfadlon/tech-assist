import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TechniciansMapScreen extends StatefulWidget {

  final double? visitLatitude;
  final double? visitLongitude;

  const TechniciansMapScreen({
    super.key,
    this.visitLatitude,
    this.visitLongitude,
  });

  @override
  State<TechniciansMapScreen> createState() =>
      _TechniciansMapScreenState();
}

class _TechniciansMapScreenState
    extends State<TechniciansMapScreen> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadTechniciansLocations();
  }

  Future<void> _loadTechniciansLocations() async {

    try {

      final visitsSnapshot = await _firestore
          .collection("visits")
          .orderBy("createdAt", descending: true)
          .get();

      final docs = visitsSnapshot.docs;

      Map<String, QueryDocumentSnapshot> latestVisits = {};

      /// ✅ تجميع آخر زيارة لكل فني
      for (var doc in docs) {

        final data = doc.data();
        final technicianId = data["technicianId"];

        if (technicianId != null &&
            !latestVisits.containsKey(technicianId)) {

          latestVisits[technicianId] = doc;
        }
      }

      Set<Marker> markers = {};
      LatLng? focusPosition;

      /// =========================================
      /// ✅ لو جاى من زيارة → ركز على الزيارة نفسها
      /// =========================================
      if (widget.visitLatitude != null &&
          widget.visitLongitude != null) {

        focusPosition = LatLng(
          widget.visitLatitude!,
          widget.visitLongitude!,
        );

        markers.add(
          Marker(
            markerId: const MarkerId("visit_location"),
            position: focusPosition,
            infoWindow: const InfoWindow(
              title: "موقع الزيارة",
              snippet: "الموقع المسجل للعميل",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      /// =========================================
      /// ✅ عرض آخر مواقع الفنيين
      /// =========================================
      for (var entry in latestVisits.entries) {

        final data =
        entry.value.data() as Map<String, dynamic>;

        final double? lat =
        (data["latitude"] as num?)?.toDouble();

        final double? lng =
        (data["longitude"] as num?)?.toDouble();

        final technicianName =
            data["technicianName"] ?? "فني";

        if (lat != null && lng != null) {

          final position = LatLng(lat, lng);

          markers.add(
            Marker(
              markerId: MarkerId(entry.key),
              position: position,
              infoWindow: InfoWindow(
                title: technicianName,
                snippet: "آخر موقع مسجل",
              ),
            ),
          );
        }
      }

      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });

      await Future.delayed(
          const Duration(milliseconds: 300));

      /// =========================================
      /// ✅ تحريك الكاميرا
      /// =========================================
      if (_mapController != null && _markers.isNotEmpty) {

        if (focusPosition != null) {

          /// فتح موقع الزيارة مباشرة
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              focusPosition,
              17,
            ),
          );

        } else {

          final firstMarker = _markers.first;

          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: firstMarker.position,
                zoom: 14,
              ),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint("Map Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("خريطة مواقع الفنيين"),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(30.0444, 31.2357),
          zoom: 6,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}