import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  GoogleMapController? mapController;

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _loadTechniciansLocations();
  }

  Future<void> _loadTechniciansLocations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('visits')
        .orderBy('createdAt', descending: true)
        .get();

    Map<String, bool> addedTechnicians = {};
    Set<Marker> loadedMarkers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final technicianId = data['technicianId'];
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (lat == null || lng == null) continue;

      // لو الفني ده اتحط قبل كده منضيفهوش تاني
      if (addedTechnicians.containsKey(technicianId)) continue;

      addedTechnicians[technicianId] = true;

      loadedMarkers.add(
        Marker(
          markerId: MarkerId(technicianId),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: "فني: $technicianId",
            snippet: "آخر ظهور",
          ),
        ),
      );
    }

    setState(() {
      markers = loadedMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("خريطة الفنيين"),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(30.0444, 31.2357), // القاهرة كبداية
          zoom: 10,
        ),
        markers: markers,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}
