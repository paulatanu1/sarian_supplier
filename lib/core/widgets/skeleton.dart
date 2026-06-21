import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class AppSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const AppSkeleton({super.key, this.width = double.infinity, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor:  dark ? AppColors.cardDark    : const Color(0xFFE0E0E0),
      highlightColor: dark ? AppColors.surfaceDark : const Color(0xFFF5F5F5),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: dark ? AppColors.cardDark : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppSkeleton(height: 110, radius: 12),
      const SizedBox(height: 10),
      AppSkeleton(height: 12, width: 140),
      const SizedBox(height: 6),
      AppSkeleton(height: 10, width: 100),
      const SizedBox(height: 10),
      AppSkeleton(height: 32, radius: 8),
    ]),
  );
}

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        AppSkeleton(height: 14, width: 140),
        AppSkeleton(height: 22, width: 70, radius: 20),
      ]),
      const SizedBox(height: 10),
      AppSkeleton(height: 10, width: 100),
      const SizedBox(height: 6),
      AppSkeleton(height: 10, width: 80),
    ]),
  );
}
