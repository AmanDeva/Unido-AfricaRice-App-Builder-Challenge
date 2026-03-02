# RICE_QUALITY_APP  
## UNIDO AfricaRice App Builder Challenge – Top 10 Submission

A fully offline, edge-optimized rice quality grading system designed for real-world agricultural deployment in low-connectivity regions.

---

# Application Preview & Test Device

## Primary Test Device

<img src="https://github.com/user-attachments/assets/ba9a3abf-74c6-4cc8-8d37-92f85f98638c" width="300"/>

**Device:** iQOO Neo9 Pro (Model I2304)  
**OS:** OriginOS 6 (Android 13)  
**Processor:** Snapdragon® 8 Gen 2 (3.2 GHz Octa-Core)  
**Memory:** 12GB RAM (+12GB Extended)  
**Storage:** 256GB  

---

## Version Information

<img src="https://github.com/user-attachments/assets/5370e571-7a7d-4f8b-b51a-ec5064479e05" width="300"/>

**Android Security Update:** January 1, 2026  
**Kernel Version:** 5.15.178 (Android 13)  
**Software Version:** PD2338BF_EX_A_16.2.7.1.W30  

---

## Sample Input Image (Rice on Blue Background)
![Rice Sample]<img width="720" height="1280" alt="image" src="https://github.com/user-attachments/assets/ab2c737e-ea35-4f65-b218-a4c07dd2e5f9" />
)

---

# 1. Installation & Usage

1. Transfer `app-release.apk` to any Android device running **Android 13 or higher**.
2. Enable **Install from Unknown Sources**.
3. Tap the APK file to install.
4. Launch the app and complete offline profile setup.
5. Use **Camera** or **Gallery** to upload a rice image (blue background recommended).
6. Tap **Confirm & Analyze** to generate full UNIDO grading metrics.

---

# 2. Devices Tested

### Primary Device
- iQOO Neo9 Pro (I2304)
- Snapdragon 8 Gen 2
- 12GB RAM
- OriginOS 6 (Android 13)

### APK Architecture
- Universal **Fat APK**
- Supports **ARM64 & ARM32**
- Compatible with Tecno, Huawei, Samsung A-Series devices common in target regions

---

# 3. Average Inference Time

- **70–75 seconds per image**
- CPU multi-threaded execution
- TFLite locked to 2 threads
- Avoided ARM big.LITTLE synchronization lag
- Zero Out-of-Memory (OOM) crashes during testing

---

# 4. Fully Offline Execution

This application is **100% offline**.

- No API calls  
- No cloud processing  
- No external data transmission  
- 50MB ConvNeXt model bundled inside app assets  
- On-device CIELAB color analysis  
- Local CSV report generation  

All computation occurs securely on-device.

---

# 5. Model Architecture & Optimization

## Base Model
Optimized adaptation of the **3rd Place UNIDO Winning Solution**  
ConvNeXt-Small Vision Transformer

---

## Optimization Pipeline

### Tile Reduction
- Reduced tiles from **48 → 12**
- 75% RAM footprint reduction
- Maintained statistical grading accuracy

### Graph Surgery
- Removed unsupported `Erf` nodes in GELU
- Applied `onnx2tf -rtpo Erf`
- Prevented Android FlexDelegate crashes

### Quantization
- Dynamic Range Quantization (FP16)
- 50% model size reduction
- Optimized for mobile CPU execution

---

# Deployment Vision

Engineered for:
- Low-connectivity rural environments
- Commodity Android devices
- Sustainable agricultural impact

Built for scalability.  
Engineered for stability.  
Deployed for impact.

---

# Tech Stack

- Flutter (Android)
- TensorFlow Lite
- ONNX → TensorFlow Conversion
- ConvNeXt Architecture
- On-device CPU Inference

---

# Status

✔ Fully Functional  
✔ Edge Optimized  
✔ Offline Verified  
✔ Competition Submission Ready  

---
---

# Demo Video

🔗 Full Demo: https://your-link-here

**Author:** Khushi  and Aman_Deva
UNIDO AfricaRice App Builder Challenge – Top 10 Finalist









































