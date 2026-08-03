import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';
import 'create_reflection_screen.dart';
import 'reflection_details_screen.dart';

class CapsuleDetailsScreen extends StatefulWidget {
  final int capsuleId;

  const CapsuleDetailsScreen({Key? key, required this.capsuleId}) : super(key: key);

  @override
  State<CapsuleDetailsScreen> createState() => _CapsuleDetailsScreenState();
}

class _CapsuleDetailsScreenState extends State<CapsuleDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _capsule;
  Map<String, dynamic>? _reflection;

  @override
  void initState() {
    super.initState();
    _fetchCapsuleDetails();
  }

  Future<void> _fetchCapsuleDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(ApiConfig.capsuleDetails(widget.capsuleId));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _capsule = data;
        });
        if (_isUnlocked()) {
          await _fetchReflection();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 403) {
        try {
          final data = jsonDecode(response.body);
          setState(() {
            _capsule = data;
            _isLoading = false;
          });
        } catch (_) {
          setState(() {
            _errorMessage = "This capsule is locked.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to load capsule details.";
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

  Future<void> _fetchReflection() async {
    try {
      final response = await ApiClient.get(ApiConfig.capsuleReflection(widget.capsuleId));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is Map) {
            if (data.containsKey('reflection') && data['reflection'] != null) {
              _reflection = data['reflection'];
            } else if (data.containsKey('id')) {
              _reflection = data as Map<String, dynamic>;
            } else {
              _reflection = null;
            }
          } else {
            _reflection = null;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _reflection = null;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _reflection = null;
        _isLoading = false;
      });
    }
  }

  bool _isUnlocked() {
    if (_capsule == null) return false;
    final unlockDateStr = _capsule!['unlock_date'];
    if (unlockDateStr == null) return false;
    final unlockDate = DateTime.parse(unlockDateStr);
    return unlockDate.isBefore(DateTime.now()) || unlockDate.isAtSameMomentAs(DateTime.now());
  }

  void _showMediaPreview(String url, String type) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text("Failed to load media", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.twilightPurple))
                  : _errorMessage != null && _capsule == null
                  ? _buildErrorState()
                  : _isUnlocked()
                  ? _buildUnlockedContent()
                  : _buildLockedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final title = _capsule?['title'] ?? 'Capsule details';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedContent() {
    final rawType = _capsule?['capsule_type'] ?? 'memory';
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

    final createdAtStr = _capsule?['created_at'];
    final createdDateFormatted = createdAtStr != null ? DateFormat('d MMMM yyyy').format(DateTime.parse(createdAtStr)) : '';

    final unlockDateStr = _capsule?['unlock_date'];
    DateTime? unlockDate = unlockDateStr != null ? DateTime.parse(unlockDateStr) : null;
    String formattedUnlockDate = unlockDate != null ? DateFormat('d MMMM yyyy').format(unlockDate) : '';

    String remainingText = "Soon";
    double progressValue = 0.0;

    if (unlockDate != null && createdAtStr != null) {
      final createdDate = DateTime.parse(createdAtStr);
      final now = DateTime.now();

      final totalDuration = unlockDate.difference(createdDate).inSeconds;
      final elapsedDuration = now.difference(createdDate).inSeconds;

      if (totalDuration > 0) {
        progressValue = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
      }

      final diff = unlockDate.difference(now);
      if (diff.isNegative) {
        remainingText = "0h";
      } else if (diff.inDays > 0) {
        remainingText = "${diff.inDays} days";
      } else if (diff.inHours > 0) {
        remainingText = "${diff.inHours}h";
      } else {
        remainingText = "${diff.inMinutes}m";
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.twilightPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.lock_rounded, color: AppColors.twilightPurple, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            formattedType,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            "Created $createdDateFormatted",
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleGlow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.twilightPurple, size: 24),
                const SizedBox(height: 8),
                const Text("Sealed until", style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                    formattedUnlockDate,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                      "Opens in $remainingText",
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4))
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: AppColors.lavender.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.twilightPurple),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    "Preview",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black45)
                ),
                const SizedBox(height: 8),
                Text(
                  "Hidden until unlocked",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Your future self will discover this on the date above.",
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedContent() {
    final rawType = _capsule?['capsule_type'] ?? 'memory';
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

    final message = _capsule?['display_message'] ?? '';

    final createdAtStr = _capsule?['created_at'];
    final createdDateFormatted = createdAtStr != null ? DateFormat('d MMMM yyyy').format(DateTime.parse(createdAtStr)) : '';
    final attachments = _capsule?['attachments'] as List<dynamic>? ?? [];
    final reflectionSentForward = _capsule?['reflection_sent_forward'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.twilightPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.lock_open_rounded, color: AppColors.twilightPurple, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  formattedType,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  "Delivered to you safely from your past self ($createdDateFormatted)",
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (rawType == 'letter') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Letter Recipient", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
                  const SizedBox(height: 4),
                  Text("To: ${_capsule?['recipient_name'] ?? 'Recipient'} (${_capsule?['recipient_email'] ?? ''})",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Main Message Card
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "with love, you",
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // Attachments Section with Click-to-Preview
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              "Attachments",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  final fileUrl = ApiConfig.buildMediaUrl(attachment['file'] ?? '');
                  final fileType = attachment['file_type'] ?? 'image';

                  return GestureDetector(
                    onTap: () => _showMediaPreview(fileUrl, fileType),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.insert_drive_file_rounded, color: AppColors.twilightPurple),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Reflections Section
          // Reflections Section
          if (rawType != 'letter') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Reflect on that",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    reflectionSentForward
                        ? "You wrote a reflection on this moment and sent it to your future self as a new capsule."
                        : _reflection != null
                        ? "You wrote a reflection on this capsule on ${DateFormat('d MMM yyyy').format(DateTime.parse(_reflection!['created_at']))}."
                        : "Reply to your past self and capture your thoughts on this moment.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),

                  // Only show button if reflection was NOT sent forward
                  if (!reflectionSentForward) ...[
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () async {
                        if (_reflection != null && _reflection!['id'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReflectionDetailsScreen(
                                reflectionId: _reflection!['id'],
                              ),
                            ),
                          );
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateReflectionScreen(
                                capsuleId: widget.capsuleId,
                                capsuleTitle: _capsule?['title'] ?? '',
                                capsuleType: rawType,
                              ),
                            ),
                          );

                          if (result == true) {
                            _fetchCapsuleDetails();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.twilightPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _reflection != null
                            ? "View Reflection"
                            : "Write Reflection",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_errorMessage ?? "Error loading capsule", textAlign: TextAlign.center),
      ),
    );
  }
}