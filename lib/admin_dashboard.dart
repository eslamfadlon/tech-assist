import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'technicians_map_screen.dart';
import 'add_technician_screen.dart';
import 'visits_reports_screen.dart';
import 'add_coordinator_screen.dart';

class AdminDashboard extends StatelessWidget {
  final String adminId;

  const AdminDashboard({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.red.shade600,
        centerTitle: true,
        title: Text(
          "لوحة تحكم الأدمن - $adminId",
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _buildButton(
              context,
              title: "عرض جميع الفنيين",
              icon: Icons.people,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TechniciansListScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _buildButton(
              context,
              title: "إضافة فني جديد",
              icon: Icons.person_add,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTechnicianScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _buildButton(
              context,
              title: "إضافة كوردينيتور",
              icon: Icons.admin_panel_settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddCoordinatorScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _buildButton(
              context,
              title: "خريطة آخر مواقع الفنيين",
              icon: Icons.map,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TechniciansMapScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _buildButton(
              context,
              title: "تقارير الزيارات",
              icon: Icons.assignment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VisitsReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, color: Colors.black),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

/// ===============================
/// شاشة عرض جميع الفنيين
/// ===============================
class TechniciansListScreen extends StatelessWidget {
  const TechniciansListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("جميع الفنيين"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("users")
            .where("role", isEqualTo: "technician")
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا يوجد فنيين"));
          }

          final technicians = snapshot.data!.docs;

          return ListView.builder(
            itemCount: technicians.length,
            itemBuilder: (context, index) {

              final techDoc = technicians[index];
              final data =
              techDoc.data() as Map<String, dynamic>;

              bool isActive = data["isActive"] ?? true;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data["name"] ?? "بدون اسم"),
                  subtitle: Text("ID: ${data["id"] ?? ""}"),

                  // 👇 ده الجزء الاحترافي الجديد
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // حالة التفعيل
                      Icon(
                        isActive
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: isActive
                            ? Colors.green
                            : Colors.red,
                      ),

                      const SizedBox(width: 8),

                      // زر التعديل ✏️
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddTechnicianScreen(
                                    existingUserId:
                                    techDoc.id,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // الضغط العادي = الخريطة
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TechniciansMapScreen(
                              focusTechnicianId:
                              techDoc.id,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}