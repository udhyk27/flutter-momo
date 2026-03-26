import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:provider/provider.dart';

class CustomBtAppBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChange;

  const CustomBtAppBar({
    required this.currentIndex,
    required this.onTabChange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeValue = context.watch<MyAppState>().selectedValue;
    final safeIndex = currentIndex.clamp(0, 2);

    final tabs = [
      (prefix: 'icon_folder',     label: '히스토리'),
      (prefix: 'icon_momosearch', label: '음악검색'),
      (prefix: 'icon_chart',      label: '검색차트'),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: themeValue == 2 ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: themeValue == 2
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final isSelected = safeIndex == index;
                final tab = tabs[index];

                // 기존 아이콘 경로 로직 그대로 유지
                final String iconPath;
                if (themeValue == 2) {
                  iconPath = isSelected
                      ? 'assets/momo_assets/${tab.prefix}_on_reverse.png'
                      : 'assets/momo_assets/${tab.prefix}.png';
                } else {
                  iconPath = isSelected
                      ? 'assets/momo_assets/${tab.prefix}_on.png'
                      : 'assets/momo_assets/${tab.prefix}.png';
                }

                return _NavItem(
                  iconPath: iconPath,
                  label: tab.label,
                  isSelected: isSelected,
                  themeValue: themeValue,
                  onTap: () => onTabChange(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 개별 탭 아이템 ────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isSelected;
  final int themeValue;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.themeValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 기존 색상 그대로
    final selectedColor = themeValue == 2 ? Colors.white : Colors.black;
    final unselectedColor = themeValue == 2 ? Colors.white54 : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // 선택된 탭: 유리 질감 pill 배경
          color: isSelected
              ? (themeValue == 2
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (themeValue == 2
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08))
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: isSelected ? 1.0 : 0.55,
              child: Image.asset(iconPath, width: 25, height: 25),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}