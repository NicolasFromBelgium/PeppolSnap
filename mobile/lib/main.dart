// mobile/lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

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

// ----------------------------------------------------------
// 1. Splash → decides if we need onboarding or go straight to home
// ----------------------------------------------------------
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
    final hasCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasCompleted ? const HomePage() : const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

// ----------------------------------------------------------
// 2. Onboarding screen – minimal PEPPOL seller data
// ----------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _vatController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _ibanController = TextEditingController();

  bool _saving = false;

  Future<void> _saveSellerData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('seller_company', _companyController.text.trim());
    await prefs.setString('seller_vat', _vatController.text.trim());
    await prefs.setString('seller_street', _streetController.text.trim());
    await prefs.setString('seller_city', _cityController.text.trim());
    await prefs.setString('seller_postal', _postalController.text.trim());
    await prefs.setString('seller_iban', _ibanController.text.trim());
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome to PeppolSnap')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.business, size: 80, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'One-time setup – your company details\n(mandatory for PEPPOL invoices)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company name *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vatController,
              decoration: const InputDecoration(labelText: 'VAT number * (ex: BE0123456789)', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street + number *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _postalController,
                    decoration: const InputDecoration(labelText: 'Postal code *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 7,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ibanController,
              decoration: const InputDecoration(labelText: 'IBAN (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveSellerData,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Continue', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ----------------------------------------------------------
// 3. HomePage – just a placeholder for now (we’ll replace it next step)
// ----------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PeppolSnap')),
    body: const Center(
      child: Text('HomePage – scanner coming in step 2!', style: TextStyle(fontSize: 24)),
    ),
  );
}
