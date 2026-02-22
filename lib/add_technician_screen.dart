import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTechnicianScreen extends StatefulWidget {
  final String? existingUserId;

  const AddTechnicianScreen({super.key, this.existingUserId});

  @override
  State<AddTechnicianScreen> createState() => _AddTechnicianScreenState();
}

class _AddTechnicianScreenState extends State<AddTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String selectedRole = "technician";
  bool isActive = true;

  bool get isEditMode => widget.existingUserId != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      loadUserData();
    }
  }

  Future<void> loadUserData() async {
    final doc =
    await _firestore.collection("users").doc(widget.existingUserId).get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data["name"] ?? "";
      _idController.text = data["id"] ?? "";
      _passwordController.text = data["password"] ?? "";
      selectedRole = data["role"] ?? "technician";
      isActive = data["isActive"] ?? true;
      setState(() {});
    }
  }

  InputDecoration customDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final id = _idController.text.trim().toUpperCase();

      if (!isEditMode) {
        final doc = await _firestore.collection("users").doc(id).get();
        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("هذا الـ ID موجود بالفعل"),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => isLoading = false);
          return;
        }
      }

      await _firestore.collection("users").doc(id).set({
        "id": id,
        "name": _nameController.text.trim(),
        "password": _passwordController.text.trim(),
        "role": selectedRole,
        "isActive": isActive,
        "lastLatitude": 0.0,
        "lastLongitude": 0.0,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode
              ? "تم تعديل المستخدم بنجاح"
              : "تم إضافة المستخدم بنجاح"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> deleteUser() async {
    await _firestore
        .collection("users")
        .doc(widget.existingUserId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم حذف المستخدم"),
        backgroundColor: Colors.red,
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "تعديل مستخدم" : "إضافة مستخدم جديد"),
        centerTitle: true,
        backgroundColor: Colors.red.shade400,
        actions: isEditMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteUser,
          )
        ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [

                TextFormField(
                  controller: _nameController,
                  decoration: customDecoration("اسم المستخدم"),
                  validator: (value) =>
                  value == null || value.isEmpty ? "أدخل الاسم" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _idController,
                  enabled: !isEditMode,
                  decoration: customDecoration("ID المستخدم"),
                  validator: (value) =>
                  value == null || value.isEmpty ? "أدخل الـ ID" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: customDecoration("كلمة المرور"),
                  validator: (value) =>
                  value == null || value.length < 4
                      ? "كلمة المرور 4 أحرف على الأقل"
                      : null,
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: customDecoration("نوع المستخدم"),
                  items: ["technician", "admin"]
                      .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),

                const SizedBox(height: 15),

                SwitchListTile(
                  title: const Text("تفعيل الحساب"),
                  value: isActive,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : saveUser,
                    child: isLoading
                        ? const CircularProgressIndicator(
                        color: Colors.black)
                        : Text(
                      isEditMode ? "حفظ التعديلات" : "إضافة المستخدم",
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}