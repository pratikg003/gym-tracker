import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting backup: $e')));
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    try {
      // 1. Ask the user to pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        if (!context.mounted) return;

        // Confirm overwrite
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Backup?'),
            content: const Text(
              'This will overwrite all your current workout data. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // 2. Perform the overwrite
        File importedFile = File(result.files.single.path!);
        String originalDbPath = await DatabaseHelper.instance.getDatabasePath();

        // Close the database connection first!
        await DatabaseHelper.instance.close();

        // Copy the imported file over the old one
        await importedFile.copy(originalDbPath);

        // Optional: Re-initialize the database connection immediately
        // await DatabaseHelper.instance.database;

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Backup restored successfully! Please restart the app.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error restoring backup: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Data Management",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Export Database Backup"),
            subtitle: const Text("Save your workout history externally"),
            onTap: () => _exportDatabase(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text("Restore Database Backup"),
            subtitle: const Text(
              "Import a previously saved GymTracker.db file",
            ),
            onTap: () => _importDatabase(context),
          ),
        ],
      ),
    );
  }
}
