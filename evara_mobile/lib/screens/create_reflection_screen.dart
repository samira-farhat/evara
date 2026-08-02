import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';
import 'seal_reflection_screen.dart';

class CreateReflectionScreen extends StatefulWidget {
  final int capsuleId;
  final String capsuleTitle;
  final String capsuleType;

  const CreateReflectionScreen({
    Key? key,
    required this.capsuleId,
    required this.capsuleTitle,
    required this.capsuleType,
  }) : super(key: key);

  @override
  State<CreateReflectionScreen> createState() => _CreateReflectionScreenState();
}

class _CreateReflectionScreenState extends State<CreateReflectionScreen> {
  late TextEditingController _titleController;
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = false;
  final List<XFile> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: "${widget.capsuleTitle} - Reflection");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _getPromptText() {
    switch (widget.capsuleType) {
      case 'prediction':
        return "Was your prediction accurate? What did you learn from how things turned out?";
      case 'accountability':
        return "Did you achieve your goal? What progress did you make along the way?";
      case 'memory':
      default:
        return "What does this memory mean to you now? How do you feel looking back at this moment?";
    }
  }

  Future<void> _pickFiles() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images);
      });
    }
  }

  Future<void> _saveReflection({bool sendToFuture = false}) async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your reflection content.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.post(
        ApiConfig.reflections,
        {
          "capsule": widget.capsuleId,
          "content": _contentController.text.trim(),
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final reflectionId = data['id'];

        if (sendToFuture) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SealReflectionScreen(
                reflectionId: reflectionId,
                defaultTitle: _titleController.text.trim(),
              ),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        final err = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save reflection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Reflecting on", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black45)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getPromptText(),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.twilightPurple),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: "Write your thoughts here...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text("Add Attachments"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.twilightPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text("${_selectedFiles.length} file(s) selected", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _saveReflection(sendToFuture: false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Save Reflection", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _saveReflection(sendToFuture: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.twilightPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text("Save & Send to Future", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildAppBar() {
    return Padding(
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
          const Text("Write Reflection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}