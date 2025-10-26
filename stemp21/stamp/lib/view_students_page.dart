import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'student_projects_page.dart';
import 'grades.dart';

class ViewStudentsPage extends StatefulWidget {
  const ViewStudentsPage({super.key});

  @override
  State<ViewStudentsPage> createState() => _ViewStudentsPageState();
}

class _ViewStudentsPageState extends State<ViewStudentsPage> {
  int? _selectedGrade; // null = All
  String? _role; // teacher, admin, or sub_admin

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _role = snap.data()?['role'] ?? 'unknown';
      });
    } else {
      setState(() {
        _role = 'unknown';
      });
    }
  }

  Future<void> editStudent({
    required String studentId,
    String? newName,
    String? newFatherName,
    String? newSchool,
    dynamic newGrade,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (newName != null && newName.isNotEmpty) {
        updates['name'] = newName;
      }
      if (newFatherName != null && newFatherName.isNotEmpty) {
        updates['fatherName'] = newFatherName;
      }
      if (newSchool != null && newSchool.isNotEmpty) {
        updates['schoolName'] = newSchool;
      }
      if (newGrade != null && gradeProjectLimits.containsKey(newGrade)) {
        if (newGrade >= 1 && newGrade <= 8) {
          updates['grade'] = newGrade.toString();
          updates['projectLimit'] = gradeProjectLimits[newGrade].toString();
        }
      }

      // if (newProjectLimit != null) {
      //   updates['projectLimit'] = newProjectLimit;
      // }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .update(updates);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Student updated successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating student: $e')));
      }
    }
  }

  Future<void> _deleteOnRoleBase(
    BuildContext context,
    String studentId,
    String studentName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(color: AppColors.darkBlue),
        ),
        content: Text('Are you sure you want to delete $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Deleted student: $studentName')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting student: $e')));
        }
      }
    }
  }

  Future<void> _editStudentDialog({
    required BuildContext context,
    required String studentId,
    required String currentName,
    String? currentFatherName,
    String? currentSchool,
    dynamic currentGrade,
    int? currentProjectLimit,
  }) async {
    final nameController = TextEditingController(text: currentName);
    final fatherController = TextEditingController(text: currentFatherName);
    final schoolController = TextEditingController(text: currentSchool);
    final gradeController = TextEditingController(
      text: currentGrade?.toString(),
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable:
            true, // 👈 This makes the dialog scrollable and removes overflow
        title: const Text(
          'Edit Student',
          style: TextStyle(color: AppColors.darkBlue),
        ),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fatherController,
                decoration: const InputDecoration(labelText: 'Father Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: schoolController,
                decoration: const InputDecoration(labelText: 'School'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: 'Grade'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await editStudent(
        studentId: studentId,
        newName: nameController.text,
        newFatherName: fatherController.text,
        newSchool: schoolController.text,
        newGrade: gradeController.text.isNotEmpty
            ? int.tryParse(gradeController.text)
            : null,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    if (_role == 'Sub-admin' || _role == 'Admin') {
      return FirebaseFirestore.instance.collection('students').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('students')
          .where('teacherId', isEqualTo: user.uid)
          .snapshots();
    }
  }

  int? _toIntGrade(dynamic g) {
    if (g == null) return null;
    if (g is int) return g;
    if (g is String) {
      final m = RegExp(r'\d+').firstMatch(g);
      if (m != null) return int.tryParse(m.group(0)!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final grades = List.generate(8, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("View Students"),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
      ),
      body: _role == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text("All"),
                        selected: _selectedGrade == null,
                        onSelected: (_) =>
                            setState(() => _selectedGrade = null),
                      ),
                      for (final g in grades)
                        ChoiceChip(
                          label: Text("Grade $g"),
                          selected: _selectedGrade == g,
                          onSelected: (_) => setState(() => _selectedGrade = g),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _studentsStream(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text("Error: ${snap.error}"));
                      }

                      final allDocs = snap.data?.docs ?? [];
                      final filtered = allDocs.where((doc) {
                        if (_selectedGrade == null) return true;
                        final grade = _toIntGrade(doc.data()['grade']);
                        return grade == _selectedGrade;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            _selectedGrade == null
                                ? "No students yet."
                                : "No students in Grade $_selectedGrade.",
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final doc = filtered[i];
                          final d = doc.data();
                          final id = doc.id;

                          final name = (d['name'] ?? '') as String;
                          final fatherName = (d['fatherName'] ?? '') as String;
                          final school = (d['schoolName'] ?? '') as String;
                          final gradeInt = _toIntGrade(d['grade']);
                          final gradeLabel = gradeInt == null
                              ? ''
                              : 'Grade $gradeInt';
                          final limit = (d['projectLimit'] ?? 0) is int
                              ? d['projectLimit'] as int
                              : int.tryParse(
                                      (d['projectLimit'] ?? '0').toString(),
                                    ) ??
                                    0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Student info
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Father: $fatherName"),
                                  Text("School: $school"),
                                  Text(gradeLabel),
                                  Text("Projects: $limit"),

                                  const SizedBox(height: 10),

                                  // Actions row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.darkBlue,
                                          foregroundColor: AppColors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  StudentProjectsPage(
                                                    studentId: id,
                                                    studentName: name,
                                                    projectLimit: limit,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: const Text("View Projects"),
                                      ),

                                      // Edit + Delete icons
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: AppColors.darkBlue,
                                            ),
                                            onPressed: () {
                                              _editStudentDialog(
                                                context: context,
                                                studentId: id,
                                                currentName: name,
                                                currentSchool: school,
                                                currentGrade: d['grade'],
                                                currentProjectLimit: limit,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              _deleteOnRoleBase(
                                                context,
                                                id,
                                                name,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
