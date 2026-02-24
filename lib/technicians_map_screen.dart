import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TechniciansMapScreen extends StatefulWidget {
  final String? focusTechnicianId;

  const TechniciansMapScreen({
    super.key,
    this.focusTechnicianId,
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

      for (var entry in latestVisits.entries) {
        final data =
        entry.value.data() as Map<String, dynamic>;

        final lat = data["latitude"];
        final lng = data["longitude"];
        final technicianName =
            data["technicianName"] ?? "فني";

        if (lat != null && lng != null) {

          final position = LatLng(lat, lng);

          markers.add(
            Marker(
              markerId: MarkerId(entry.key),
              position: position,
              infoWindow: InfoWindow(
                title: technicianName, // ✅ الاسم بدل الـ ID
                snippet: "آخر موقع مسجل",
              ),
            ),
          );

          if (widget.focusTechnicianId != null &&
              widget.focusTechnicianId == entry.key) {
            focusPosition = position;
          }
        }
      }

      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });

      await Future.delayed(
          const Duration(milliseconds: 300));

      if (_mapController != null && _markers.isNotEmpty) {

        if (focusPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              focusPosition,
              16,
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