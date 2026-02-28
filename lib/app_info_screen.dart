import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Information',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Icon(Icons.grass, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('New Rice Scan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          SizedBox(height: 32),
          ListTile(
            leading: Icon(Icons.memory, color: Colors.blue),
            title: Text('Model Traceability',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Powered by the UNIDO 3rd Place Solution.\nOptimized 12-Tile Edge AI Architecture.'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.gavel, color: Colors.orange),
            title: Text('Legal Disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'This tool is intended for indicative, field-level quality assessment and does not replace laboratory analysis or provide food safety certification.\n\nIntellectual property for the solution is co-owned by UNIDO and AfricaRice.'),
          ),
        ],
      ),
    );
  }
}
