import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../utils/constants.dart';

/// Displays a flag image from a URL with memory and disk caching.
class FlagImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const FlagImage({
    super.key,
    required this.url,
    this.width = kFlagWidth,
    this.height = kFlagHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: width.toInt(),
      memCacheHeight: height.toInt(),
      cacheManager: CacheManager(
        Config(
          kFlagCacheKey,
          stalePeriod: kFlagCacheStalePeriod,
          maxNrOfCacheObjects: kFlagCacheMaxObjects,
        ),
      ),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
