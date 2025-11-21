// mobile/lib/screens/history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<File> invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final dir = await getTemporaryDirectory();
    final files = dir
        .listSync()
        .where((f) => f.path.endsWith('.xml') && f.path.contains('PEPPOL'))
        .toList();
    setState(() {
      invoices = files.map((f) => File(f.path)).toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Invoice History'),
          actions: [
            IconButton(onPressed: _loadInvoices, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: invoices.isEmpty
            ? const Center(child: Text('No invoices yet'))
            : ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (ctx, i) {
                  final file = invoices[i];
                  final name = file.path.split('/').last;
                  return ListTile(
                    leading: const Icon(Icons.description, color: Colors.indigo),
                    title: Text(name),
                    subtitle: Text('Tap to open'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => OpenFile.open(file.path),
                  );
                },
              ),
      );
}
