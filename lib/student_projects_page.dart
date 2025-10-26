import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'app_colors.dart';
import 'project_evaluation_page.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

class StudentProjectsPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final int projectLimit;

  const StudentProjectsPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.projectLimit,
  });

  @override
  State<StudentProjectsPage> createState() => _StudentProjectsPageState();
}

class _StudentProjectsPageState extends State<StudentProjectsPage> {
  bool _initialized = false;

  CollectionReference<Map<String, dynamic>> get _projectsCol =>
      FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('projects');

  @override
  void initState() {
    super.initState();
    _ensureProjects();
  }

  Future<pw.Font> loadFont() async {
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  // creates and deletes the projects
  Future<void> _ensureProjects() async {
    if (_initialized) return;
    _initialized = true;

    final existing = await _projectsCol.get();
    final existingIds = existing.docs.map((d) => d.id).toSet();

    final batch = FirebaseFirestore.instance.batch();

    // Create missing projects up to the current limit
    for (int i = 1; i <= widget.projectLimit; i++) {
      final id = "p${i.toString().padLeft(2, '0')}";
      if (!existingIds.contains(id)) {
        final ref = _projectsCol.doc(id);
        batch.set(ref, {
          'index': i,
          'title': 'Project $i',
          'objective': false,
          'sdgs': 'none',
          'introduction': 'none',
          'stemGuided': 'none',
          'thinkingQuestion': 'none',
          'missionBrainstorming': 'none',
          'realLifeAdvantage': 'none',
          'evaluation': 'none',
          'presentation': 'none',
          'remarks': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    // Delete projects beyond the current limit
    for (final doc in existing.docs) {
      final id = doc.id;
      final index = int.tryParse(id.substring(1));
      if (index != null && index > widget.projectLimit) {
        final ref = _projectsCol.doc(id);
        batch.delete(ref);
      }
    }

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _projectsStream() {
    return _projectsCol.orderBy('index').snapshots();
  }

  Future<pw.Font> loadPdfFont() async {
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  // ---- SINGLE PROJECT PDF (you already had this; kept and hardened)
  Future<void> _downloadEvaluationReport(
    String projectId,
    String projectTitle,
  ) async {
    try {
      // Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch project data
      final snap = await _projectsCol.doc(projectId).get();
      final data = snap.data();

      if (data == null || !mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No evaluation data found")),
        );
        return;
      }

      // Create PDF
      final pdf = pw.Document();

      // Load logo
      final logoBytes = await rootBundle.load('assets/images/stemp.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // Try to load first project image from URL (Cloudinary)
      pw.MemoryImage? projectImage;
      final imageUrls = (data['images'] as List?)?.cast<dynamic>();
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final firstUrl = imageUrls.first.toString();
        final response = await http.get(Uri.parse(firstUrl));
        if (response.statusCode == 200) {
          projectImage = pw.MemoryImage(response.bodyBytes);
        }
      }

      final font = await loadFont();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 80, height: 80),
                pw.Text(
                  "STEMP21 Project Evaluation",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Student Name: ${widget.studentName}",
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              "Project Title: $projectTitle",
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["Section", "Status"],
              data: [
                ["Objective", (data['objective'] ?? false) ? "✓" : "✓✓"],
                ["SDGs", data['sdgs']?.toString() ?? ""],
                ["Introduction", data['introduction']?.toString() ?? ""],
                ["STEM Guided", data['stemGuided']?.toString() ?? ""],
                [
                  "Thinking Question",
                  data['thinkingQuestion']?.toString() ?? "",
                ],
                [
                  "Mission & Brainstorming",
                  data['missionBrainstorming']?.toString() ?? "",
                ],
                [
                  "Real-life Advantage",
                  data['realLifeAdvantage']?.toString() ?? "",
                ],
                ["Evaluation", data['evaluation']?.toString() ?? ""],
                ["Presentation", data['presentation']?.toString() ?? ""],
              ],
              border: pw.TableBorder.all(width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Teacher Remarks:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.5),
              ),
              child: pw.Text(
                data['remarks']?.toString() ?? "No remarks provided",
              ),
            ),

            if (projectImage != null) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                width: 450,
                height: 300,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue, width: 2),
                ),
                child: pw.FittedBox(
                  fit: pw.BoxFit.cover,
                  child: pw.Image(projectImage),
                ),
              ),
            ],

            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      );

      String filePath;
      if (Platform.isAndroid) {
        // Use app-specific external storage (no permissions needed!)
        final dir = await getExternalStorageDirectory();
        filePath =
            "${dir!.path}/${widget.studentName}_${projectTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath =
            "${dir.path}/${widget.studentName}_${projectTitle.replaceAll(' ', '_')}.pdf";
      }

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        Navigator.pop(context);

        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ PDF Saved'),
            content: Text('Saved to:\n$filePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await OpenFile.open(filePath);
                  if (result.type != ResultType.done) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${result.message}")),
                    );
                  }
                },
                child: const Text('OPEN PDF'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
      }
    }
  }

  // ---- ALL PROJECTS IN ONE PDF (AppBar button calls this)
  Future<void> _downloadAllProjectsReport() async {
    try {
      // Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final snapshot = await _projectsCol.orderBy('index').get();
      if (snapshot.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No projects found.")));
        return;
      }

      final pdf = pw.Document();
      final logoBytes = await rootBundle.load('assets/images/stemp.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final projectTitle = (data['title'] ?? "Untitled Project").toString();

        // load first image if exists
        pw.MemoryImage? projectImage;
        final imageUrls = (data['images'] as List?)?.cast<dynamic>();
        if (imageUrls != null && imageUrls.isNotEmpty) {
          final url = imageUrls.first.toString();
          final resp = await http.get(Uri.parse(url));
          if (resp.statusCode == 200) {
            projectImage = pw.MemoryImage(resp.bodyBytes);
          }
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 60, height: 60),
                  pw.Text(
                    "STEMP21 Project Evaluation",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                "Student: ${widget.studentName}",
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                "Project: $projectTitle",
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 15),

              pw.Table.fromTextArray(
                headers: ["Section", "Status"],
                data: [
                  ["Objective", (data['objective'] ?? false) ? "✓" : "✓✓"],
                  ["SDGs", data['sdgs']?.toString() ?? ""],
                  ["Introduction", data['introduction']?.toString() ?? ""],
                  ["STEM Guided", data['stemGuided']?.toString() ?? ""],
                  [
                    "Thinking Question",
                    data['thinkingQuestion']?.toString() ?? "",
                  ],
                  [
                    "Mission & Brainstorming",
                    data['missionBrainstorming']?.toString() ?? "",
                  ],
                  [
                    "Real-life Advantage",
                    data['realLifeAdvantage']?.toString() ?? "",
                  ],
                  ["Evaluation", data['evaluation']?.toString() ?? ""],
                  ["Presentation", data['presentation']?.toString() ?? ""],
                ],
                border: pw.TableBorder.all(width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),

              pw.SizedBox(height: 15),
              pw.Text(
                "Teacher Remarks:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Text(data['remarks']?.toString() ?? "No remarks"),
              ),

              if (projectImage != null) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 450,
                  height: 300,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue, width: 2),
                  ),
                  child: pw.FittedBox(
                    fit: pw.BoxFit.cover,
                    child: pw.Image(projectImage),
                  ),
                ),
              ],

              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
              pw.Divider(),
            ],
          ),
        );
      }

      // Save
      String filePath;
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        filePath =
            "${dir!.path}/${widget.studentName}_ALL_PROJECTS_${DateTime.now().millisecondsSinceEpoch}.pdf";
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath = "${dir.path}/${widget.studentName}_ALL_PROJECTS.pdf";
      }

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("PDF's Saved"),
            content: Text('Saved to:\n$filePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  if (Platform.isAndroid) {
                    try {
                      // Simple intent to open any file manager
                      final intent = AndroidIntent(
                        action: 'android.intent.action.VIEW',
                        type: 'resource/folder',
                      );
                      await intent.launch();

                      // Show user where to navigate
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Navigate to: Android/data/your.package.name/files',
                            ),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      // Just open the PDF as fallback
                      await OpenFile.open(filePath);
                    }
                  } else {
                    await OpenFile.open(filePath);
                  }
                },
                child: const Text("Open PDF's"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.studentName} • Projects"),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline, color: Colors.white),
            tooltip: "Download ALL Projects",
            onPressed: _downloadAllProjectsReport,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _projectsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Creating projects…"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data();
              final title = (d['title'] ?? 'Project') as String;
              final sdgs = (d['sdgs'] ?? 'not_done') as String;
              final objective = (d['objective'] ?? false) as bool;

              return Card(
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Objective: ${objective ? '✓' : '✓✓'}   SDGs: $sdgs",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkBlue,
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectEvaluationPage(
                                studentId: widget.studentId,
                                projectId: doc.id,
                                projectTitle: title,
                                studentName: widget.studentName,
                              ),
                            ),
                          );
                        },
                        child: const Text("Evaluate"),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: AppColors.darkBlue,
                        ),
                        tooltip: "Download Report",
                        onPressed: () {
                          _downloadEvaluationReport(doc.id, title);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
