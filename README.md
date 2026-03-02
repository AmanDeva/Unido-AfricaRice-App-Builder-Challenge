# rice_quality_app
# UNIDO AfricaRice App Builder Challenge - Top 10 Submission

## 1. How to Install and Run the App
1. Transfer the `app-release.apk` file to any Android device running Android 9 or higher.
2. Tap the APK file to install it. (Ensure "Install from Unknown Sources" is enabled in Android settings).
3. Open the app, accept the disclaimer, and complete the offline profile creation.
4. Use the "Camera" or "Gallery" buttons to load an image of rice on a blue background. The built-in quality validator will guide you if the image is too dark.
5. Tap "Confirm & Analyze" to run the on-device inference and view the full UNIDO grading metrics.

## 2. Device(s) Tested On
The application was rigorously tested and optimized for low-to-mid-range hardware typical in target deployment regions (Ghana, Senegal, etc.):
* **Primary Test Device:** Vivo Y20G (MediaTek Helio G80 processor, 6GB RAM, Android 12).
* **Architecture Support:** The APK is built as a universal "Fat APK" supporting both ARM64 and ARM32 architectures for maximum compatibility with older phones (Tecno, Huawei, Samsung A-Series).

## 3. Average Inference Time
* **Inference Time:** ~90 to 120 seconds per image on a mid-range MediaTek Helio G80 CPU. 
* *Technical Note:* Because the test device lacks a dedicated hardware NPU, inference is executed entirely via CPU multi-threading. We locked the TFLite interpreter to 2 threads to exclusively utilize the high-performance Cortex-A75 cores (avoiding ARM big.LITTLE synchronization lag) to achieve this speed without RAM exhaustion.

## 4. Confirmation of Fully Offline Execution
**This application is 100% offline.** There are absolutely no API calls, cloud processing, or external data requests. The ~50MB ConvNeXt model is bundled entirely within the application's assets. All processing, including CIELAB color math, background isolation, and NoSQL history database storage, happens securely on the device.

## 5. Brief Description of Model Architecture
The app utilizes an optimized version of the 3rd-Place UNIDO winning solution (ConvNeXt-Small Vision Transformer). To deploy this massive model to edge hardware without Out-Of-Memory (OOM) crashes, we applied a strict optimization pipeline:
1. **Tile Reduction:** The original PyTorch export was modified to dynamically process 12 tiles (down from 48), reducing the mobile RAM footprint by 75% while maintaining statistical accuracy.
2. **Graph Surgery:** During ONNX to TensorFlow conversion, unsupported `Erf` (Error Function) nodes in the GELU activation layers were explicitly removed and mapped to native math (`onnx2tf -rtpo Erf`) to prevent fatal Android FlexDelegate crashes.
3. **Quantization:** The final `.tflite` model underwent Dynamic Range Quantization to FP16 (16-bit float), cutting the mathematical workload and file size in half to accommodate mobile CPUs.
A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
