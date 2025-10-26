import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'get_started_page.dart';
import 'login_page.dart';
import 'app_colors.dart';
import 'home_page.dart';
import 'dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Management',
      theme: ThemeData(
        primaryColor: AppColors.darkBlue,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkBlue,
            foregroundColor: AppColors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: AppColors.textDarkBlue,
            fontSize: 14,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textDarkBlue,
            fontSize: 16,
          ),
          titleLarge: TextStyle(
            color: AppColors.textDarkBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/get_started': (context) => const GetStartedPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => LoginPage(
              role: (ModalRoute.of(context)?.settings.arguments ?? 'student') as String,
            ),
        '/dashboard': (context) => DashboardPage(
              role: (ModalRoute.of(context)?.settings.arguments ?? 'student') as String,
            ),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _cachedRole;

  @override
  void initState() {
    super.initState();
    _loadPersistedRole();
  }

  Future<void> _loadPersistedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    if (role != null && mounted) {
      setState(() {
        _cachedRole = role;
      });
    }
  }

  Future<void> _cacheUserRole(String role) async {
    if (!mounted) return;
    
    setState(() {
      _cachedRole = role;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  Future<void> _clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = authSnapshot.data;

        if (user != null) {
          if (_cachedRole != null) {
            return DashboardPage(role: _cachedRole!);
          } else {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final role = userSnapshot.data!.get('role') as String? ?? 'student';
                  _cacheUserRole(role);
                  return DashboardPage(role: role);
                }
                return const GetStartedPage();
              },
            );
          }
        } else {
          if (mounted) {
            _cachedRole = null;
            _clearUserRole();
          }
          return const GetStartedPage();
        }
      },
    );
  }
}