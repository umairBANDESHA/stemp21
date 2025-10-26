import 'package:flutter/material.dart';
import 'app_colors.dart';

class UserFormPage extends StatefulWidget {
  final String role; // "Teacher" or "Admin" or others
  const UserFormPage({super.key, required this.role});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _passwordController = TextEditingController();

  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      // For now just show a message. Later save to Firestore.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.role} saved successfully!")),
      );
      // clear if needed:
      // _nameController.clear(); ...
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add ${widget.role}"),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, "Name"),
              _buildTextField(_schoolController, "School"),
              _buildTextField(_emailController, "Email"),
              _buildTextField(_phoneController, "Phone Number"),
              _buildTextField(_areaController, "Area"),
              _buildTextField(_passwordController, "Password", isPassword: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
