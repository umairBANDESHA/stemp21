import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProjectEvaluationPage extends StatefulWidget {
  final String studentId;
  final String projectId;
  final String projectTitle;
  final String studentName;

  const ProjectEvaluationPage({
    super.key,
    required this.studentId,
    required this.projectId,
    required this.projectTitle,
    required this.studentName,
  });

  @override
  State<ProjectEvaluationPage> createState() => _ProjectEvaluationPageState();
}

class _ProjectEvaluationPageState extends State<ProjectEvaluationPage> {
  final _formKey = GlobalKey<FormState>();

  bool _objective = false;
  String _sdgs = 'none';
  String _introduction = 'none';
  String _stemGuided = 'none';
  String _thinkingQuestion = 'none';
  String _missionBrainstorming = 'none';
  String _realLifeAdvantage = 'none';
  String _evaluation = 'none';
  String _presentation = 'none';
  final _remarksController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  final validValues = {
    'sdgs': ['done', 'not_done'],
    'introduction': ['planner', 'developer'],
    'stemGuided': ['done', 'not_done'],
    'thinkingQuestion': ['written', 'not_written'],
    'missionBrainstorming': ['written', 'not_written'],
    'realLifeAdvantage': ['written', 'not_written'],
    'evaluation': ['written', 'not_written'],
    'presentation': ['done', 'not_done'],
  };

  DocumentReference<Map<String, dynamic>> get _docRef => FirebaseFirestore
      .instance
      .collection('students')
      .doc(widget.studentId)
      .collection('projects')
      .doc(widget.projectId);

  Future<void> _load() async {
    final snap = await _docRef.get();
    final d = snap.data();
    if (d != null) {
      _objective = (d['objective'] ?? false) as bool;
      _sdgs = _ensureValid(d['sdgs'], 'sdgs');
      _introduction = _ensureValid(d['introduction'], 'introduction');
      _stemGuided = _ensureValid(d['stemGuided'], 'stemGuided');
      _thinkingQuestion = _ensureValid(
        d['thinkingQuestion'],
        'thinkingQuestion',
      );
      _missionBrainstorming = _ensureValid(
        d['missionBrainstorming'],
        'missionBrainstorming',
      );
      _realLifeAdvantage = _ensureValid(
        d['realLifeAdvantage'],
        'realLifeAdvantage',
      );
      _evaluation = _ensureValid(d['evaluation'], 'evaluation');
      _presentation = _ensureValid(d['presentation'], 'presentation');
      _remarksController.text = (d['remarks'] ?? '') as String;
    }
    setState(() => _loading = false);
  }

