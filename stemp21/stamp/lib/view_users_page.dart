import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';

class ViewUsersPage extends StatefulWidget {
  final String role;
  const ViewUsersPage({super.key, required this.role});

  @override
  State<ViewUsersPage> createState() => _ViewUsersPageState();
}

class _ViewUsersPageState extends State<ViewUsersPage> {
  late final String _role;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _role = widget.role;
  }

  Stream<QuerySnapshot> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: _role)
        .snapshots();
  }

  Future<void> editUser({
    required String userId,
    String? newName,
    String? newPhone,
    String? newSchool,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (newName != null && newName.isNotEmpty) {
        updates['name'] = newName;
      }
      if (newPhone != null && newPhone.isNotEmpty) {
        updates['phone'] = newPhone;
      }
      if (newSchool != null && newSchool.isNotEmpty) {
        updates['school'] = newSchool;
      }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(updates);
      }
    } catch (e) {
      throw Exception("Error updating user: $e");
    }
  }

  Future<void> _deleteEntity(String uid, String role) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirm Deletion $role',
          style: TextStyle(color: AppColors.darkBlue),
        ),
        content: Text('Are you sure you want to delete this $role?'),
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
        if (role == "Student") {
          // Delete student + subcollections
          final studentRef = FirebaseFirestore.instance
              .collection('students')
              .doc(uid);

          final projects = await studentRef.collection('projects').get();
          for (final project in projects.docs) {
            await project.reference.delete();
          }

          await studentRef.delete();

          // Also delete from users collection
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .delete();
        } else {
          // Just delete from users collection (soft delete)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Deleted $role successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting $role: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All ${widget.role}s"),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by name, email, or school...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No ${widget.role}s found"));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final school = (data['school'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      school.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text("No matching ${widget.role}s found"),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        title: Text(data['name'] ?? 'No name'),
                        subtitle: Text(
                          "${data['email'] ?? ''}\n"
                          "${data['phone'] ?? ''}\n"
                          "${data['school'] ?? ''} - ${data['area'] ?? ''}",
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✏️ Edit button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: "Edit User",
                              onPressed: () async {
                                final newNameController = TextEditingController(
                                  text: data['name'],
                                );
                                final newPhoneController =
                                    TextEditingController(text: data['phone']);
                                final newSchoolController =
                                    TextEditingController(text: data['school']);

                                await showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return AlertDialog(
                                      title: const Text("Edit User"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: newNameController,
                                            decoration: const InputDecoration(
                                              labelText: "Name",
                                            ),
                                          ),
                                          TextField(
                                            controller: newPhoneController,
                                            decoration: const InputDecoration(
                                              labelText: "Phone",
                                            ),
                                          ),
                                          TextField(
                                            controller: newSchoolController,
                                            decoration: const InputDecoration(
                                              labelText: "School",
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await editUser(
                                              userId: user.id,
                                              newName: newNameController.text
                                                  .trim(),
                                              newPhone: newPhoneController.text
                                                  .trim(),
                                              newSchool: newSchoolController
                                                  .text
                                                  .trim(),
                                            );
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            "Save",
                                            style: TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),

                            // 🗑️ Delete button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Delete User",
                              onPressed: () =>
                                  _deleteEntity(user.id, data['role']),
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
