import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';

class ReflectionDetailsScreen extends StatefulWidget {
  final int reflectionId;

  const ReflectionDetailsScreen({Key? key, required this.reflectionId}) : super(key: key);

  @override
  State<ReflectionDetailsScreen> createState() => _ReflectionDetailsScreenState();
}

class _ReflectionDetailsScreenState extends State<ReflectionDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reflection;

  @override
  void initState() {
    super.initState();
    _fetchReflection();
  }

  Future<void> _fetchReflection() async {
    try {
      final response = await ApiClient.get("${ApiConfig.reflections}${widget.reflectionId}/");
      if (response.statusCode == 200) {
        setState(() {
          _reflection = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = _reflection?['created_at'] != null
        ? DateFormat('d MMMM yyyy').format(DateTime.parse(_reflection!['created_at']))
        : '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text("Your Reflection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.twilightPurple))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Written on $createdAt", style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5))),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purpleGlow.withValues(alpha: 0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        _reflection?['content'] ?? '',
                        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}