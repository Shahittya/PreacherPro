import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Utility class for handling Base64 encoded images
class ImageUtils {
  /// Check if a string is Base64 encoded image data (not a URL)
  static bool isBase64(String? str) {
    if (str == null || str.isEmpty) return false;
    // Base64 strings don't start with 'http'
    if (str.startsWith('http://') || str.startsWith('https://')) return false;
    // Valid Base64 contains only alphanumeric, +, /, and = for padding
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(str);
  }

  /// Decode Base64 string to Image widget
  static Image decodeBase64Image(String base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
      );
    } catch (e) {
      print('Error decoding Base64 image: $e');
      return Image.asset(
        'assets/placeholder.png',
        width: width,
        height: height,
        fit: fit,
      );
    }
  }

  /// Decode Base64 string to Uint8List
  static Uint8List? decodeBase64Bytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding Base64 bytes: $e');
      return null;
    }
  }

  /// Check file size in KB
  static double getFileSizeInKB(String base64String) {
    return base64String.length / 1024;
  }

  /// Check if image is compressed enough (under 500KB)
  static bool isImageSizeValid(String base64String) {
    return getFileSizeInKB(base64String) < 500;
  }
}
