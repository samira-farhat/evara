import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';
import '../core/app_background.dart';

class SealReflectionScreen extends StatefulWidget {
  final int reflectionId;
  final String defaultTitle;
  final int? initialChapterId;

  const SealReflectionScreen({
    Key? key,
    required this.reflectionId,
    required this.defaultTitle,
    this.initialChapterId,
  }) : super(key: key);

  @override
  State<SealReflectionScreen> createState() => _SealReflectionScreenState();
}

class _SealReflectionScreenState extends State<SealReflectionScreen> {
  late TextEditingController _titleController;
  late DateTime _selectedUnlockDate;
  bool _isLoading = false;
  bool _isLoadingChapters = true;

  int? _selectedChapterId;
  List<Map<String, dynamic>> _chapters = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedUnlockDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 30));

    _titleController = TextEditingController(text: widget.defaultTitle);
    _selectedChapterId = widget.initialChapterId;
    _fetchChapters();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _fetchChapters() async {
    try {
      final response = await ApiClient.get(ApiConfig.chapters);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> fetchedChapters = [];

        if (data is List) {
          fetchedChapters = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['results'] is List) {
          fetchedChapters = List<Map<String, dynamic>>.from(data['results']);
        }

        setState(() {
          _chapters = fetchedChapters;
          _isLoadingChapters = false;
        });
      } else {
        setState(() {
          _isLoadingChapters = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoadingChapters = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();

    final normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final initial = _selectedUnlockDate.isAfter(
      normalizedToday,
    )
        ? _selectedUnlockDate
        : normalizedToday.add(const Duration(days: 1));


    final picked = await showDatePicker(
      context: context,

      initialDate: initial,

      firstDate: normalizedToday.add(
        const Duration(days: 1),
      ),

      lastDate: DateTime(2100),

      helpText: "Select Unlock Date",

      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.twilightPurple,
              onPrimary: Colors.white,
              surface: AppColors.twilightPurple,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );


    if (picked != null) {
      setState(() {
        _selectedUnlockDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  void _showChapterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.twilightPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Select Chapter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: _isLoadingChapters
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text(
                          "No Chapter",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        trailing: _selectedChapterId == null
                            ? const Icon(Icons.check_rounded, color: Colors.white)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedChapterId = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ..._chapters.map((chapter) {
                        final int chapterId = chapter['id'];
                        final String chapterTitle = chapter['title'] ?? 'Untitled Chapter';
                        return ListTile(
                          title: Text(
                            chapterTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          trailing: _selectedChapterId == chapterId
                              ? const Icon(Icons.check_rounded, color: Colors.white)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedChapterId = chapterId;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          "chapter": _selectedChapterId,
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

  String _getSelectedChapterName() {
    if (_selectedChapterId == null) {
      return "No Chapter";
    }
    for (var chapter in _chapters) {
      if (chapter['id'] == _selectedChapterId) {
        return chapter['title'] ?? 'Selected Chapter';
      }
    }
    return "No Chapter";
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
              Text(
                "Seal your reflection",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text("Send this reflection forward as a brand new capsule into your future.", style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 32),
              const Text("Capsule title", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black26),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Chapter", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showChapterBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getSelectedChapterName(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black26),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
                    ],
                  ),
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Custom date", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('d. MMM yyyy').format(_selectedUnlockDate),
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
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