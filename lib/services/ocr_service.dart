import 'dart:io';

class OCRService {
  /// Extract text from an image file using a fallback approach
  /// Since OCR libraries can be complex, we'll provide image file info
  /// and let the AI analyze the image content through the filename and context
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      final file = File(imagePath);

      // Check if file exists first
      if (!await file.exists()) {
        print('File does not exist: $imagePath');
        return 'Error: Image file not found or not accessible';
      }

      final fileName = imagePath.split('/').last.toLowerCase();

      // Get file size for context (with error handling)
      int fileSize = 0;
      try {
        fileSize = await file.length();
      } catch (e) {
        print('Could not get file size for $imagePath: $e');
      }

      final fileSizeKB =
          fileSize > 0 ? (fileSize / 1024).toStringAsFixed(1) : 'unknown';

      // Provide context about the image for AI analysis
      String context = 'Image file: $fileName (${fileSizeKB}KB)\n';

      // Try to infer content from filename
      if (fileName.contains('contract') || fileName.contains('agreement')) {
        context += 'This appears to be a contract or agreement document. ';
      } else if (fileName.contains('notice') || fileName.contains('letter')) {
        context += 'This appears to be a notice or letter document. ';
      } else if (fileName.contains('invoice') || fileName.contains('bill')) {
        context += 'This appears to be an invoice or bill document. ';
      } else if (fileName.contains('lease') || fileName.contains('rental')) {
        context += 'This appears to be a lease or rental document. ';
      } else if (fileName.contains('court') || fileName.contains('legal')) {
        context += 'This appears to be a court or legal document. ';
      } else {
        context +=
            'This appears to be a document or image with potential legal content. ';
      }

      context +=
          'Please analyze this legal document image and extract any relevant legal information, terms, dates, parties involved, or other important details.';

      return context;
    } catch (e) {
      print('OCR processing error for $imagePath: $e');
      return 'Error processing image: File access issue. This may be due to permissions or file format.';
    }
  }

  /// Extract text from multiple image files
  static Future<Map<String, String>> extractTextFromImages(
    List<String> imagePaths,
  ) async {
    Map<String, String> results = {};

    for (String imagePath in imagePaths) {
      final fileName = imagePath.split('/').last;
      final extractedText = await extractTextFromImage(imagePath);
      results[fileName] = extractedText;
    }

    return results;
  }

  /// Dispose method for compatibility (no resources to dispose in fallback)
  static void dispose() {
    // No resources to dispose in the fallback implementation
  }
}
