import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Make sure to add this!
import 'services/rice_inference.dart';
import 'results_screen.dart';
import 'history_screen.dart';
import 'app_info_screen.dart';

// -------------------------------------------------------------------
// 🧠 BACKGROUND ISOLATE: Extremely fast Image Validation Math
// -------------------------------------------------------------------
bool _isImagePoorQuality(String imagePath) {
  try {
    final bytes = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) return false;

    // Shrink it down to 200px so the math is instant
    final smallImage = img.copyResize(image, width: 200);
    double totalLuminance = 0.0;

    for (var p in smallImage) {
      // Get standard perceived luminance of the pixel
      totalLuminance += p.luminanceNormalized;
    }

    double avgLuminance =
        totalLuminance / (smallImage.width * smallImage.height);

    // Warn if it is incredibly dark (< 25%) or completely washed out (> 85%)
    // Washed out images usually indicate motion blur or terrible glare
    return avgLuminance < 0.25 || avgLuminance > 0.85;
  } catch (e) {
    return false; // If the check fails, just let them pass
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _isProcessing = false;
  int _selectedRiceType = 0;
  bool _optInGPS = false;

  final ImagePicker _picker = ImagePicker();
  final RiceClassifier _classifier = RiceClassifier();

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  Future<void> _captureImage(ImageSource source) async {
    // 🚨 FIX 1: Force native OS to compress the image BEFORE our app loads it into RAM!
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 2048, // The absolute max our AI needs
      maxHeight: 2048,
      imageQuality: 85, // Compresses the JPEG size natively
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = true;
      });

      bool poorQuality = await compute(_isImagePoorQuality, pickedFile.path);

      setState(() {
        _isProcessing = false;
      });

      if (poorQuality && mounted) {
        _showValidationWarning();
      }
    }
  }

  void _showValidationWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Quality Warning'),
          ],
        ),
        content: const Text(
            'This image appears to be too dark, washed out, or blurry.\n\nFor accurate AI results, please ensure the grains are evenly lit on a blue background.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _image = null); // Clear the bad image
            },
            child: const Text('Retake Photo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), // Keep the image
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAnalysis() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final results = await _classifier.predict(_image!, _selectedRiceType);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
                image: _image!, results: results, saveGps: _optInGPS),
          ));
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Rice Scan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'App Info',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AppInfoScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HistoryScreen())),
          )
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text('Please wait...', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Guidelines Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Capture Guidelines',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text('• Place rice sample on a flat BLUE background.'),
                        Text(
                            '• Ensure grains are spread out and NOT touching.'),
                        Text(
                            '• Ensure good, even lighting without heavy shadows.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rice Type Selector
                  DropdownButtonFormField<int>(
                    initialValue: _selectedRiceType,
                    decoration: const InputDecoration(
                      labelText: 'Select Rice Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Paddy Rice')),
                      DropdownMenuItem(
                          value: 1,
                          child: Text('Brown Rice')), // 🚨 ADDED BROWN RICE
                      DropdownMenuItem(
                          value: 2,
                          child: Text('White Rice')), // 🚨 SHIFTED WHITE TO 2
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedRiceType = value!),
                  ),
                  // 📍 OPTIONAL GPS TOGGLE
                  CheckboxListTile(
                    title: const Text('Include GPS Location (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Tags the scan with your current coordinates.'),
                    value: _optInGPS,
                    activeColor: Colors.green,
                    onChanged: (bool? value) {
                      setState(() {
                        _optInGPS = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),

                  // Image Preview Area
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 60, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No image selected',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // ---------------------------------------------------------
                  // 📸 DYNAMIC ACTION BUTTONS (Confirm or Retake Flow)
                  // ---------------------------------------------------------
                  if (_image == null) ...[
                    // STATE 1: NO IMAGE SELECTED YET
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _captureImage(ImageSource.camera),
                          icon: const Icon(Icons.camera),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade900,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _captureImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // STATE 2: IMAGE CAPTURED - CONFIRM OR RETAKE
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Are you happy with this photo?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // a) Retake Button
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _image =
                                  null; // Clears the image to let them retake
                            });
                          },
                          icon: const Icon(Icons.replay),
                          label: const Text('Retake'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                        // b) Confirm & Analyze Button
                        ElevatedButton.icon(
                          onPressed: _runAnalysis,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirm & Analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
