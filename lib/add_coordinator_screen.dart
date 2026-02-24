import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCoordinatorScreen extends StatefulWidget {
  const AddCoordinatorScreen({super.key});

  @override
  State<AddCoordinatorScreen> createState() =>
      _AddCoordinatorScreenState();
}

class _AddCoordinatorScreenState
    extends State<AddCoordinatorScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController =
  TextEditingController();
  final TextEditingController _nameArController =
  TextEditingController();
  final TextEditingController _nameEnController =
  TextEditingController();
  final TextEditingController _phoneController =
  TextEditingController();
  final TextEditingController _emailController =
  TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool isLoading = false;
  bool isEditMode = false;

  InputDecoration customDecoration(String label) {
    return InputDecoration(
      labelText: label,
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

  Future<void> checkIfCoordinatorExists(String username) async {
    if (username.isEmpty) return;

    final doc = await _firestore
        .collection("coordinators")
        .doc(username.toUpperCase())
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      _nameArController.text = data["name_ar"] ?? "";
      _nameEnController.text = data["name_en"] ?? "";
      _phoneController.text = data["phone"] ?? "";
      _emailController.text = data["email"] ?? "";

      setState(() {
        isEditMode = true;
      });
    } else {
      _nameArController.clear();
      _nameEnController.clear();
      _phoneController.clear();
      _emailController.clear();

      setState(() {
        isEditMode = false;
      });
    }
  }

  Future<void> addOrUpdateCoordinator() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final username =
      _usernameController.text.trim().toUpperCase();

      final docRef =
      _firestore.collection("coordinators").doc(username);

      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          "name_ar": _nameArController.text.trim(),
          "name_en": _nameEnController.text.trim(),
          "phone": _phoneController.text.trim(),
          "email": _emailController.text.trim(),
          "updatedAt": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تعديل بيانات الكوردينيتور"),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        await docRef.set({
          "username": username,
          "name_ar": _nameArController.text.trim(),
          "name_en": _nameEnController.text.trim(),
          "phone": _phoneController.text.trim(),
          "email": _emailController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إضافة الكوردينيتور بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
      }

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

  @override
  void dispose() {
    _usernameController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة كوردينيتور"),
        centerTitle: true,
        backgroundColor: Colors.red.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [

                TextFormField(
                  controller: _usernameController,
                  decoration:
                  customDecoration("Username"),
                  onChanged: (value) {
                    checkIfCoordinatorExists(value.trim());
                  },
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "أدخل Username";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _nameArController,
                  decoration:
                  customDecoration("الاسم بالعربي"),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "أدخل الاسم بالعربي";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _nameEnController,
                  decoration:
                  customDecoration("الاسم بالإنجليزي"),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "أدخل الاسم بالإنجليزي";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  customDecoration("رقم الموبايل"),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "أدخل رقم الموبايل";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  decoration:
                  customDecoration("البريد الإلكتروني"),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "أدخل البريد الإلكتروني";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.red.shade400,
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 15),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                    isLoading ? null : addOrUpdateCoordinator,
                    child: isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      isEditMode
                          ? "تعديل الكوردينيتور"
                          : "إضافة الكوردينيتور",
                      style: const TextStyle(
                        color: Colors.black,
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
    );
  }
}