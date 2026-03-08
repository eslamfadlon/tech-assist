import 'package:flutter/material.dart';
import 'custody_details_screen.dart';

class CustodyMonthsScreen extends StatefulWidget {
  final String technicianId;
  final bool isAdmin;

  const CustodyMonthsScreen({
    super.key,
    required this.technicianId,
    required this.isAdmin,
  });

  @override
  State<CustodyMonthsScreen> createState() => _CustodyMonthsScreenState();
}

class _CustodyMonthsScreenState extends State<CustodyMonthsScreen> {
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    "يناير",
    "فبراير",
    "مارس",
    "أبريل",
    "مايو",
    "يونيو",
    "يوليو",
    "أغسطس",
    "سبتمبر",
    "أكتوبر",
    "نوفمبر",
    "ديسمبر",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE60000),
        title: const Text("الجرد الشهري"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<int>(
                value: selectedYear,
                isExpanded: true,
                underline: const SizedBox(),
                items: List.generate(
                  5,
                      (index) {
                    int year = DateTime.now().year - index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  },
                ),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: months.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        months[index],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustodyDetailsScreen(
                              technicianId: widget.technicianId,
                              year: selectedYear,
                              month: index + 1,
                              monthName: months[index],
                              isAdmin: widget.isAdmin,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}