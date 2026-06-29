import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletonLoader extends StatelessWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  /// Base shimmer modifier using flutter_animate
  Widget _applyShimmer(Widget target, int index) {
    return target
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          delay: (index * 100).ms,
          duration: 1200.ms,
          color: const Color(0xFFF8FAFC), // Ultra soft white shimmer glare
        );
  }

  /// Reusable rounded rectangle bar
  static Widget bar({required double width, required double height, double borderRadius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0), // Slate 200 base loading color
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Reusable circle skeleton
  static Widget circle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
    );
  }

  /// 1. PROFILE DASHBOARD HEADER SKELETON
  factory SkeletonLoader.profile() {
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header container mock
            Container(
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 60),
              decoration: const BoxDecoration(
                color: Color(0xFF0F4C81), // Solid theme background
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  // Avatar circle
                  circle(size: 80),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(width: 120, height: 16),
                        const SizedBox(height: 8),
                        bar(width: 180, height: 12),
                        const SizedBox(height: 6),
                        bar(width: 90, height: 18, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Sub-cards mock
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          circle(size: 40),
                          const SizedBox(height: 8),
                          bar(width: 50, height: 14),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),
                    Expanded(
                      child: Column(
                        children: [
                          circle(size: 40),
                          const SizedBox(height: 8),
                          bar(width: 80, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Menu list mock
            ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    circle(size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(width: 120, height: 14),
                          const SizedBox(height: 6),
                          bar(width: 180, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 2. LIST VIEW SKELETON (For Admin/Super Admin pages)
  factory SkeletonLoader.list({int itemCount = 4}) {
    return SkeletonLoader(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    circle(size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(width: 120, height: 14),
                          const SizedBox(height: 6),
                          bar(width: 80, height: 10),
                        ],
                      ),
                    ),
                    bar(width: 60, height: 24, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 16),
                bar(width: double.infinity, height: 36, borderRadius: 10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    bar(width: 100, height: 12),
                    bar(width: 80, height: 12),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 3. SINGLE CARD SKELETON
  factory SkeletonLoader.card() {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                circle(size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(width: 120, height: 14),
                      const SizedBox(height: 6),
                      bar(width: 200, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                bar(width: 100, height: 12),
                bar(width: 80, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 4. GRID VIEW SKELETON (For Promo, popular routes, etc)
  factory SkeletonLoader.grid({int itemCount = 4}) {
    return SkeletonLoader(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                bar(width: 100, height: 12),
                const SizedBox(height: 6),
                bar(width: 60, height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _applyShimmer(child, 0);
  }
}