  String _ensureValid(dynamic value, String key) {
    final val = value?.toString();
    return validValues[key]!.contains(val) ? val! : 'none';
  }

  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  // Function to pick image from gallery or camera
  Future<void> _pickImage() async {
    // Show dialog to let user pick between gallery or camera
    final pickedOption = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pick an image"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 1), // Camera
              child: const Text("Camera"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 2), // Gallery
              child: const Text("Gallery"),
            ),
          ],
        );
      },
    );

    if (pickedOption == null) return;

    // Pick image based on selected option
    try {
      XFile? pickedFile;
      if (pickedOption == 1) {
        // Open Camera
        pickedFile = await _picker.pickImage(source: ImageSource.camera);
      } else if (pickedOption == 2) {
        // Pick from Gallery
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      }

      if (pickedFile != null) {
        setState(() {
          _selectedImages
            ..clear()
            ..add(File(pickedFile!.path));
        });
      }
    } catch (e) {
      // Handle errors (e.g., permissions)
      _showSnackBar("Failed to pick image: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<String> _uploadToCloudinary(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/dx2q08oc0/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'stemp123'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = json.decode(responseString);
      return jsonMap['secure_url'];
    } else {
      throw Exception(
        "Failed to upload image. Status code: ${response.statusCode}",
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    _uploadedImageUrls.clear();

    for (final image in _selectedImages) {
      try {
        final imageUrl = await _uploadToCloudinary(image);
        _uploadedImageUrls.add(imageUrl);
      } catch (e) {
        _showSnackBar("Image upload failed: $e");
        throw Exception("Image upload failed");
      }
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _docRef.set({
        'objective': _objective,
        'sdgs': _sdgs,
        'introduction': _introduction,
        'stemGuided': _stemGuided,
        'thinkingQuestion': _thinkingQuestion,
        'missionBrainstorming': _missionBrainstorming,
        'realLifeAdvantage': _realLifeAdvantage,
        'evaluation': _evaluation,
        'presentation': _presentation,
        'remarks': _remarksController.text.trim(),
        'images': _uploadedImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved successfully")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _saving = false);
    }
  }

  String _pretty(String key) {
    switch (key) {
      case 'done':
        return 'Done';
      case 'not_done':
        return 'Not Done';
      case 'planner':
        return 'Planner';
      case 'developer':
        return 'Developer';
      case 'written':
        return 'Written';
      case 'not_written':
        return 'Not Written';
      default:
        return 'None';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  DropdownButtonFormField<String> _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value == 'none' ? null : value,
      hint: Text('Select $label'),
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(_pretty(opt))))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _sectionTitle("Objective"),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Objective complete (✓/✓✓)"),
                      value: _objective,
                      onChanged: (v) => setState(() => _objective = v),
                    ),
                    _sectionTitle("SDGs"),
                    _buildDropdown(
                      label: "SDGs",
                      value: _sdgs,
                      options: validValues['sdgs']!,
                      onChanged: (v) => setState(() => _sdgs = v ?? 'none'),
                    ),
                    _sectionTitle("Introduction"),
                    _buildDropdown(
                      label: "Introduction",
                      value: _introduction,
                      options: validValues['introduction']!,
                      onChanged: (v) =>
                          setState(() => _introduction = v ?? 'none'),
                    ),
                    _sectionTitle("STEM Guided"),
                    _buildDropdown(
                      label: "STEM Guided",
                      value: _stemGuided,
                      options: validValues['stemGuided']!,
                      onChanged: (v) =>
                          setState(() => _stemGuided = v ?? 'none'),
                    ),
                    _sectionTitle("Thinking Question"),
                    _buildDropdown(
                      label: "Thinking Question",
                      value: _thinkingQuestion,
                      options: validValues['thinkingQuestion']!,
                      onChanged: (v) =>
                          setState(() => _thinkingQuestion = v ?? 'none'),
                    ),
                    _sectionTitle("Mission & Brainstorming"),
                    _buildDropdown(
                      label: "Mission & Brainstorming",
                      value: _missionBrainstorming,
                      options: validValues['missionBrainstorming']!,
                      onChanged: (v) =>
                          setState(() => _missionBrainstorming = v ?? 'none'),
                    ),
                    _sectionTitle("Real-life Advantage"),
                    _buildDropdown(
                      label: "Real-life Advantage",
                      value: _realLifeAdvantage,
                      options: validValues['realLifeAdvantage']!,
                      onChanged: (v) =>
                          setState(() => _realLifeAdvantage = v ?? 'none'),
                    ),
                    _sectionTitle("Evaluation"),
                    _buildDropdown(
                      label: "Evaluation",
                      value: _evaluation,
                      options: validValues['evaluation']!,
                      onChanged: (v) =>
                          setState(() => _evaluation = v ?? 'none'),
                    ),
                    _sectionTitle("Presentation"),
                    _buildDropdown(
                      label: "Presentation",
                      value: _presentation,
                      options: validValues['presentation']!,
                      onChanged: (v) =>
                          setState(() => _presentation = v ?? 'none'),
                    ),
                    _sectionTitle("Teacher Remarks"),
                    TextFormField(
                      controller: _remarksController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Write a brief report...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _selectedImages.isNotEmpty ? null : _pickImage,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text("Choose Image"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBlue,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            Colors.grey, // Optional: show disabled look
                        disabledForegroundColor: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 20),
                    if (_selectedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 5),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBlue,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
