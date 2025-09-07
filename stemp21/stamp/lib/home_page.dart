import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildRoleCard(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(role: title),
          ),
        );
      },
      child: Card(
        color: AppColors.darkBlue,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 30, color: AppColors.white),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: AppColors.darkBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Connect with us.",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: const [
              Icon(Icons.email, color: Colors.white),
              SizedBox(width: 8),
              Text("info@stemp21.com", style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.public, color: Colors.white),
              SizedBox(width: 8),
              Text("www.stemp21.com", style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Office# 18, Ist Floor, Khyber 3, G-15 Markaz, Islamabad",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Role"),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleCard(context, "Admin", Icons.admin_panel_settings),
                  _buildRoleCard(context, "Sub-admin", Icons.supervised_user_circle),
                  _buildRoleCard(context, "Teacher", Icons.school),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }
}
