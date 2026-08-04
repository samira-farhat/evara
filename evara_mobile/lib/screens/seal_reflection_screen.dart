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
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.twilightPurple,   // selected day circle
              onPrimary: Colors.white,             // number inside selected day
              surface: Colors.white,               // calendar background
              onSurface: Colors.black87,           // normal text
            ),
            dialogBackgroundColor: Colors.white,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Select Chapter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 16),

                Flexible(
                  child: _isLoadingChapters
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: Text(
                          "No Chapter",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        trailing: _selectedChapterId == null
                            ? Icon(Icons.check_rounded, color: Colors.white)
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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          trailing: _selectedChapterId == chapterId
                              ? Icon(Icons.check_rounded, color: Colors.white)
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
          SnackBar(content: Text("Failed to seal and send reflection forward.")),
        );
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error.")),
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
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
                ),
              ),

              SizedBox(height: 24),

              Text(
                "Seal your reflection",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 6),

              Text("Send this reflection forward as a brand new capsule into your future.", style: TextStyle(fontSize: 14, color: Colors.black54)),

              SizedBox(height: 32),

              Text("Capsule title", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),

              SizedBox(height: 8),

              TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black26),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

              SizedBox(height: 24),

              Text("Chapter", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),

              SizedBox(height: 8),

              GestureDetector(
                onTap: _showChapterBottomSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getSelectedChapterName(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black26),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              Text("When should your future self receive this?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),

              SizedBox(height: 8),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.all(18),
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
                            Text("Custom date", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 15)),

                            SizedBox(height: 2),

                            Text(
                              DateFormat('d. MMM yyyy').format(_selectedUnlockDate),
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.calendar_today_rounded, color: AppColors.twilightPurple, size: 20),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sealAndSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.twilightPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Seal Capsule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}