import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';

class ChapterDetailsScreen extends StatefulWidget {
  final int chapterId;

  const ChapterDetailsScreen({Key? key, required this.chapterId}) : super(key: key);

  @override
  State<ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();
}

class _ChapterDetailsScreenState extends State<ChapterDetailsScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _titleErrorMessage;
  Map<String, dynamic>? _chapterData;
  List<dynamic> _chapterCapsules = [];

  // Edit fields controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchChapterDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchChapterDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get("${ApiConfig.chapters}${widget.chapterId}/");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chapterData = data;
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';

          if (data is Map && data.containsKey('capsules')) {
            _chapterCapsules = data['capsules'] ?? [];
          } else if (data is Map && data.containsKey('results')) {
            _chapterCapsules = data['results'] ?? [];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load chapter details.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error. Please check your network.";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _titleErrorMessage = "Chapter title cannot be empty.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _titleErrorMessage = null;
    });

    try {
      final request = http.MultipartRequest('PATCH', Uri.parse("${ApiConfig.chapters}${widget.chapterId}/"));
      final headers = await ApiClient.authHeaders();
      request.headers.addAll(headers);

      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'cover_image',
            bytes,
            filename: _selectedImage!.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
          _selectedImage = null;
          _titleErrorMessage = null;
        });
        _fetchChapterDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chapter updated successfully!")),
        );
      } else {
        setState(() {
          _isSaving = false;
        });

        String errorMessage = "Failed to update chapter. Please try again.";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('title')) {
            final titleErrors = errorData['title'];
            if (titleErrors is List && titleErrors.isNotEmpty) {
              errorMessage = titleErrors[0].toString();
            } else if (titleErrors is String) {
              errorMessage = titleErrors;
            }
          }
        } catch (_) {}

        setState(() {
          _titleErrorMessage = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _titleErrorMessage = "Connection error during update.";
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
              ),

              SizedBox(height: 16),

              Text(
                "Delete Chapter",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),

              SizedBox(height: 8),

              Text(
                "Are you sure you want to delete this chapter? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.5)),
              ),

              SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.grey.shade100,
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteChapter();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                        side: BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteChapter() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.delete("${ApiConfig.chapters}${widget.chapterId}/");

      if (response.statusCode == 204 || response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete chapter.")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error during deletion.")),
      );
    }
  }

  void _showOptionsMenu(BuildContext context, TapDownDetails details) {
    final position = details.globalPosition;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.05),
      transitionDuration: Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              top: position.dy - 10,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        dense: true,
                        horizontalTitleGap: 8,
                        leading: Icon(Icons.edit_outlined, color: AppColors.twilightPurple, size: 16),
                        title: Text(
                          "Edit",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                      ListTile(
                        dense: true,
                        horizontalTitleGap: 8,
                        leading: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                        title: Text(
                          "Delete",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDelete();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCapsuleTypeIcon(String type) {
    switch (type) {
      case "prediction":
        return Icons.nightlight_round_outlined;
      case "accountability":
        return Icons.track_changes_rounded;
      case "letter":
        return Icons.favorite_border_rounded;
      case "memory":
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _chapterData?['title'] ?? 'Chapter';
    final description = _chapterData?['description'] ?? '';
    final coverImage = _chapterData?['cover_image'] != null ? ApiConfig.buildMediaUrl(_chapterData!['cover_image']) : null;
    final capsuleCount = _chapterCapsules.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(color: AppColors.twilightPurple),
        )
            : _errorMessage != null
            ? Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.rosePink, size: 48),

                SizedBox(height: 16),

                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),

                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _fetchChapterDetails,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.twilightPurple),
                  child: Text("Retry", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchChapterDetails,
          color: AppColors.twilightPurple,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isEditing) {
                          setState(() {
                            _isEditing = false;
                            _selectedImage = null;
                            _titleErrorMessage = null;
                            _titleController.text = _chapterData?['title'] ?? '';
                            _descriptionController.text = _chapterData?['description'] ?? '';
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(_isEditing ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
                      ),
                    ),
                    Text(
                      _isEditing ? "Edit Chapter" : title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    _isEditing
                        ? SizedBox(width: 38)
                        : GestureDetector(
                      onTapDown: (details) => _showOptionsMenu(context, details),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.more_horiz_rounded, size: 18, color: Colors.black87),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // EDIT MODE UI
                if (_isEditing) ...[
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepPurple.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_selectedImage != null)
                              FutureBuilder<Uint8List>(
                                future: _selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                  }
                                  return Container(color: Colors.grey.shade200);
                                },
                              )
                            else if (coverImage != null && coverImage.isNotEmpty)
                              Image.network(coverImage, fit: BoxFit.cover)
                            else ...[
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.twilightPurple,
                                        AppColors.mauve,
                                        AppColors.rosePink,
                                        AppColors.deepPurple,
                                      ],
                                      stops: [0.0, 0.35, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.deepPurple.withValues(alpha: 0.35),
                                  ),
                                ),
                                CustomPaint(
                                  painter: EtherealStardustPainter(),
                                ),
                              ],
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 18),

                                    SizedBox(width: 8),

                                    Text(
                                      _selectedImage != null || (coverImage != null && coverImage.isNotEmpty)
                                          ? "Change cover photo"
                                          : "Cover photo",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Text("CHAPTER NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),

                  SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _titleErrorMessage != null ? Colors.redAccent : Colors.grey.shade200,
                        width: _titleErrorMessage != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: _titleController,
                      onChanged: (_) {
                        if (_titleErrorMessage != null) {
                          setState(() {
                            _titleErrorMessage = null;
                          });
                        }
                      },
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  if (_titleErrorMessage != null) ...[
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        _titleErrorMessage!,
                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  SizedBox(height: 16),

                  Text("DESCRIPTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),

                  SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.twilightPurple, width: 1.5),
                      color: AppColors.twilightPurple.withValues(alpha: 0.08),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isSaving ? null : _saveChanges,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _isSaving
                                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.twilightPurple, strokeWidth: 2))
                                : Text(
                              "Save Changes",
                              style: TextStyle(
                                color: AppColors.twilightPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[

                  // NORMAL VIEW UI
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepPurple.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          coverImage != null && coverImage.isNotEmpty
                              ? Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallbackCoverBox(),
                          )
                              : _buildFallbackCoverBox(),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 16,
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  if (description.isNotEmpty) ...[
                    Text("DESCRIPTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),

                    SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        description,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                  ],

                  // Capsules Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Capsules in this chapter",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      Text(
                        "$capsuleCount",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.twilightPurple,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  _chapterCapsules.isEmpty ? _buildEmptyCapsulesState() : _buildCapsulesList(),
                ],

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCoverBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.3),
      ),
      child: Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.deepPurple, size: 36),
      ),
    );
  }

  Widget _buildEmptyCapsulesState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lavender.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.deepPurple, size: 28),
          ),

          SizedBox(height: 14),

          Text(
            "No capsules yet",
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 6),

          Text(
            "Assign capsules to this chapter when creating them.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsulesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _chapterCapsules.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final capsule = _chapterCapsules[index];
        return _buildCapsuleCard(capsule);
      },
    );
  }

  Widget _buildCapsuleCard(dynamic capsule) {
    final title = capsule['title'] ?? 'Untitled';
    final rawType = capsule['capsule_type'] ?? 'memory';

    String formattedType = 'Memory Capsule';
    if (rawType == 'prediction') {
      formattedType = 'Prediction Capsule';
    } else if (rawType == 'accountability') {
      formattedType = 'Accountability Capsule';
    } else if (rawType == 'letter') {
      formattedType = 'Letter Capsule';
    } else {
      formattedType = '${rawType[0].toUpperCase()}${rawType.substring(1)} Capsule';
    }

    final daysRemaining = capsule['days_remaining'] ?? 0;
    final timeAgoText = '$daysRemaining days';

    String dateText = '';
    try {
      if (capsule['unlock_date'] != null) {
        final parsedDate = DateTime.parse(capsule['unlock_date']);
        dateText = DateFormat('MMM yyyy').format(parsedDate);
      }
    } catch (_) {
      dateText = '';
    }

    Color capsuleColor = AppColors.lavender;
    if (rawType == 'prediction') {
      capsuleColor = AppColors.mauve;
    } else if (rawType == 'accountability') {
      capsuleColor = AppColors.rosePink;
    }

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: capsuleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.lock_outline_rounded, color: capsuleColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_getCapsuleTypeIcon(rawType), color: capsuleColor, size: 14),
                      SizedBox(width: 6),
                      Text(
                        formattedType,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgoText,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  dateText,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EtherealStardustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(101010);

    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      final opacity = random.nextDouble() * 0.4 + 0.1;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}