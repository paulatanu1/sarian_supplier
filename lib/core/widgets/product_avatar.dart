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
  final double? width;
  final double? height;
  final double  size;
  final double  radius;

  const ProductAvatar({
    super.key,
    this.imageUrl,
    required this.productName,
    required this.company,
    required this.composition,
    this.width,
    this.height,
    this.size   = 120,
    this.radius = 12,
  });

  double get _w => width ?? size;
  double get _h => height ?? size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: _w, height: _h, fit: BoxFit.cover,
          placeholder: (ctx, _) => _generated(),
          errorWidget: (ctx, url, _) => _generated(),
        ),
      );
    }
    return _generated();
  }

  Widget _generated() {
    final idx     = gradientIndexFor(company + productName);
    final colors  = AppColors.categoryGradients[idx % AppColors.categoryGradients.length];
    final abbrev  = company.isNotEmpty ? company[0].toUpperCase() : 'S';
    // Scale inner content by shorter dimension so it fits both square + rectangular.
    final s = _w < _h ? _w : _h;

    return Container(
      width: _w, height: _h,
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
            radius: s * 0.16,
            backgroundColor: Colors.white24,
            child: Text(abbrev,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: s * 0.16,
              ),
            ),
          ),
          SizedBox(height: s * 0.06),
          Flexible(
            child: Text(
              productName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: s * 0.09,
              ),
            ),
          ),
          SizedBox(height: s * 0.03),
          Flexible(
            child: Text(
              composition,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: s * 0.075,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
