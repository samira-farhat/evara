import 'package:evara_mobile/dashboard/profile_tab.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'chapters_tab.dart';
import 'create_tab.dart';
import 'home_tab.dart';
import 'library_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  String _libraryInitialFilter = 'all';

  late final List<Widget> _screens = [
    HomeTab(
      onViewReadyCapsules: () => _navigateToLibraryWithFilter('unlocked'),
    ),
    LibraryTab(key: ValueKey(_libraryInitialFilter), initialFilter: _libraryInitialFilter),
    const ChaptersTab(),
    const ProfileTab(),
  ];

  void _navigateToLibraryWithFilter(String filter) {
    setState(() {
      _libraryInitialFilter = filter;
      _screens[1] = LibraryTab(key: ValueKey(_libraryInitialFilter), initialFilter: _libraryInitialFilter);
      _currentIndex = 2;
    });
    _pageController.jumpToPage(1);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      _openCreateBottomSheet();
      return;
    }

    if (index == 2) {
      _navigateToLibraryWithFilter('all');
      return;
    }

    int screenIndex = index > 1 ? index - 1 : index;

    setState(() {
      _currentIndex = index;
    });

    _pageController.jumpToPage(screenIndex);
  }

  void _openCreateBottomSheet() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        barrierDismissible: true,
        transitionDuration: Duration(milliseconds: 350),
        reverseTransitionDuration: Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return CapsuleCreationSlideScreen(
            onClose: () {
              Navigator.of(context).pop();
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: slideAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              int navIndex = index >= 1 ? index + 1 : index;
              setState(() {
                _currentIndex = navIndex;
              });
            },
            children: _screens,
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.twilightPurple.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.auto_awesome_rounded, "Home"),
                  _buildNavItem(1, Icons.add_circle_outline_rounded, "Create"),
                  _buildNavItem(2, Icons.menu_book_rounded, "Library"),
                  _buildNavItem(3, Icons.auto_stories_rounded, "Chapters"),
                  _buildNavItem(4, Icons.person_outline_rounded, "Profile"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.twilightPurple.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.twilightPurple : Colors.black87,
              size: 20,
            ),

            SizedBox(height: 2),

            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.twilightPurple : Colors.black87,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}