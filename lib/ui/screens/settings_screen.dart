import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/database_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      // Share the SQLite file
      await Share.shareXFiles([XFile(dbPath)], text: 'Gym Tracker Backup');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting backup: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("Data Management", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Export Database Backup"),
            subtitle: const Text("Save your workout history externally"),
            onTap: () => _exportDatabase(context),
          ),
        ],
      ),
    );
  }
}