import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_config.dart';
import '../../../../core/api_client.dart';

class LibraryTab extends StatefulWidget {
  final String initialFilter; // 'all', 'locked', 'unlocked'

  const LibraryTab({Key? key, this.initialFilter = 'all'}) : super(key: key);

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allCapsules = [];
  List<dynamic> _filteredCapsules = [];

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  late String _selectedTab;

  // Advanced Filter & Sort Modal State
  String _selectedTypeFilter = 'all'; // 'all', 'memory', 'prediction', 'accountability', 'letter'
  String _selectedSortBy = 'newest'; // 'newest', 'oldest', 'soonest', 'latest'

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialFilter;
    _searchController.addListener(_filterCapsules);
    _fetchLibraryData();
  }

  @override
  void didUpdateWidget(covariant LibraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _selectedTab = widget.initialFilter;
        _filterCapsules();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLibraryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(ApiConfig.capsuleLibrary);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allCapsules = data['capsules'] ?? [];
          _isLoading = false;
        });
        _filterCapsules();
      } else {
        setState(() {
          _errorMessage = "Failed to load library capsules.";
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

  void _filterCapsules() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredCapsules = _allCapsules.where((capsule) {
        final title = (capsule['title'] ?? '').toLowerCase();
        final chapterTitle = (capsule['chapter_title'] ?? '').toLowerCase();
        final status = (capsule['status'] ?? 'locked').toLowerCase();
        final type = (capsule['capsule_type'] ?? 'memory').toLowerCase();

        // 1. Tab Status Filter (All, Locked, Unlocked)
        bool matchesTab = true;
        if (_selectedTab == 'locked') {
          matchesTab = status == 'locked';
        } else if (_selectedTab == 'unlocked') {
          matchesTab = status == 'unlocked' || status == 'ready';
        }

        // 2. Search Query (Title or Chapter name)
        bool matchesSearch = query.isEmpty ||
            title.contains(query) ||
            chapterTitle.contains(query);

        // 3. Advanced Modal Type Filter
        bool matchesType = true;
        if (_selectedTypeFilter != 'all') {
          matchesType = type == _selectedTypeFilter;
        }

        return matchesTab && matchesSearch && matchesType;
      }).toList();

      // 4. Sorting logic
      _filteredCapsules.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        DateTime dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        DateTime unlockA = DateTime.tryParse(a['unlock_date'] ?? '') ?? DateTime(2100);
        DateTime unlockB = DateTime.tryParse(b['unlock_date'] ?? '') ?? DateTime(2100);

        if (_selectedSortBy == 'newest') {
          return dateB.compareTo(dateA);
        } else if (_selectedSortBy == 'oldest') {
          return dateA.compareTo(dateB);
        } else if (_selectedSortBy == 'soonest') {
          return unlockA.compareTo(unlockB);
        } else if (_selectedSortBy == 'latest') {
          return unlockB.compareTo(unlockA);
        }
        return 0;
      });
    });
  }

  Color _getCapsuleColor(String type) {
    switch (type.toLowerCase()) {
      case "prediction":
        return AppColors.twilightPurple;
      case "accountability":
        return AppColors.rosePink;
      case "letter":
        return AppColors.mauve;
      case "memory":
      default:
        return AppColors.lavender;
    }
  }

  IconData _getCapsuleTypeIcon(String type) {
    switch (type.toLowerCase()) {
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
                    color: Colors.black.withValues(alpha: 0.15),
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
                          "Filter & Sort",
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
                      "TYPE",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
                    ),

                    SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip("All types", 'all', _selectedTypeFilter, (val) {
                          setModalState(() => _selectedTypeFilter = val);
                        }),
                        _buildFilterChip("Memory", 'memory', _selectedTypeFilter, (val) {
                          setModalState(() => _selectedTypeFilter = val);
                        }),
                        _buildFilterChip("Prediction", 'prediction', _selectedTypeFilter, (val) {
                          setModalState(() => _selectedTypeFilter = val);
                        }),
                        _buildFilterChip("Accountability", 'accountability', _selectedTypeFilter, (val) {
                          setModalState(() => _selectedTypeFilter = val);
                        }),
                        _buildFilterChip("Letter", 'letter', _selectedTypeFilter, (val) {
                          setModalState(() => _selectedTypeFilter = val);
                        }),
                      ],
                    ),

                    SizedBox(height: 24),

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
                        _buildFilterChip("Unlocking soonest", 'soonest', _selectedSortBy, (val) {
                          setModalState(() => _selectedSortBy = val);
                        }),
                        _buildFilterChip("Unlocking latest", 'latest', _selectedSortBy, (val) {
                          setModalState(() => _selectedSortBy = val);
                        }),
                      ],
                    ),

                    SizedBox(height: 32),

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
                                    _filterCapsules();
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
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
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

  @override
  Widget build(BuildContext context) {
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

                Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),

                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _fetchLibraryData,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.twilightPurple),
                  child: Text("Retry", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchLibraryData,
          color: AppColors.twilightPurple,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Filter Icon Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Library",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: _showFilterSortModal,
                      icon: Container(
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

                SizedBox(height: 16),

                // Search Bar
                Container(
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
                      hintText: "Search capsules...",
                      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.black.withValues(alpha: 0.4)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterCapsules();
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton("All", 'all'),

                      SizedBox(width: 8),

                      _buildTabButton("Locked", 'locked'),

                      SizedBox(width: 8),

                      _buildTabButton("Unlocked", 'unlocked'),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Capsules List or Empty State
                _filteredCapsules.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _filteredCapsules.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final capsule = _filteredCapsules[index];
                    return _buildCapsuleCard(capsule);
                  },
                ),
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    bool isSelected = _selectedTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabKey;
          _filterCapsules();
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.twilightPurple.withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.twilightPurple : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.twilightPurple.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.twilightPurple : Colors.black.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
            child: Icon(Icons.inventory_2_outlined, color: AppColors.deepPurple, size: 32),
          ),

          SizedBox(height: 16),

          Text(
            "Nothing here yet",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Capsules in this section will appear here.",
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

  Widget _buildCapsuleCard(dynamic capsule) {
    final title = capsule['title'] ?? 'Untitled';
    final rawType = capsule['capsule_type'] ?? 'memory';
    final status = (capsule['status'] ?? 'locked').toLowerCase();
    bool isUnlocked = status == 'unlocked' || status == 'ready';

    final cardColor = _getCapsuleColor(rawType);
    String formattedType = '${rawType[0].toUpperCase()}${rawType.substring(1)} Capsule';

    String dateText = '';
    String timeAgoText = '';
    try {
      if (capsule['unlock_date'] != null) {
        final parsedDate = DateTime.parse(capsule['unlock_date']);
        dateText = DateFormat('MMM yyyy').format(parsedDate);

        final difference = parsedDate.difference(DateTime.now()).inDays;
        if (difference > 0) {
          timeAgoText = '${difference}d';
        } else {
          timeAgoText = 'Ready';
        }
      }
    } catch (_) {
      dateText = '';
    }

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to Capsule Details screen when built
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
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardColor.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Icon(
                isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                color: cardColor,
                size: 22,
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

                  SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(_getCapsuleTypeIcon(rawType), color: cardColor, size: 13),

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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  dateText,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.4),
                    fontSize: 11,
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