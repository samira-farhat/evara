import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
// If your app background widget has a specific path, update import accordingly:
// import '../core/app_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.twilightPurple, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.twilightPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last updated: August 2026',
                style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('1. Introduction'),
              _buildSectionBody(
                  'Welcome to our Time Capsule & Life Chapters application. We deeply value your privacy and are committed to safeguarding the personal memories, reflections, and chapters you entrust to us.'
              ),
              _buildSectionTitle('2. Information We Collect'),
              _buildSectionBody(
                  '• Account Data: Your chosen username, email address, and profile settings.\n'
                      '• Capsule Contents: The text memories, photos, reflections, and scheduled future delivery timestamps you create.\n'
                      '• Usage Analytics: Basic performance logs to maintain app stability and improve notifications.'
              ),
              _buildSectionTitle('3. How We Secure Your Memories'),
              _buildSectionBody(
                  'All your time capsules and life entries are encrypted in transit and at rest. Your future-bound messages remain strictly private until their designated unlock date arrives, ensuring absolute confidentiality.'
              ),
              _buildSectionTitle('4. Data Sharing & Disclosure'),
              _buildSectionBody(
                  'We never sell, trade, or rent your personal data or capsule contents to third parties. Your stories belong solely to you.'
              ),
              _buildSectionTitle('5. Deleting Your Account'),
              _buildSectionBody(
                  'You have full autonomy over your data. If you choose to delete your account via your Profile settings, all your chapters, media files, and capsules will be permanently and irreversibly wiped from our database.'
              ),
              _buildSectionTitle('6. Contact Us'),
              _buildSectionBody(
                  'If you have any questions or concerns regarding our privacy practices or your data, please reach out via our in-app support channels.'
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.twilightPurple,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Text(
      body,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF4A4A4A),
        height: 1.5,
      ),
    );
  }
}