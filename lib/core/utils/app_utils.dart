import 'dart:convert';
import 'dart:math';

class AppUtils {
  static String generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '$timestamp$random';
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:\\"/\\\\|?*]'), '_')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim()
        .substring(0, min(fileName.length, 255));
  }

  static String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  static Map<String, dynamic> mergeMaps(
    Map<String, dynamic> map1,
    Map<String, dynamic> map2,
  ) {
    return {...map1, ...map2};
  }

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  static bool isValidUrl(String url) {
    final regex = RegExp(
      r'^https?://(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)$',
    );
    return regex.hasMatch(url);
  }

  static String extractFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) return '';
    return fileName.substring(lastDot + 1).toLowerCase();
  }

  static String getMimeTypeFromExtension(String extension) {
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'xml': 'application/xml',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'mp3': 'audio/mpeg',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'apk': 'application/vnd.android.package-archive',
    };
    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }

  static String toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  static String toCamelCase(String text) {
    final words = text.toLowerCase().split(RegExp(r'[_\\s]+'));
    return words.first + words.skip(1).map((w) => toTitleCase(w)).join('');
  }

  static String toSnakeCase(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'[\\s-]+'), '_')
        .toLowerCase();
  }

  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars * 2) return '*' * data.length;
    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final middle = '*' * (data.length - visibleChars * 2);
    return '$start$middle$end';
  }

  static bool containsDangerousCommands(String command) {
    final dangerousPatterns = [
      r'rm\\s+-rf',
      r'rm\\s+-r\\s+/',
      r'dd\\s+if=',
      r'mkfs\\.',
      r'fdisk',
      r'format\\s+/',
      r'del\\s+/[fF]',
      r'erase\\s+/[fF]',
      r'>\\s*/dev/',
      r'wipe',
      r'factory reset',
      r'hard reset',
    ];
    
    final lowerCommand = command.toLowerCase();
    return dangerousPatterns.any((pattern) => 
      RegExp(pattern).hasMatch(lowerCommand));
  }

  static List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'(https?://[^\\s]+)|(www\\.[^\\s]+)',
      caseSensitive: false,
    );
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static List<String> extractPhoneNumbers(String text) {
    final phoneRegex = RegExp(r'\\b\\d{10,}\\b');
    return phoneRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static List<String> extractEmails(String text) {
    final emailRegex = RegExp(r'[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}');
    return emailRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static String encodeToBase64(String text) {
    return base64Encode(utf8.encode(text));
  }

  static String decodeFromBase64(String encoded) {
    return utf8.decode(base64Decode(encoded));
  }
}
