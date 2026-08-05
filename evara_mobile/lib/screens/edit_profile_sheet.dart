import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../core/app_colors.dart';
import 'change_password_dialog.dart';

class EditProfileSheet extends StatefulWidget {
  final String currentUsername;
  final String? currentProfilePicture;
  final VoidCallback onProfileUpdated;

  const EditProfileSheet({
    super.key,
    required this.currentUsername,
    required this.currentProfilePicture,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _usernameController;
  File? _selectedImage;
  Uint8List? _webImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final headers = await ApiClient.authHeaders();
      var request = http.MultipartRequest('PATCH', Uri.parse(ApiConfig.profile));
      request.headers.addAll(headers);

      request.fields['username'] = _usernameController.text.trim();

      if (kIsWeb && _webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_picture',
            _webImageBytes!,
            filename: 'profile_pic.jpg',
          ),
        );
      } else if (!kIsWeb && _selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            _selectedImage!.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        widget.onProfileUpdated();
        Navigator.pop(context);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Please try again.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.lavender)),
                ),
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lavender))
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lavender)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.lavender.withOpacity(0.2),
                      backgroundImage: kIsWeb && _webImageBytes != null
                          ? MemoryImage(_webImageBytes!) as ImageProvider
                          : (!kIsWeb && _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (widget.currentProfilePicture != null && widget.currentProfilePicture!.isNotEmpty
                          ? NetworkImage(ApiConfig.buildMediaUrl(widget.currentProfilePicture)) as ImageProvider
                          : null)),
                      child: (_webImageBytes == null && _selectedImage == null && (widget.currentProfilePicture == null || widget.currentProfilePicture!.isEmpty))
                          ? const Icon(Icons.camera_alt_outlined, color: AppColors.lavender, size: 28)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Darker label color for clear visibility
            const Text(
              'Name',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openChangePasswordDialog,
                icon: const Icon(Icons.lock_reset_rounded, color: AppColors.lavender),
                label: const Text('Change Password', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.lavender),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}