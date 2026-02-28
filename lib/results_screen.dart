import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/rice_inference.dart';
import 'package:geolocator/geolocator.dart';

class ResultsScreen extends StatefulWidget {
  final File image;
  final RiceInferenceResult results;
  final bool saveGps; // 📍 DEFINED HERE

  const ResultsScreen(
      {super.key,
      required this.image,
      required this.results,
      required this.saveGps // 📍 ADDED TO CONSTRUCTOR HERE
      });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // Base Metrics
  late double totalGrains;
  late double brokenGrains, brokenPercentage;
  late double avgLength, avgWidth, lwRatio;

  // Color Defect Percentages
  late double chalkyPct, redPct, yellowPct, greenPct, blackPct;

  // CIELAB Color Values
  late double cielabL, cielabA, cielabB;

  // UI Strings
  late String gradeTitle, grainShape, chalkyStatus;
  late Color gradeColor;

  // Dynamic Alerts List
  List<String> qualityAlerts = [];

  @override
  void initState() {
    super.initState();
    _calculateMetrics();
    _saveToHistory();
  }

  void _calculateMetrics() {
    // 1. Total & Broken
    totalGrains = widget.results.counts.reduce((a, b) => a + b);

    // ⚠️ ALIGN THESE INDICES WITH YOUR MODEL'S EXACT TRAINING CLASSES ⚠️
    brokenGrains = widget.results.counts[1];
    double chalkyGrains = widget.results.counts[2];
    double redGrains = widget.results.counts[3];
    double yellowGrains = widget.results.counts[4];
    double greenGrains = widget.results.counts[5];
    double blackGrains = widget.results.counts[6];

    // Calculate Percentages
    brokenPercentage =
        totalGrains > 0 ? (brokenGrains / totalGrains) * 100 : 0.0;
    chalkyPct = totalGrains > 0 ? (chalkyGrains / totalGrains) * 100 : 0.0;
    redPct = totalGrains > 0 ? (redGrains / totalGrains) * 100 : 0.0;
    yellowPct = totalGrains > 0 ? (yellowGrains / totalGrains) * 100 : 0.0;
    greenPct = totalGrains > 0 ? (greenGrains / totalGrains) * 100 : 0.0;
    blackPct = totalGrains > 0 ? (blackGrains / totalGrains) * 100 : 0.0;

    // 2. Physical Measurements (Indices 0, 1, 2)
    avgLength = widget.results.measures[0];
    avgWidth = widget.results.measures[1];
    lwRatio = avgWidth > 0 ? avgLength / avgWidth : 0.0;

    // 3. CIELAB Color Profile (Indices 3, 4, 5)
    cielabL = widget.results.measures[3];
    cielabA = widget.results.measures[4];
    cielabB = widget.results.measures[5];

    // 🏆 UNIDO EXACT MILLING GRADES
    if (brokenPercentage < 5.0) {
      gradeTitle = "Premium Grade";
      gradeColor = Colors.green;
    } else if (brokenPercentage < 10.0) {
      gradeTitle = "Grade 1";
      gradeColor = Colors.lightGreen;
    } else if (brokenPercentage < 15.0) {
      gradeTitle = "Grade 2";
      gradeColor = Colors.orange;
    } else if (brokenPercentage < 20.0) {
      gradeTitle = "Grade 3";
      gradeColor = Colors.deepOrange;
    } else {
      gradeTitle = "Below Standard";
      gradeColor = Colors.redAccent;
    }

    // 📐 UNIDO EXACT GRAIN SHAPES
    if (lwRatio >= 3.0) {
      grainShape = "Slender";
    } else if (lwRatio >= 2.1) {
      grainShape = "Medium";
    } else {
      grainShape = "Bold / Short";
    }

    // ⚪ UNIDO CHALKY CLASSIFICATION
    chalkyStatus = chalkyPct > 20.0 ? "Chalky" : "Not Chalky";

    // 🚨 UNIDO 10% DEFECT ALERTS
    if (blackPct > 10.0) qualityAlerts.add("Damaged/Defective (>10% Black)");
    if (greenPct > 10.0) qualityAlerts.add("Immature Grains (>10% Green)");
    if (redPct > 10.0) qualityAlerts.add("Red Strips (>10% Red)");
    if (yellowPct > 10.0) qualityAlerts.add("Fermented (>10% Yellow)");
  }

  Future<void> _saveToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('scan_history') ?? [];

    String locationData = "Opted Out";

    // 📍 FETCH GPS IF OPTED IN
    if (widget.saveGps) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          // 🚨 FIXED DEPRECATED ACCURACY SETTING HERE
          Position position = await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.medium));

          locationData =
              "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        } else {
          locationData = "Permission Denied";
        }
      } catch (e) {
        locationData = "GPS Error";
      }
    }

    // 🕒 DATE & TIME ARE AUTOMATICALLY SAVED HERE
    final scanData = jsonEncode({
      'date':
          DateTime.now().toString().split('.')[0], // Captures Exact Date & Time
      'location': locationData, // Captures Optional GPS
      'grade': gradeTitle,
      'brokenPercent': brokenPercentage.toStringAsFixed(1),
      'length': avgLength.toStringAsFixed(2),
      'shape': grainShape,
      'totalGrains': totalGrains.toInt()
    });

    history.insert(0, scanData);
    if (history.length > 100) history = history.sublist(0, 100);
    await prefs.setStringList('scan_history', history);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Analysis Results',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP HEADER ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(widget.image,
                      width: 100, height: 100, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gradeTitle,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: gradeColor)),
                      const SizedBox(height: 4),
                      Text('Shape: $grainShape',
                          style: const TextStyle(fontSize: 16)),
                      Text('Chalkiness: $chalkyStatus',
                          style: const TextStyle(fontSize: 16)),
                      Text('Total Grains: ${totalGrains.toInt()}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(thickness: 1.5)),

            // --- DYNAMIC ALERTS SECTION ---
            if (qualityAlerts.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text('Quality Alerts',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 12),
              ...qualityAlerts.map((alert) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200)),
                    child: Text(alert,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                  )),
              const SizedBox(height: 24),
            ],

            // --- DETAILED METRICS ---
            const Text('Physical Metrics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                children: [
                  _buildMetricRow('Broken Grains',
                      '${brokenPercentage.toStringAsFixed(1)}%'),
                  const Divider(height: 24),
                  _buildMetricRow(
                      'Average Length', '${avgLength.toStringAsFixed(2)} mm'),
                  const Divider(height: 24),
                  _buildMetricRow(
                      'Length/Width Ratio', lwRatio.toStringAsFixed(2)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- CIELAB COLOR PROFILE ---
            const Text('CIELAB Color Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200)),
              child: Column(
                children: [
                  _buildMetricRow('L* (Lightness)', cielabL.toStringAsFixed(2)),
                  const Divider(height: 24),
                  _buildMetricRow(
                      'a* (Green to Red)', cielabA.toStringAsFixed(2)),
                  const Divider(height: 24),
                  _buildMetricRow(
                      'b* (Blue to Yellow)', cielabB.toStringAsFixed(2)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- SCAN ANOTHER BUTTON ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.purple, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Scan Another Sample',
                    style: TextStyle(fontSize: 18, color: Colors.purple)),
              ),
            ),
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
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ],
    );
  }
}
