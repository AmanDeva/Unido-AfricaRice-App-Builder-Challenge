import 'dart:io';
import 'package:flutter/material.dart';
import '../services/rice_inference.dart';
import '../utils/grading_helper.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final RiceInferenceResult inferenceResult;
  final int riceType;

  const ResultScreen({
    super.key,
    required this.image,
    required this.inferenceResult,
    required this.riceType,
  });

  @override
  Widget build(BuildContext context) {
    // Generate the user-friendly report using our Helper logic
    final report = GradingHelper.generateReport(inferenceResult, riceType);

    // Determine header color based on Grade
    Color gradeColor = Colors.green;
    if (report['grade'] == 'Grade 2') gradeColor = Colors.orange;
    if (report['grade'] == 'Grade 3' || report['grade'] == 'Below Standard')
      gradeColor = Colors.red;

    List<String> flags = List<String>.from(report['flags']);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image Summary
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(image,
                      width: 80, height: 80, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['grade'],
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: gradeColor),
                      ),
                      Text("Grain Shape: ${report['shape']}",
                          style: const TextStyle(fontSize: 16)),
                      Text("Total Grains: ${report['total_grains']}",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 2),

            // Defect Flags (If any)
            if (flags.isNotEmpty) ...[
              const Text("⚠️ Quality Alerts",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: flags
                    .map((flag) => Chip(
                          label: Text(flag,
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.redAccent,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Detailed Metrics
            const Text("Detailed Metrics",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMetricRow("Broken Grains",
                        "${report['broken_pct']}% (${report['broken_grains']} grains)"),
                    const Divider(),
                    _buildMetricRow("Average Length",
                        "${report['dimensions']['length']} mm"),
                    const Divider(),
                    _buildMetricRow(
                        "Average Width", "${report['dimensions']['width']} mm"),
                    const Divider(),
                    _buildMetricRow("Length/Width Ratio",
                        "${report['dimensions']['ratio']}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Finish Button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Scan Another Sample",
                  style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
