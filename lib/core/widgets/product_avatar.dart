import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

/// Renders a gradient card with company/product text when no image URL is set.
class ProductAvatar extends StatelessWidget {
  final String? imageUrl;
  final String  productName;
  final String  company;
  final String  composition;
  final double  size;
  final double  radius;

  const ProductAvatar({
    super.key,
    this.imageUrl,
    required this.productName,
    required this.company,
    required this.composition,
    this.size   = 120,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size, height: size, fit: BoxFit.cover,
          placeholder: (ctx, _) => _generated(),
          errorWidget: (ctx, url, _) => _generated(),
        ),
      );
    }
    return _generated();
  }

  Widget _generated() {
    final idx    = gradientIndexFor(company + productName);
    final colors = AppColors.categoryGradients[idx % AppColors.categoryGradients.length];
    final abbrev = company.isNotEmpty ? company[0].toUpperCase() : 'S';

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: size * 0.16,
            backgroundColor: Colors.white24,
            child: Text(abbrev,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.16,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            productName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.09,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            composition,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: size * 0.075,
            ),
          ),
        ],
      ),
    );
  }
}
