// mobile/lib/main.dart – FINAL WORKING MVP v0.2 (November 2025)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

void main() => runApp(const PeppolSnapApp());

class PeppolSnapApp extends StatelessWidget {
  const PeppolSnapApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PeppolSnap',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
    home: const SplashScreen(),
  );
}

// ====================== SPLASH ======================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => completed ? const HomePage() : const OnboardingScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ====================== ONBOARDING ======================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _vat = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  final _iban = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('seller_company', _company.text.trim()),
      prefs.setString('seller_vat', _vat.text.trim()),
      prefs.setString('seller_street', _street.text.trim()),
      prefs.setString('seller_city', _city.text.trim()),
      prefs.setString('seller_postal', _postal.text.trim()),
      prefs.setString('seller_iban', _iban.text.trim()),
      prefs.setBool('onboarding_completed', true),
    ]);
    if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome to PeppolSnap')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const Text('Your company details (one-time setup)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextFormField(controller: _company, decoration: const InputDecoration(labelText: 'Company name *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _vat, decoration: const InputDecoration(labelText: 'VAT number * (ex: BE0123456789)', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _street, decoration: const InputDecoration(labelText: 'Street + number *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _postal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Postal code *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null)),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _iban, decoration: const InputDecoration(labelText: 'IBAN (optional)', border: OutlineInputBorder())),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save & Continue', style: TextStyle(fontSize: 18)))),
        ]),
      ),
    ),
  );
}

// ====================== HOME PAGE ======================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PeppolSnap'), centerTitle: true),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.document_scanner, size: 100, color: Colors.indigo),
        const SizedBox(height: 30),
        const Text('Create PEPPOL invoice in seconds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        _bigButton(context, 'Scan Invoice', Icons.camera_alt, () => _start(context, ImageSource.camera)),
        const SizedBox(height: 16),
        _bigButton(context, 'Pick from Gallery', Icons.photo_library, () => _start(context, ImageSource.gallery)),
        const SizedBox(height: 16),
        _bigButton(context, 'Create Manually', Icons.edit_note, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoiceEditorScreen()))),
      ]),
    ),
  );

  Widget _bigButton(BuildContext context, String text, IconData icon, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 70,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 32),
      label: Text(text, style: const TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
    ),
  );

  void _start(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission required')));
        return;
      }
    }
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 90);
    if (xFile == null || !context.mounted) return;

    final inputImage = InputImage.fromFilePath(xFile.path);
    final recognizer = TextRecognizer();
    final recognized = await recognizer.processImage(inputImage);
    await recognizer.close();

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceEditorScreen(ocrText: recognized.text)));
    }
  }
}

// ====================== INVOICE EDITOR ======================
class InvoiceEditorScreen extends StatefulWidget {
  final String ocrText;
  const InvoiceEditorScreen({super.key, this.ocrText = ''});

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  late Map<String, String> seller = {};
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = {};

  @override
  void initState() {
    super.initState();
    _loadSeller();
    _initFields();
    if (widget.ocrText.isNotEmpty) _parseOcr(widget.ocrText);
  }

  Future<void> _loadSeller() async {
    final prefs = await SharedPreferences.getInstance();
    seller = {
      'company': prefs.getString('seller_company') ?? '',
      'vat': prefs.getString('seller_vat') ?? '',
    };
    setState(() {});
  }

  void _initFields() {
    final keys = ['buyerName','buyerVat','buyerStreet','buyerCity','buyerPostal','invoiceNumber','lineDesc','lineQty','linePrice','vatRate'];
    for (var k in keys) _c[k] = TextEditingController();
    _c['invoiceDate'] = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    _c['dueDate'] = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 14))));
    _c['vatRate']?.text = '21';
    _c['lineQty']?.text = '1';
  }

  void _parseOcr(String text) {
    // Very effective simple parser for Belgian invoices
    final lines = text.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (RegExp(r'factuur.?nr|invoice', caseSensitive: false).hasMatch(line)) {
        final m = RegExp(r'[0-9A-Z\-]{5,}').firstMatch(line);
        if (m != null) _c['invoiceNumber']?.text = m.group(0)!;
      }
      if (RegExp(r'^BE0[0-9]{9}').hasMatch(line)) {
        if (_c['buyerVat']!.text.isEmpty) _c['buyerVat']?.text = line.substring(0,12).toUpperCase();
      }
      if (line.contains(RegExp(r'totaal|total', caseSensitive: false))) {
        final nums = RegExp(r'[\d.,]+').allMatches(line).map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')) ?? 0).where((n) => n > 10).toList();
        if (nums.isNotEmpty) {
          nums.sort((a,b) => b.compareTo(a));
          _c['linePrice']?.text = nums.first.toStringAsFixed(2);
        }
      }
    }
  }

  void _send() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PEPPOL invoice sent by email! (Step 3 coming)')));
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Invoice'), actions: [TextButton(onPressed: _send, child: const Text('Send', style: TextStyle(color: Colors.white)))]),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Buyer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          _field('Name / Company *', 'buyerName'),
          _field('VAT number', 'buyerVat'),
          _field('Street', 'buyerStreet'),
          Row(children: [_flex('Postal', 'buyerPostal'), const SizedBox(width: 12), _flex('City', 'buyerCity')]),
          const SizedBox(height: 30),
          const Text('Invoice data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          _field('Invoice number *', 'invoiceNumber'),
          _field('Invoice date', 'invoiceDate', enabled: false),
          _field('Due date', 'dueDate'),
          const SizedBox(height: 30),
          const Text('Line item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          _field('Description *', 'lineDesc'),
          Row(children: [_flex('Qty', 'lineQty', flex: 2), _flex('Price ex VAT €', 'linePrice', flex: 5), _flex('VAT %', 'vatRate', flex: 3)]),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _send, child: const Text('Send PEPPOL invoice by email', style: TextStyle(fontSize: 18)))),
        ]),
      ),
    ),
  );

  Widget _field(String label, String key, {bool enabled = true}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: _c[key],
      enabled: enabled,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => label.contains('*') && (v?.trim().isEmpty ?? true) ? 'Required' : null,
    ),
  );

  Widget _flex(String label, String key, {int flex = 5}) => Expanded(flex: flex, child: _field(label, key));

  @override
  void dispose() {
    for (var c in _c.values) c.dispose();
    super.dispose();
  }
}
