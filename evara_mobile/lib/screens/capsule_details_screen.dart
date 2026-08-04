import 'dart:async';
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
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchCapsuleDetails();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _capsule != null && !(_isUnlocked())) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
        insetPadding: EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
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

    List<Map<String, dynamic>> timeUnits = [];

    if (unlockDate != null) {
      final now = DateTime.now();
      if (unlockDate.isAfter(now)) {
        int years = unlockDate.year - now.year;
        int months = unlockDate.month - now.month;
        int days = unlockDate.day - now.day;
        int hours = unlockDate.hour - now.hour;
        int minutes = unlockDate.minute - now.minute;
        int seconds = unlockDate.second - now.second;

        if (seconds < 0) {
          seconds += 60;
          minutes--;
        }
        if (minutes < 0) {
          minutes += 60;
          hours--;
        }
        if (hours < 0) {
          hours += 24;
          days--;
        }
        if (days < 0) {
          final prevMonth = DateTime(unlockDate.year, unlockDate.month - 1, now.day);
          final daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
          days += daysInPrevMonth;
          months--;
        }
        if (months < 0) {
          months += 12;
          years--;
        }

        if (years > 0) {
          timeUnits.add({'value': years, 'label': years == 1 ? 'Year' : 'Years'});
        }
        if (years > 0 || months > 0) {
          timeUnits.add({'value': months, 'label': months == 1 ? 'Month' : 'Months'});
        }
        if (years > 0 || months > 0 || days > 0) {
          timeUnits.add({'value': days, 'label': days == 1 ? 'Day' : 'Days'});
        }
        timeUnits.add({'value': hours, 'label': 'Hours'});
        timeUnits.add({'value': minutes, 'label': 'Minutes'});
        timeUnits.add({'value': seconds, 'label': 'Seconds'});
      }
    }

    if (timeUnits.isEmpty) {
      timeUnits = [
        {'value': 0, 'label': 'Hours'},
        {'value': 0, 'label': 'Minutes'},
        {'value': 0, 'label': 'Seconds'},
      ];
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.twilightPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.lock_rounded, color: AppColors.twilightPurple, size: 30),
          ),

          SizedBox(height: 12),

          Text(
            formattedType,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
          ),

          SizedBox(height: 4),

          Text(
            "Created $createdDateFormatted",
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4)),
          ),

          SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleGlow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.twilightPurple, size: 24),

                SizedBox(height: 8),

                Text("Sealed until", style: TextStyle(fontSize: 12, color: Colors.black54)),

                SizedBox(height: 4),

                Text(
                    formattedUnlockDate,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black45)
                ),

                SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(timeUnits.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.translate(
                          offset: Offset(0, -5),
                          child: Text(
                            ":",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withValues(alpha: 0.4),
                              height: 1.0,
                            ),
                          ),
                        ),
                      );
                    }
                    final unitIndex = index ~/ 2;
                    final unit = timeUnits[unitIndex];
                    final valStr = unit['value'].toString().padLeft(2, '0');
                    final labelStr = unit['label'];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          valStr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          labelStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "Preview",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black45)
                ),

                SizedBox(height: 8),

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

          SizedBox(height: 16),

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
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.twilightPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.lock_open_rounded, color: AppColors.twilightPurple, size: 30),
                ),

                SizedBox(height: 12),

                Text(
                  formattedType,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                ),

                SizedBox(height: 4),

                Text(
                  "Delivered to you safely from your past self ($createdDateFormatted)",
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          if (rawType == 'letter') ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Letter Recipient", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),

                  SizedBox(height: 4),

                  Text("To: ${_capsule?['recipient_name'] ?? 'Recipient'} (${_capsule?['recipient_email'] ?? ''})",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Main Message Card
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                ),

                SizedBox(height: 24),

                Align(
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
            SizedBox(height: 20),

            Text(
              "Attachments",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),

            SizedBox(height: 10),

            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (context, index) => SizedBox(width: 12),
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
                            offset: Offset(0, 4),
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

          SizedBox(height: 32),

          // Reflections Section
          if (rawType != 'letter') ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Reflect on that",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 6),

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

                  // Only show this button if reflection was NOT sent forward
                  if (!reflectionSentForward) ...[
                    SizedBox(height: 16),

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
                        padding: EdgeInsets.symmetric(
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
                        style: TextStyle(
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
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(_errorMessage ?? "Error loading capsule", textAlign: TextAlign.center),
      ),
    );
  }
}