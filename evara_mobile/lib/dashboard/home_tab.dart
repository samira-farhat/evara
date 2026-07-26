import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sparkleScaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isLoading = true;
  String? _errorMessage;

  String _greeting = "";
  String _username = "";

  int _pastCapsulesCount = 0;
  int _futureCapsulesCount = 0;
  int _yearsSpan = 1;

  List<dynamic> _upcomingCapsules = [];
  List<dynamic> _activeChapters = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _sparkleScaleAnimation = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 6.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(ApiConfig.home);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _greeting = data['greeting'] ?? "Hello";
          _username = data['username'] ?? "";

          final timeline = data['timeline_summary'] ?? {};
          _pastCapsulesCount = timeline['past_capsules_count'] ?? 0;
          _futureCapsulesCount = timeline['future_capsules_count'] ?? 0;
          _yearsSpan = timeline['years_span'] ?? 1;
          if (_yearsSpan < 1) _yearsSpan = 1;

          _upcomingCapsules = data['upcoming_capsules'] ?? [];
          _activeChapters = data['active_chapters'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load dashboard data.";
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: AppColors.twilightPurple,
          ),
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

                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),

                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _fetchHomeData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.twilightPurple,
                  ),
                  child: Text("Retry", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchHomeData,
          color: AppColors.twilightPurple,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Message & Date
                _buildHeaderSection(),
                SizedBox(height: 32),

                // 2. Timeline Box
                _buildTimelineWidget(),
                SizedBox(height: 40),

                // 3. Quick Create Section
                _buildQuickCreateSection(),
                SizedBox(height: 40),

                // 4. Upcoming Capsules Section
                _buildUpcomingCapsulesSection(),
                SizedBox(height: 40),

                // 5. Active Chapters Section
                _buildActiveChaptersSection(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeaderSection() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE, MMMM d').format(now);
    String formattedUsername = _username.isNotEmpty
        ? '${_username[0].toUpperCase()}${_username.substring(1)}'
        : 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$_greeting, $formattedUsername",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 4),

        Text(
          formattedDate,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }


  Widget _buildTimelineWidget() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleGlow.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your timeline",
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Icon(Icons.all_inclusive_rounded, color: AppColors.amethystGlow, size: 20),
            ],
          ),

          SizedBox(height: 8),

          Text(
            "Past · Present · Future",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 20),

          SizedBox(
            height: 90,
            child: Stack(
              children: [
                // Curved Line Painter
                Positioned(
                  top: 15,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(double.infinity, 40),
                    painter: TimelineCurvePainter(),
                  ),
                ),
                // Past Marker (Left)
                Positioned(
                  left: 8,
                  bottom: 0,
                  child: _buildTimelineMarker("Past", "$_pastCapsulesCount", isSelected: true, icon: Icons.history_rounded),
                ),
                // Future Marker (Right)
                Positioned(
                  right: 8,
                  bottom: 0,
                  child: _buildTimelineMarker("Future", "$_futureCapsulesCount", isSelected: false, icon: Icons.update_rounded),
                ),
                // Center "Now" Aura Circle Marker on top of the curve peak
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Container(
                              width: 36,
                              height: 36,
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
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.amethystGlow.withValues(alpha: 0.4),
                                    blurRadius: _glowAnimation.value,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Transform.scale(
                                  scale: _sparkleScaleAnimation.value,
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 2),

                        Text(
                          "now",
                          style: TextStyle(
                            color: AppColors.twilightPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Row(
            children: [
              Icon(Icons.event_available_rounded, color: Colors.black.withValues(alpha: 0.3), size: 16),

              SizedBox(width: 8),

              Text(
                "Your story spans $_yearsSpan ${_yearsSpan == 1 ? 'year' : 'years'}.",
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
    );
  }

  Widget _buildTimelineMarker(String label, String value, {required bool isSelected, required IconData icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? AppColors.twilightPurple : Colors.black.withValues(alpha: 0.3),
          size: 16,
        ),

        SizedBox(height: 2),

        Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.twilightPurple : Colors.black.withValues(alpha: 0.3),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        Text(
          value,
          style: TextStyle(
            color: isSelected ? AppColors.twilightPurple : Colors.black.withValues(alpha: 0.3),
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }


  Widget _buildQuickCreateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick create",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Adjusted aspect ratio so smaller phone screens (like iPhone SE/12 Pro) don't overflow
          childAspectRatio: 2.1,
          children: [
            _buildQuickCreateCard(
              title: "Capsule",
              subtitle: "Preserve a moment",
              icon: Icons.widgets_outlined,
              color: AppColors.lavender,
              onTap: () {
                // TODO: Navigate to Capsule Create screen
              },
            ),
            _buildQuickCreateCard(
              title: "Prediction",
              subtitle: "Guess the future",
              icon: Icons.nightlight_round_outlined,
              color: AppColors.twilightPurple,
              onTap: () {
                // TODO: Navigate to Prediction Create screen
              },
            ),
            _buildQuickCreateCard(
              title: "Accountability",
              subtitle: "Commit to a goal",
              icon: Icons.track_changes_rounded,
              color: AppColors.rosePink,
              onTap: () {
                // TODO: Navigate to Accountability Create screen
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCreateCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),

            SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 1),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUpcomingCapsulesSection() {
    bool hasCapsules = _upcomingCapsules.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming capsules",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasCapsules)
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to See All Capsules screen
                },
                child: Text(
                  "See all",
                  style: TextStyle(
                    color: AppColors.twilightPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 16),

        hasCapsules ? _buildPopulatedCapsulesList() : _buildEmptyCapsulesState(),
      ],
    );
  }

  Widget _buildEmptyCapsulesState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.nights_stay_rounded, color: AppColors.twilightPurple.withValues(alpha: 0.4), size: 45),

          SizedBox(height: 16),

          Text(
            "No capsules waiting yet",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Create your first time capsule — a message to your future self.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopulatedCapsulesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _upcomingCapsules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final capsule = _upcomingCapsules[index];
        final title = capsule['title'] ?? 'Untitled';

        final rawType = capsule['capsule_type'] ?? 'memory';
        final formattedType = '${rawType[0].toUpperCase()}${rawType.substring(1)} Capsule';

        final daysRemaining = capsule['days_remaining'] ?? 0;
        final timeAgoText = '${daysRemaining} days';

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
          onTap: () {
            // TODO: Navigate to Capsule Details screen
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.black.withValues(alpha: 0.3), size: 14),

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
      },
    );
  }

  Widget _buildActiveChaptersSection() {
    bool hasChapters = _activeChapters.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active chapters",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasChapters)
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to See All Chapters screen
                },
                child: Text(
                  "See all",
                  style: TextStyle(
                    color: AppColors.twilightPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 16),

        hasChapters ? _buildPopulatedChaptersList() : _buildEmptyChaptersState(),
      ],
    );
  }

  Widget _buildEmptyChaptersState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined, color: AppColors.twilightPurple.withValues(alpha: 0.4), size: 48),

          SizedBox(height: 16),

          Text(
            "No active chapters yet",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Organize your memories and capsules into structured chapters.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopulatedChaptersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _activeChapters.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final chapter = _activeChapters[index];
        final title = chapter['title'] ?? 'Untitled';
        final capsuleCount = chapter['capsule_count'] ?? 0;
        final imageUrl = chapter['cover_image'];

        return GestureDetector(
          onTap: () {
            // TODO: Navigate to Chapter Details screen
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl != null && imageUrl.toString().isNotEmpty
                      ? Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      width: double.infinity,
                      color: AppColors.lavender.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.black38, size: 32),
                      ),
                    ),
                  )
                      : Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.lavender.withValues(alpha: 0.4),
                          AppColors.twilightPurple.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.auto_stories_rounded, color: AppColors.twilightPurple.withValues(alpha: 0.5), size: 40),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        "$capsuleCount ${capsuleCount == 1 ? 'capsule' : 'capsules'}",
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
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
}


class TimelineCurvePainter extends CustomPainter {
  @override
  void paint(Canvas sizeCanvas, Size size) {
    final paint = Paint()
      ..color = AppColors.twilightPurple.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.3,
      size.width,
      size.height * 0.7,
    );

    sizeCanvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}