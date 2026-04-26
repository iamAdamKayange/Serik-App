// lib/utils/image_helper.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageHelper {
  // Check if image is Base64
  static bool isBase64(String imageString) {
    return imageString.startsWith('/data') == false &&
        imageString.startsWith('/storage') == false &&
        imageString.startsWith('http') == false &&
        imageString.contains('||') == false;
  }

  // Decode Base64 to Image widget
  static Widget buildImage(
    String imageString, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageString.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }

    // Check if it's Base64
    if (isBase64(imageString)) {
      try {
        Uint8List bytes = base64Decode(imageString);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey,
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      }
    }

    // Local file path (old format)
    return Image.file(
      File(imageString),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      },
    );
  }

  // Get first image as widget
  static Widget buildFirstImage(
    List<String> images, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (images.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.home_rounded, size: 40, color: Colors.grey),
      );
    }
    return buildImage(images.first, width: width, height: height, fit: fit);
  }
}
