import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'grades.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _projectLimitController = TextEditingController();

  int? _selectedGrade;
  bool _isSaving = false;

  void _onGradeChanged(int? grade) {
    setState(() {
      _selectedGrade = grade;
      if (grade != null) {
        _projectLimitController.text = gradeProjectLimits[grade].toString();
      } else {
        _projectLimitController.clear();
      }
    });
  }

  void initState() {
    super.initState();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid;

      if (teacherId == null) {
        throw Exception("No logged-in teacher found.");
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(teacherId)
          .get();

      final subAdminId = doc.data()?['subAdminId'];

      await FirebaseFirestore.instance.collection('students').add({
        'name': _nameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'schoolName': _schoolNameController.text.trim(),
        'grade': _selectedGrade,
        'projectLimit': int.parse(_projectLimitController.text),
        'teacherId': teacherId,
        'subAdminId': subAdminId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _schoolNameController.dispose();
    _projectLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student"),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                autofillHints: [AutofillHints.name],
                decoration: const InputDecoration(labelText: "Student Name"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter student name" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fatherNameController,
                autofillHints: [AutofillHints.name],
                decoration: const InputDecoration(labelText: "Father Name"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter father name" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _schoolNameController,
                autofillHints: [AutofillHints.organizationName],
                decoration: const InputDecoration(labelText: "School Name"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter school name" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Grade"),
                value: _selectedGrade,
                items: List.generate(
                  8,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text("Grade ${index + 1}"),
                  ),
                ),
                onChanged: _onGradeChanged,
                validator: (value) =>
                    value == null ? "Please select grade" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _projectLimitController,
                autofillHints: [AutofillHints.telephoneNumber],
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Number of Projects",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : _saveStudent,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Student"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
