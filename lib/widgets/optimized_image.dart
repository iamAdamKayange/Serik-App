import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:serik/providers/theme_provider.dart';

/// Optimized image widget with enhanced caching and error handling
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? fadeInDuration;
  final bool useMemCache;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration,
    this.useMemCache = true,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: placeholder != null
          ? (context, url) => placeholder!
          : (context, url) => Container(
              width: width,
              height: height,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
            ),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!
          : (context, url, error) => Container(
              width: width,
              height: height,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: Icon(
                Icons.broken_image,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                size: 32,
              ),
            ),
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      useOldImageOnUrlChange: true,
      maxWidthDiskCache: 100 * 1024 * 1024, // 100MB
      maxHeightDiskCache: 100 * 1024 * 1024, // 100MB
    );
  }
}

/// Optimized circular image for avatars
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final defaultColor = backgroundColor ?? 
        (isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32));

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return OptimizedImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 2).toInt(),
        memCacheHeight: (size * 2).toInt(),
      );
    }

    // Fallback to initials
    final initials = name != null && name!.isNotEmpty
        ? name!.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: defaultColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Optimized property image carousel
class OptimizedPropertyCarousel extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final BoxFit fit;
  final Function(int)? onImageTap;

  const OptimizedPropertyCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.fit = BoxFit.cover,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return _buildEmptyPlaceholder(context);
    }

    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onImageTap?.call(index),
            child: OptimizedImage(
              imageUrl: imageUrls[index],
              height: height,
              fit: fit,
              memCacheWidth: 800,
              memCacheHeight: 600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      height: height,
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }
}

/// Optimized gallery grid for multiple images
class OptimizedGalleryGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double aspectRatio;
  final Function(int)? onImageTap;

  const OptimizedGalleryGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.aspectRatio = 1.0,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return _buildEmptyPlaceholder(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onImageTap?.call(index),
          child: OptimizedImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            memCacheWidth: 400,
            memCacheHeight: 400,
          ),
        );
      },
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      height: 200,
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No images',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}