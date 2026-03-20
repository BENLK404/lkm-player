import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musio/features/home/presentation/screens/home_screen.dart';
import 'package:musio/features/online/presentation/screens/online_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OfflineHomeScreen(),
    const OnlineScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.72),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                indicatorColor: scheme.primaryContainer.withValues(alpha: 0.90),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                height: 64,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music),
                    label: 'Ma Musique',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: 'Découvrir',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
