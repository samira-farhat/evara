import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/app_colors.dart';
import '../../core/api_config.dart';
import '../../core/api_client.dart';
import '../../core/app_background.dart';
import '../../services/token_storage.dart';

class CreateTab extends StatelessWidget {
  final String? initialType;
  const CreateTab({Key? key, this.initialType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AppBackground(child: SizedBox.shrink());
  }
}

class CapsuleCreationSlideScreen extends StatefulWidget {
  final String? initialType;
  final VoidCallback onClose;

  const CapsuleCreationSlideScreen({Key? key, this.initialType, required this.onClose}) : super(key: key);

  @override
  State<CapsuleCreationSlideScreen> createState() => _CapsuleCreationSlideScreenState();
}

class _CapsuleCreationSlideScreenState extends State<CapsuleCreationSlideScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isSubmitting = false;

  String _selectedType = 'memory';
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _recipientEmailController = TextEditingController();
  final TextEditingController _predictionTextController = TextEditingController();
  final TextEditingController _goalDescriptionController = TextEditingController();

  List<dynamic> _chapters = [];
  int? _selectedChapterId;
  List<PlatformFile> _pickedFiles = [];

  DateTime? _selectedUnlockDate;
  int _selectedPresetIndex = -1;

  late AnimationController _auraController;
  late Animation<double> _sparkleScaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      _currentPage = 1;
    }
    _pageController = PageController(initialPage: _currentPage);

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _sparkleScaleAnimation = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 15.0, end: 32.0).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    try {
      final response = await ApiClient.get(ApiConfig.chapters);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chapters = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _createNewChapterDialog() async {
    final TextEditingController newChapterController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.twilightPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Create New Chapter",
          style: GoogleFonts.cormorantGaramond(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: TextField(
          controller: newChapterController,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "e.g., University Years, 2026 Goals",
            hintStyle: TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.glassFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.glassBorder)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softLavender,
              foregroundColor: AppColors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final title = newChapterController.text.trim();
              if (title.isNotEmpty) {
                try {
                  final response = await ApiClient.post(ApiConfig.chapters, {"title": title});
                  if (response.statusCode == 201 || response.statusCode == 200) {
                    final newChapter = jsonDecode(response.body);
                    await _fetchChapters();
                    setState(() {
                      _selectedChapterId = newChapter['id'];
                    });
                    if (mounted) Navigator.pop(context);
                  }
                } catch (_) {}
              }
            },
            child: Text("Create", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _auraController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    _predictionTextController.dispose();
    _goalDescriptionController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1 && !_formKey.currentState!.validate()) return;
    if (_currentPage == 2 && _selectedUnlockDate == null) return;
    if (_currentPage < 3) {
      _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      widget.onClose();
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
      if (result != null) {
        setState(() => _pickedFiles.addAll(result.files));
      }
    } catch (_) {}
  }

  Future<void> _submitCapsule() async {
    setState(() => _isSubmitting = true);
    try {
      final Map<String, dynamic> body = {
        "title": _titleController.text.trim(),
        "capsule_type": _selectedType,
        "unlock_date": _selectedUnlockDate!.toIso8601String(),
        if (_selectedType != 'letter' && _selectedChapterId != null) "chapter": _selectedChapterId,
      };

      if (_selectedType == 'memory') {
        body["message"] = _messageController.text.trim();
      } else if (_selectedType == 'prediction') {
        body["prediction_text"] = _predictionTextController.text.trim();
      } else if (_selectedType == 'accountability') {
        body["goal_description"] = _goalDescriptionController.text.trim();
      } else if (_selectedType == 'letter') {
        body["message"] = _messageController.text.trim();
        body["recipient_name"] = _recipientNameController.text.trim();
        body["recipient_email"] = _recipientEmailController.text.trim();
      }

      final response = await ApiClient.post(ApiConfig.capsules, body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final capsuleId = responseData['id'];
        final token = await TokenStorage.getAccessToken();

        for (var file in _pickedFiles) {
          if (file.path == null && file.bytes == null) continue;
          String attachmentType = 'image';
          final fileName = file.name.toLowerCase();
          if (fileName.endsWith('.mp4') || fileName.endsWith('.mov')) attachmentType = 'video';
          if (fileName.endsWith('.mp3') || fileName.endsWith('.wav')) attachmentType = 'audio';

          var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.attachments));
          if (token != null && token.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $token';
          }
          request.fields['capsule'] = capsuleId.toString();
          request.fields['attachment_type'] = attachmentType;

          if (kIsWeb && file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
          } else if (file.path != null) {
            request.files.add(await http.MultipartFile.fromPath('file', file.path!));
          }

          await request.send();
        }

        if (mounted) {
          widget.onClose();
        }
      } else {
        setState(() => _isSubmitting = false);
      }
    } catch (_) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
                  ),
                ),

                Text(
                  _getHeaderTitle(),
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),

                GestureDetector(
                  onTap: widget.onClose,
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Step Progress Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              bool isActive = index == _currentPage;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                height: 4,
                width: isActive ? 24 : 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),

          SizedBox(height: 12),

          // Page View Body
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                _buildTypeSelectionPage(),
                _buildComposePage(),
                _buildSchedulePage(),
                _buildSealPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentPage) {
      case 0: return "Choose type";
      case 1: return "Compose";
      case 2: return "Schedule";
      case 3: return "Seal it";
      default: return "Create";
    }
  }

  Widget _buildGlassButton({required VoidCallback onPressed, required Widget child, bool isPrimary = true}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.softLavender : AppColors.glassFill,
          foregroundColor: isPrimary ? AppColors.deepPurple : AppColors.textPrimary,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: isPrimary ? Colors.transparent : AppColors.glassBorder),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
        child: child,
      ),
    );
  }

  // --- PAGE 1: CHOOSE TYPE (Centered icons & selection circles) ---
  Widget _buildTypeSelectionPage() {
    final types = [
      {'key': 'memory', 'title': 'Memory Capsule', 'subtitle': 'Preserve a moment.', 'desc': 'Capture a trip, achievement, or important day to rediscover later.', 'icon': Icons.auto_awesome_rounded, 'color': AppColors.lavender},
      {'key': 'prediction', 'title': 'Prediction Capsule', 'subtitle': 'Record an expectation.', 'desc': "Predict where you'll be — then revisit to see how right you were.", 'icon': Icons.nightlight_round_outlined, 'color': AppColors.twilightPurple},
      {'key': 'accountability', 'title': 'Accountability Capsule', 'subtitle': 'Make a commitment.', 'desc': 'Promise yourself a goal, then reflect on whether you kept it.', 'icon': Icons.track_changes_rounded, 'color': AppColors.rosePink},
      {'key': 'letter', 'title': 'Letter Capsule', 'subtitle': 'Send a message.', 'desc': 'Write a heartfelt letter directly to someone special.', 'icon': Icons.favorite_border_rounded, 'color': AppColors.mauve},
    ];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        ...types.map((t) {
          bool isSelected = _selectedType == t['key'];
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedType = t['key'] as String);
              },
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.glassStrong : AppColors.glassFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : AppColors.glassBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centered vertically
                  children: [
                    // Centered icon container
                    Center(
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: (t['color'] as Color).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(t['icon'] as IconData, color: AppColors.textPrimary, size: 22),
                      ),
                    ),

                    SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t['title'] as String,
                            style: GoogleFonts.cormorantGaramond(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),

                          SizedBox(height: 2),

                          Text(
                            t['subtitle'] as String,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),

                          SizedBox(height: 4),

                          Text(
                            t['desc'] as String,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 12),

                    Center(
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.textMuted, width: 2),
                          color: isSelected ? AppColors.textPrimary : Colors.transparent,
                        ),
                        child: isSelected
                            ? Center(child: Icon(Icons.check, size: 13, color: Colors.black))
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        SizedBox(height: 12),

        _buildGlassButton(
          onPressed: _nextPage,
          child: Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),

        SizedBox(height: 80),
      ],
    );
  }

  // --- PAGE 2: COMPOSE ---
  Widget _buildComposePage() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          Text("TITLE", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

          SizedBox(height: 8),

          TextFormField(
            controller: _titleController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: "e.g., Reflections of Spring",
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.glassFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
          ),

          SizedBox(height: 20),

          if (_selectedType == 'memory') ...[
            Text("MESSAGE TO YOUR FUTURE SELF", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

            SizedBox(height: 8),

            TextFormField(
              controller: _messageController,
              maxLines: 5,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "Write your thoughts...",
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Message is required" : null,
            ),
          ] else if (_selectedType == 'prediction') ...[

            Text("YOUR PREDICTION", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

            SizedBox(height: 8),

            TextFormField(
              controller: _predictionTextController,
              maxLines: 5,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "What do you predict will happen?",
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Prediction text is required" : null,
            ),
          ] else if (_selectedType == 'accountability') ...[

            Text("GOAL DESCRIPTION", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

            SizedBox(height: 8),

            TextFormField(
              controller: _goalDescriptionController,
              maxLines: 5,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "What goal are you committing to?",
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Goal description is required" : null,
            ),
          ] else if (_selectedType == 'letter') ...[

            Text("RECIPIENT NAME", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

            SizedBox(height: 8),

            TextFormField(
              controller: _recipientNameController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "e.g., Jane Doe",
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Recipient name is required" : null,
            ),

            SizedBox(height: 16),

            Text("RECIPIENT EMAIL", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

            SizedBox(height: 8),

            TextFormField(
              controller: _recipientEmailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "e.g., friend@example.com",
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
              ),
              validator: (val) => val == null || !val.contains('@') ? "Valid email is required" : null,
            ),

            SizedBox(height: 16),

            Text("MESSAGE", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

            SizedBox(height: 8),

            TextFormField(
              controller: _messageController,
              maxLines: 4,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "Write your letter...",
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Message is required" : null,
            ),
          ],

          if (_selectedType != 'letter') ...[

            SizedBox(height: 20),

            Text("CHAPTER (OPTIONAL)", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedChapterId,
                        dropdownColor: AppColors.twilightPurple,
                        hint: Text("Select a chapter", style: TextStyle(color: AppColors.textMuted)),
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        items: [
                          DropdownMenuItem<int?>(value: null, child: Text("No Chapter", style: TextStyle(color: AppColors.textPrimary))),
                          ..._chapters.map((ch) => DropdownMenuItem<int?>(
                            value: ch['id'] as int,
                            child: Text(ch['title'] ?? 'Chapter', style: TextStyle(color: AppColors.textPrimary)),
                          )),
                        ],
                        onChanged: (val) => setState(() => _selectedChapterId = val),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                GestureDetector(
                  onTap: _createNewChapterDialog,
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(Icons.add, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 20),

          Text("ATTACHMENTS (OPTIONAL)", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

          SizedBox(height: 8),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attachment_rounded, color: AppColors.textSecondary, size: 18),

                        SizedBox(width: 8),

                        Text("Files attached (${_pickedFiles.length})", style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      ],
                    ),

                    TextButton.icon(
                      onPressed: _pickFiles,
                      icon: Icon(Icons.add, size: 16, color: AppColors.softLavender),
                      label: Text("Add files", style: TextStyle(color: AppColors.softLavender)),
                    ),
                  ],
                ),
                if (_pickedFiles.isNotEmpty) ...[

                  SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pickedFiles.map((f) => Chip(
                      backgroundColor: AppColors.glassStrong,
                      label: Text(f.name, style: TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                      deleteIconColor: AppColors.textSecondary,
                      onDeleted: () => setState(() => _pickedFiles.remove(f)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 30),
          _buildGlassButton(
            onPressed: _nextPage,
            child: Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- PAGE 3: SCHEDULE ---
  Widget _buildSchedulePage() {
    final now = DateTime.now();

    void selectPreset(int idx, Duration dur) {
      setState(() {
        _selectedPresetIndex = idx;
        _selectedUnlockDate = now.add(dur);
      });
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Text(
          "When should this open?",
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 4),

        Text(
          "Your capsule stays sealed until this date.",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),

        SizedBox(height: 24),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildScheduleCard(0, "1 month", DateFormat('d. MMM yyyy').format(now.add(const Duration(days: 30))), Icons.timer_outlined, () => selectPreset(0, const Duration(days: 30))),
            _buildScheduleCard(1, "3 months", DateFormat('d. MMM yyyy').format(now.add(const Duration(days: 90))), Icons.hourglass_top_rounded, () => selectPreset(1, const Duration(days: 90))),
            _buildScheduleCard(2, "1 year", DateFormat('d. MMM yyyy').format(now.add(const Duration(days: 365))), Icons.event_repeat_rounded, () => selectPreset(2, const Duration(days: 365))),
            _buildScheduleCard(3, "3 years", DateFormat('d. MMM yyyy').format(now.add(const Duration(days: 1095))), Icons.all_inclusive_rounded, () => selectPreset(3, const Duration(days: 1095))),
          ],
        ),

        SizedBox(height: 12),

        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: now.add(Duration(days: 1)),
              firstDate: now,
              lastDate: now.add(Duration(days: 365 * 50)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppColors.softLavender,
                      onPrimary: AppColors.deepPurple,
                      surface: AppColors.twilightPurple,
                      onSurface: AppColors.textPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.softLavender,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedPresetIndex = 4;
                _selectedUnlockDate = picked;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _selectedPresetIndex == 4 ? AppColors.glassStrong : AppColors.glassFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedPresetIndex == 4 ? AppColors.textPrimary : AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColors.textPrimary),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Custom date", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),

                      SizedBox(height: 2),

                      Text(
                        _selectedPresetIndex == 4 && _selectedUnlockDate != null
                            ? DateFormat('d. MMM yyyy').format(_selectedUnlockDate!)
                            : "Pick a custom calendar unlock date",
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),

        SizedBox(height: 30),
        _buildGlassButton(
          onPressed: _nextPage,
          child: Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),

        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildScheduleCard(int idx, String title, String subDate, IconData icon, VoidCallback onTap) {
    bool isSel = _selectedPresetIndex == idx;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? AppColors.glassStrong : AppColors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? AppColors.textPrimary : AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),

            SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
            ),

            SizedBox(height: 2),

            Text(
              subDate,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // --- PAGE 4: SEAL IT ---
  Widget _buildSealPage() {
    String formattedUnlock = _selectedUnlockDate != null
        ? DateFormat('d. MMMM yyyy').format(_selectedUnlockDate!)
        : 'Unknown date';

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _auraController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(0.0, 0.0),
                    radius: 0.85,
                    colors: [
                      AppColors.softLavender,
                      AppColors.mediumLavender,
                      AppColors.deepPurple,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amethystGlow.withValues(alpha: 0.35),
                      blurRadius: _glowAnimation.value * 0.75,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _sparkleScaleAnimation.value,
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.textPrimary,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        SizedBox(height: 16),

        Center(
          child: Text(
            "Ready to seal",
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 4),

        Center(
          child: Text(
            "This capsule will open on $formattedUnlock.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),

        SizedBox(height: 20),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow("TYPE", "${_selectedType[0].toUpperCase()}${_selectedType.substring(1)} Capsule"),

              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.glassBorder, height: 1)),

              _buildSummaryRow("TITLE", _titleController.text.isNotEmpty ? _titleController.text : "Untitled"),

              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.glassBorder, height: 1)),

              _buildSummaryRow(
                "MESSAGE",
                _selectedType == 'prediction'
                    ? _predictionTextController.text
                    : (_selectedType == 'accountability' ? _goalDescriptionController.text : _messageController.text),
              ),

              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.glassBorder, height: 1)),

              _buildSummaryRow("OPENS", formattedUnlock),
            ],
          ),
        ),

        SizedBox(height: 24),

        _buildGlassButton(
          onPressed: _isSubmitting ? () {} : _submitCapsule,
          child: _isSubmitting
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.deepPurple, strokeWidth: 2))
              : Text("Seal capsule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),

        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),

        SizedBox(height: 4),

        Text(
          value.isNotEmpty ? value : "-",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}