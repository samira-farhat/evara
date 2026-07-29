import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';

class ChaptersTab extends StatefulWidget {
  const ChaptersTab({Key? key}) : super(key: key);

  @override
  State<ChaptersTab> createState() => _ChaptersTabState();
}

class _ChaptersTabState extends State<ChaptersTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allChapters = [];
  List<dynamic> _filteredChapters = [];

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedSortBy = 'newest'; // 'newest', 'oldest', 'updated', 'title'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChaptersLocally);
    _fetchChapters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChapters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(ApiConfig.chapters);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is List) {
            _allChapters = data;
          } else if (data is Map && data.containsKey('results')) {
            _allChapters = data['results'];
          } else {
            _allChapters = [];
          }
          _isLoading = false;
        });
        _filterChaptersLocally();
      } else {
        setState(() {
          _errorMessage = "Failed to load chapters.";
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

  void _filterChaptersLocally() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredChapters = _allChapters.where((chapter) {
        final title = (chapter['title'] ?? '').toLowerCase();
        final description = (chapter['description'] ?? '').toLowerCase();

        return query.isEmpty || title.contains(query) || description.contains(query);
      }).toList();

      // Sorting logic
      _filteredChapters.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        DateTime dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        DateTime updateA = DateTime.tryParse(a['updated_at'] ?? a['created_at'] ?? '') ?? DateTime(2000);
        DateTime updateB = DateTime.tryParse(b['updated_at'] ?? b['created_at'] ?? '') ?? DateTime(2000);
        String titleA = (a['title'] ?? '').toLowerCase();
        String titleB = (b['title'] ?? '').toLowerCase();

        if (_selectedSortBy == 'newest') {
          return dateB.compareTo(dateA);
        } else if (_selectedSortBy == 'oldest') {
          return dateA.compareTo(dateB);
        } else if (_selectedSortBy == 'updated') {
          return updateB.compareTo(updateA);
        } else if (_selectedSortBy == 'title') {
          return titleA.compareTo(titleB);
        }
        return 0;
      });
    });
  }

  void _showFilterSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(24, 20, 24, 34),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Filter & Sort Chapters",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    Text(
                      "SORT BY",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
                    ),

                    SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip("Newest created", 'newest', _selectedSortBy, (val) {
                          setModalState(() => _selectedSortBy = val);
                        }),
                        _buildFilterChip("Oldest created", 'oldest', _selectedSortBy, (val) {
                          setModalState(() => _selectedSortBy = val);
                        }),
                        _buildFilterChip("Recently updated", 'updated', _selectedSortBy, (val) {
                          setModalState(() => _selectedSortBy = val);
                        }),
                        _buildFilterChip("Alphabetical (Title)", 'title', _selectedSortBy, (val) {
                          setModalState(() => _selectedSortBy = val);
                        }),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Apply Filters Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepPurple.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
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
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.deepPurple.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: EtherealStardustPainter(),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _filterChaptersLocally();
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      "Apply Filters",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
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
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, String groupValue, Function(String) onChanged) {
    bool isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.twilightPurple.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.twilightPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.twilightPurple : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _openCreateChapterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CreateChapterBottomSheet(
        onChapterCreated: () {
          _fetchChapters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPurple.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _openCreateChapterModal,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
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
                  onPressed: _fetchChapters,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.twilightPurple),
                  child: Text("Retry", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchChapters,
          color: AppColors.twilightPurple,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chapters",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 16),

                // Search Bar and Filter Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search chapters...",
                            hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.black.withValues(alpha: 0.4)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _filterChaptersLocally();
                              },
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 10),

                    GestureDetector(
                      onTap: _showFilterSortModal,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.tune_rounded, color: AppColors.twilightPurple, size: 20),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                _filteredChapters.isEmpty ? _buildEmptyState() : _buildChaptersList(),

                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(Icons.menu_book_rounded, color: AppColors.deepPurple, size: 32),
          ),

          SizedBox(height: 16),

          Text(
            "Start a Life Chapter",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Organize capsules into stories — University, Career, Travel, or anything you choose.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _filteredChapters.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final chapter = _filteredChapters[index];
        return _buildChapterCard(chapter);
      },
    );
  }

  Widget _buildChapterCard(dynamic chapter) {
    final title = chapter['title'] ?? 'Untitled Chapter';
    final description = chapter['description'] ?? '';
    final capsuleCount = chapter['capsule_count'] ?? 0;
    final coverImage = chapter['cover_image'] != null ? ApiConfig.buildMediaUrl(chapter['cover_image']) : null;

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to Chapter Details screen (Edit, Delete, and inner contents)
      },
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
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 52,
                width: 52,
                child: coverImage != null && coverImage.isNotEmpty
                    ? Image.network(
                  coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackCoverBox(),
                )
                    : _buildFallbackCoverBox(),
              ),
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

                  SizedBox(height: 3),

                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: 3),
                  ],
                  Text(
                    "$capsuleCount ${capsuleCount == 1 ? 'capsule' : 'capsules'}",
                    style: TextStyle(
                      color: AppColors.twilightPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCoverBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.3),
      ),
      child: Icon(Icons.menu_book_rounded, color: AppColors.deepPurple, size: 22),
    );
  }
}

// CREATE CHAPTER BOTTOM SHEET
class _CreateChapterBottomSheet extends StatefulWidget {
  final VoidCallback onChapterCreated;

  const _CreateChapterBottomSheet({Key? key, required this.onChapterCreated}) : super(key: key);

  @override
  State<_CreateChapterBottomSheet> createState() => _CreateChapterBottomSheetState();
}

class _CreateChapterBottomSheetState extends State<_CreateChapterBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _submitChapter() async {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.chapters));

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

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        widget.onChapterCreated();
      } else {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create chapter. Please try again.")),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error during chapter creation.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 30),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.twilightPurple,
                    backgroundColor: AppColors.lavender.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),

                Text(
                  "New Chapter",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                ),

                TextButton(
                  onPressed: _isSubmitting ? null : _submitChapter,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.twilightPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: _isSubmitting
                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),

            SizedBox(height: 24),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 130,
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
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 18),

                              SizedBox(width: 8),

                              Text(
                                _selectedImage != null ? "Change cover photo" : "Cover photo",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
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

            // Chapter Title Input
            Text(
              "CHAPTER NAME",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
            ),

            SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "e.g., University Years",
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Description Input
            Text(
              "DESCRIPTION (OPTIONAL)",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
            ),

            SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "What is this chapter about?",
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
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