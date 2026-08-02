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
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['detail'] ?? "This capsule is locked.";
          _isLoading = false;
        });
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
          _reflection = data['reflection'] != null ? data : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isUnlocked() {
    if (_capsule == null) return false;
    final unlockDate = DateTime.parse(_capsule!['unlock_date']);
    return unlockDate.isBefore(DateTime.now()) || unlockDate.isAtSameMomentAs(DateTime.now());
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
      child: Row(
        children: [
          GestureDetector(
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedContent() {
    final unlockDateStr = _capsule?['unlock_date'];
    DateTime? unlockDate = unlockDateStr != null ? DateTime.parse(unlockDateStr) : null;
    String formattedDate = unlockDate != null ? DateFormat('d MMMM yyyy').format(unlockDate) : '';

    String remainingText = "Soon";
    if (unlockDate != null) {
      final diff = unlockDate.difference(DateTime.now());
      if (diff.inHours < 24) {
        remainingText = "${diff.inHours}h";
      } else {
        remainingText = "${diff.inDays} days";
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.twilightPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.lock_rounded, color: AppColors.twilightPurple, size: 32),
          ),
          const SizedBox(height: 12),
          const Text("Memory Capsule", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            _capsule?['created_at'] != null
                ? "Created ${DateFormat('d MMMM yyyy').format(DateTime.parse(_capsule!['created_at']))}"
                : "",
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 32),
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
                Text(formattedDate, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(remainingText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.twilightPurple)),
                    Text("Opens in $remainingText", style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.7,
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
                const Text("Preview", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black45)),
                const SizedBox(height: 8),
                Text(
                  "Hidden until unlocked",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.3),
                    decoration: TextDecoration.lineThrough,
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
    final type = _capsule?['capsule_type'] ?? 'memory';
    final message = _capsule?['message'] ?? '';
    final createdAtStr = _capsule?['created_at'];
    final createdDateFormatted = createdAtStr != null ? DateFormat('d MMMM yyyy').format(DateTime.parse(createdAtStr)) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.twilightPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_open_rounded, color: AppColors.twilightPurple, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  "${type[0].toUpperCase()}${type.substring(1)} Capsule",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
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

          if (type == 'letter') ...[
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

          const SizedBox(height: 32),

          if (type != 'letter') ...[
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _reflection != null
                        ? "You wrote a reflection on this capsule on ${DateFormat('d MMM yyyy').format(DateTime.parse(_reflection!['created_at']))}."
                        : "Reply to your past self and capture your thoughts on this moment.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (_reflection != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReflectionDetailsScreen(reflectionId: _reflection!['id']),
                          ),
                        );
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateReflectionScreen(
                              capsuleId: widget.capsuleId,
                              capsuleTitle: _capsule?['title'] ?? '',
                              capsuleType: type,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      _reflection != null ? "View Reflection" : "Write Reflection",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
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