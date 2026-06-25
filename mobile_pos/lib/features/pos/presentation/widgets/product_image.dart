import 'dart:convert';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String? imageUrl;
  final Widget placeholder;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim() ?? '';
    if (trimmedUrl.isEmpty) {
      return placeholder;
    }

    if (trimmedUrl.startsWith('data:image/')) {
      final commaIndex = trimmedUrl.indexOf(',');
      if (commaIndex <= 0) {
        return placeholder;
      }

      try {
        final bytes = base64Decode(trimmedUrl.substring(commaIndex + 1));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (_) {
        return placeholder;
      }
    }

    return Image.network(
      trimmedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
