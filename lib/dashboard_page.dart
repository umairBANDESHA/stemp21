import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'view_users_page.dart';
import 'add_sub_admin_page.dart';
import 'add_teacher_page.dart';
import 'add_student_page.dart';
import 'view_students_page.dart';
import 'home_page.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  const DashboardPage({super.key, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int studentCount = 0;
  int teacherCount = 0;
  int subAdminCount = 0;
  late String userName = "User";

  List<IconData> icons = [
    Icons.person_add, // for "Add Teacher"
    Icons.group, // for "View All Teachers"
    Icons.school, // for "View All Students"
  ];

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _getUserName();
  }

  void _getUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    userName = doc.data()?['name'] ?? 'User';

    if (mounted) {
      setState(() {
        userName = userName;
      });
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final usersCol = FirebaseFirestore.instance.collection('users');
      final studentsCol = FirebaseFirestore.instance.collection('students');

      final userDoc = await usersCol
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      final role = userDoc.data()?['role'];

      if (role == 'Admin') {
        final results = await Future.wait([
          studentsCol.get(),
          usersCol.where('role', isEqualTo: 'Teacher').get(),
          usersCol.where('role', isEqualTo: 'Sub-admin').get(),
        ]);

        setState(() {
          studentCount = results[0].size;
          teacherCount = results[1].size;
          subAdminCount = results[2].size;
        });
      } else if (role == 'Sub-admin') {
        final studentDocs = await Future.wait([
          usersCol
              .where(
                'subAdminId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get(),
          studentsCol
              .where(
                "subAdminId",
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get(),
          // usersCol.where('role', isEqualTo: 'Sub-admin').get(),
        ]);

        setState(() {
          teacherCount = studentDocs[0].size;
          studentCount = studentDocs[1].size;
          subAdminCount = 0;
        });
      } else if (role == 'Teacher') {
        final studentDocs = await studentsCol
            .where(
              'teacherId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .get();

        setState(() {
          studentCount = studentDocs.size;
          teacherCount = 0;
          subAdminCount = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching counts: $e')));
      }
    }
  }

  List<Map<String, dynamic>> getMenu() {
    switch (widget.role) {
      case "Admin":
        return [
          {
            "title": "Add Sub-admin",
            "action": "add_sub_admin",
            "icon": Icons.add_moderator,
          },
          // {
          //   "title": "Add Teacher",
          //   "action": "add_teacher",
          //   "icon": Icons.person_add,
          // },
          {
            "title": "View All Sub-admins",
            "action": "view_admins",
            "icon": Icons.admin_panel_settings,
          },
          {
            "title": "View All Teachers",
            "action": "view_teachers",
            "icon": Icons.school,
          },
          {
            "title": "View All Students",
            "action": "view_students",
            "icon": Icons.group,
          },
        ];
      case "Sub-admin":
        return [
          {
            "title": "Add Teacher",
            "action": "add_teacher",
            "icon": Icons.person_add,
          },
          {
            "title": "View All Teachers",
            "action": "view_teachers",
            "icon": Icons.school,
          },
          {
            "title": "View All Students",
            "action": "view_students",
            "icon": Icons.group,
          },
        ];
      case "Teacher":
        return [
          {
            "title": "Add Student",
            "action": "add_student",
            "icon": Icons.person_add,
          },
          {
            "title": "View All Students",
            "action": "view_students",
            "icon": Icons.group,
          },
        ];
      default:
        return [];
    }
  }

  Future<void> _logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('role');
      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final menu = getMenu();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Welcome $userName"),
          // title: Text("${widget.role} Dashboard"),
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Column(
          children: [
            // Responsive App logo
            Image.asset(
              'assets/images/stemp.png',
              height: screenHeight * 0.15,
              width: screenHeight * 0.15,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),

            // Horizontal counts row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Only show student count for Admin and Sub-admin
                  if (widget.role == "Admin" ||
                      widget.role == "Sub-admin" ||
                      widget.role == "Teacher")
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewStudentsPage(),
                          ),
                        ).then((_) => _fetchCounts());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color with opacity
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(
                                0,
                                3,
                              ), // changes position of shadow
                            ),
                          ],
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Optional: rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ), // Optional: padding inside container
                        child: Column(
                          children: [
                            const Text(
                              "👩‍🎓 Students",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$studentCount",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.role == "Admin" || widget.role == "Sub-admin")
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ViewUsersPage(role: "Teacher"),
                          ),
                        ).then((_) => _fetchCounts());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color with opacity
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(
                                0,
                                3,
                              ), // changes position of shadow
                            ),
                          ],
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Optional: rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ), // Optional: padding inside container
                        child: Column(
                          children: [
                            const Text(
                              "👨‍🏫 Teachers",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$teacherCount",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.role == "Admin")
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ViewUsersPage(role: "Sub-admin"),
                          ),
                        ).then((_) => _fetchCounts());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color with opacity
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(
                                0,
                                3,
                              ), // changes position of shadow
                            ),
                          ],
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Optional: rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ), // Optional: padding inside container
                        child: Column(
                          children: [
                            const Text(
                              "🛡️ Sub-admins",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$subAdminCount",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Menu list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: menu.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = menu[index];
                  return Card(
                    color: AppColors.darkBlue,
                    child: ListTile(
                      leading: Icon(item['icon'], color: Colors.blue),
                      title: Text(
                        item['title']!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        final action = item['action'];
                        if (action == 'add_teacher') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddTeacherPage(),
                            ),
                          ).then((_) => _fetchCounts());
                        } else if (action == 'add_sub_admin') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddSubAdminPage(),
                            ),
                          ).then((_) => _fetchCounts());
                        } else if (action == 'view_teachers') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ViewUsersPage(role: "Teacher"),
                            ),
                          ).then((_) => _fetchCounts());
                        } else if (action == 'view_admins') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ViewUsersPage(role: "Sub-admin"),
                            ),
                          ).then((_) => _fetchCounts());
                        } else if (action == 'add_student') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddStudentPage(),
                            ),
                          ).then((_) => _fetchCounts());
                        } else if (action == 'view_students') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ViewStudentsPage(),
                            ),
                          ).then((_) => _fetchCounts());
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${item['title']} coming soon"),
                            ),
                          );
                        }
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
