import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';
import '../core/app_background.dart';

class SealReflectionScreen extends StatefulWidget {
  final int reflectionId;
  final String defaultTitle;

  const SealReflectionScreen({Key? key, required this.reflectionId, required this.defaultTitle}) : super(key: key);

  @override
  State<SealReflectionScreen> createState() => _SealReflectionScreenState();
}

class _SealReflectionScreenState extends State<SealReflectionScreen> {
  late TextEditingController _titleController;
  DateTime _selectedUnlockDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedUnlockDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.twilightPurple),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedUnlockDate = picked;
      });
    }
  }

  Future<void> _sealAndSend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.post(
        ApiConfig.sendReflectionForward,
        {
          "reflection": widget.reflectionId,
          "title": _titleController.text.trim(),
          "unlock_date": _selectedUnlockDate.toIso8601String(),
        },
      );

      if (response.statusCode == 201) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to seal and send reflection forward.")),
        );
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Seal your reflection", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              const Text("Send this reflection forward as a brand new capsule into your future.", style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 32),
              const Text("Capsule title", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text("When should your future self receive this?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('d MMMM yyyy').format(_selectedUnlockDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      Icon(Icons.calendar_today_rounded, color: AppColors.twilightPurple, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sealAndSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.twilightPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Seal Capsule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}