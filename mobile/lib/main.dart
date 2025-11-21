// mobile/lib/main.dart — PEPPOLSNAP v1.0 — 100% WORKING
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'screens/history_screen.dart';

void main() => runApp(const PeppolSnapApp());

class PeppolSnapApp extends StatelessWidget {
  const PeppolSnapApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PeppolSnap',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
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
    final completed = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => completed ? const HomePage() : const OnboardingScreen()),
    );
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
      prefs.setBool('onboarding_done', true),
    ]);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome to PeppolSnap')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const Text('Your company (one-time setup)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextFormField(controller: _company, decoration: const InputDecoration(labelText: 'Company name *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _vat, decoration: const InputDecoration(labelText: 'VAT number * (BE0123456789)', border: OutlineInputBorder()), validator: (v) => !RegExp(r'^BE[0-9]{10}$').hasMatch(v ?? '') ? 'Invalid VAT' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _street, decoration: const InputDecoration(labelText: 'Street + number *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _postal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Postal code *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null)),
          ]),
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
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.receipt_long, size: 120, color: Colors.indigo),
        const SizedBox(height: 32),
        const Text('Create PEPPOL invoice in seconds', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 60),
        _bigButton(context, 'Scan Invoice', Icons.camera_alt, () => _scan(context, ImageSource.camera)),
        const SizedBox(height: 16),
        _bigButton(context, 'Pick from Gallery', Icons.photo_library, () => _scan(context, ImageSource.gallery)),
        const SizedBox(height: 16),
        _bigButton(context, 'Create Manually', Icons.edit_note, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoiceFormScreen()))),
        const SizedBox(height: 40),
        _bigButton(context, 'View History', Icons.history, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()))),
      ]),
    ),
  );

  Widget _bigButton(BuildContext context, String text, IconData icon, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 70,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 34),
      label: Text(text, style: const TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
    ),
  );

  void _scan(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera && !await Permission.camera.isGranted) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission required')));
        return;
      }
    }

    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 95);
    if (xFile == null || !context.mounted) return;

    final inputImage = InputImage.fromFilePath(xFile.path);
    final recognizer = TextRecognizer();
    final recognized = await recognizer.processImage(inputImage);
    await recognizer.close();

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceFormScreen(ocrText: recognized.text)));
    }
  }
}

// ====================== INVOICE FORM ======================
class InvoiceFormScreen extends StatefulWidget {
  final String ocrText;
  const InvoiceFormScreen({super.key, this.ocrText = ''});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, String> seller;
  final Map<String, TextEditingController> _c = {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadSeller();
    _initControllers();
    if (widget.ocrText.isNotEmpty) _parseOcr(widget.ocrText);
  }

  Future<void> _loadSeller() async {
    final prefs = await SharedPreferences.getInstance();
    seller = {
      'company': prefs.getString('seller_company') ?? '',
      'vat': prefs.getString('seller_vat') ?? '',
      'street': prefs.getString('seller_street') ?? '',
      'city': prefs.getString('seller_city') ?? '',
      'postal': prefs.getString('seller_postal') ?? '',
    };
    setState(() {});
  }

  void _initControllers() {
    final keys = ['buyer_name', 'buyer_vat', 'buyer_street', 'buyer_postal', 'buyer_city', 'invoice_number', 'buyer_reference', 'description', 'quantity', 'price_ex_vat', 'vat_rate'];
    for (var k in keys) _c[k] = TextEditingController();
    _c['invoice_date'] = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    _c['due_date'] = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30))));
    _c['quantity']?.text = '1';
    _c['vat_rate']?.text = '21';
  }

  void _parseOcr(String text) {
    final lines = text.toUpperCase().split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.contains('FACTUUR') || line.contains('INVOICE')) {
        final m = RegExp(r'[A-Z0-9\-]{5,}').firstMatch(line);
        if (m != null) _c['invoice_number']?.text = m.group(0)!;
      }
      if (RegExp(r'BE0[0-9]{9}').hasMatch(line)) {
        final vat = RegExp(r'BE0[0-9]{9}').firstMatch(line)?.group(0);
        if (vat != null && _c['buyer_vat']!.text.isEmpty) _c['buyer_vat']?.text = vat;
      }
      if (line.contains('TOTAAL') || line.contains('TOTAL')) {
        final nums = RegExp(r'[\d.,]+').allMatches(line).map((e) => double.tryParse(e.group(0)!.replaceAll(',', '.')) ?? 0).where((n) => n > 10).toList();
        if (nums.isNotEmpty) _c['price_ex_vat']?.text = nums.last.toStringAsFixed(2);
      }
    }
    setState(() {});
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final payload = {
      "seller_company": seller['company'],
      "seller_vat": seller['vat'],
      "seller_street": seller['street'],
      "seller_postal": seller['postal'],
      "seller_city": seller['city'],
      "buyer_name": _c['buyer_name']!.text.trim(),
      "buyer_vat": _c['buyer_vat']!.text.trim(),
      "buyer_street": _c['buyer_street']!.text.trim(),
      "buyer_postal": _c['buyer_postal']!.text.trim(),
      "buyer_city": _c['buyer_city']!.text.trim(),
      "invoice_number": _c['invoice_number']!.text.trim(),
      "invoice_date": _c['invoice_date']!.text,
      "due_date": _c['due_date']!.text,
      "buyer_reference": _c['buyer_reference']!.text.trim(),
      "description": _c['description']!.text.trim(),
      "quantity": _c['quantity']!.text,
      "price_ex_vat": _c['price_ex_vat']!.text,
      "vat_rate": _c['vat_rate']!.text,
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/invoices'), // Android emulator → localhost
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final xml = json['xml'] as String;

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/PEPPOL_${payload['invoice_number']}.xml');
        await file.writeAsString(xml);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice saved: ${file.path}')));
        OpenFile.open(file.path);
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Invoice'), actions: [TextButton(onPressed: _sending ? null : _send, child: _sending ? const CircularProgressIndicator(color: Colors.white) : const Text('Send', style: TextStyle(color: Colors.white)))]),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Buyer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          _field('Name *', 'buyer_name'),
          _field('VAT (BE...) *', 'buyer_vat'),
          _field('Street *', 'buyer_street'),
          Row(children: [_flex('Postal *', 'buyer_postal'), const SizedBox(width: 12), _flex('City *', 'buyer_city', flex: 2)]),
          const SizedBox(height: 24),
          const Text('Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          _field('Invoice number *', 'invoice_number'),
          _field('Buyer reference / PO *', 'buyer_reference'),
          _field('Date', 'invoice_date', enabled: false),
          _field('Due date', 'due_date'),
          const SizedBox(height: 24),
          const Text('Line', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          _field('Description *', 'description'),
          Row(children: [
            _flex('Qty', 'quantity', flex: 2),
            _flex('Price ex VAT', 'price_ex_vat', flex: 4),
            _flex('VAT %', 'vat_rate', flex: 2),
          ]),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _sending ? null : _send, child: _sending ? const CircularProgressIndicator(color: Colors.white) : const Text('Generate & Save PEPPOL XML', style: TextStyle(fontSize: 18)))),
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
