import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';
import 'seal_reflection_screen.dart';

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

    final String reflectionTitle =
    _reflection?['capsule_title'] != null
        ? "${_reflection!['capsule_title']} - Reflection"
        : "Reflection - Future Capsule";

    final int? chapterId =
    _reflection?['capsule_chapter'];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
                    ),
                  ),
                  SizedBox(width: 16),

                  Text("Your Reflection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.twilightPurple))
                  : SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Written on $createdAt", style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5))),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purpleGlow.withValues(alpha: 0.06),
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        _reflection?['content'] ?? '',
                        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                      ),
                    ),

                    SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SealReflectionScreen(
                                reflectionId: widget.reflectionId,
                                defaultTitle: reflectionTitle,
                                initialChapterId: chapterId,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.lock_rounded, size: 18),
                        label: Text("Send to the Future", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.twilightPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
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