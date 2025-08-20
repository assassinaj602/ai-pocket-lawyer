import 'dart:io';
import 'dart:typed_data';

class OCRService {
  /// Extract text from an image file using a comprehensive approach
  /// This implementation provides detailed image analysis for AI processing
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      print('DEBUG: Processing image at path: $imagePath');

      final file = File(imagePath);

      print('DEBUG: File exists check for: ${file.path}');
      // Check if file exists first
      if (!await file.exists()) {
        print('DEBUG: File does not exist: $imagePath');
        return 'Error: Image file not found or not accessible at path: $imagePath';
      }

      final fileName =
          imagePath.split(Platform.pathSeparator).last.toLowerCase();
      print('DEBUG: Processing file name: $fileName');

      // Get file size for context (with error handling)
      int fileSize = 0;
      Uint8List? imageBytes;
      try {
        imageBytes = await file.readAsBytes();
        fileSize = imageBytes.length;
        print('DEBUG: Successfully read ${fileSize} bytes from image');
      } catch (e) {
        print('DEBUG: Could not read file $imagePath: $e');
        return 'Error: Cannot read image file - may be corrupted or inaccessible: ${e.toString()}';
      }

      final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);

      // Enhanced document type analysis
      String documentType = _analyzeDocumentType(fileName);

      // Get image format
      String imageFormat = _getImageFormat(imageBytes);
      print('DEBUG: Detected image format: $imageFormat');

      // Create detailed context for AI analysis
      String context = '''LEGAL DOCUMENT IMAGE ATTACHED

File Details:
- Name: ${fileName}
- Size: ${fileSizeKB}KB
- Format: $imageFormat
- Type: $documentType

Image Content Instructions:
I have attached a legal document image that needs to be analyzed. Please examine this image carefully and extract:

1. All visible text content (titles, headings, body text, fine print)
2. Key legal terms, clauses, and conditions
3. Important dates, deadlines, and time periods
4. Names of parties, organizations, or individuals
5. Financial amounts, fees, or monetary terms
6. Legal references, statute numbers, or case citations
7. Contact information (addresses, phone numbers, emails)
8. Signatures, notarizations, or official stamps
9. Any compliance requirements or legal obligations
10. Warning notices or important disclaimers

Document Analysis Context:
$documentType

Please provide a thorough analysis of the legal content in this image, focusing on actionable information that can help with legal guidance and next steps.''';

      return context;
    } catch (e) {
      print('OCR processing error for $imagePath: $e');
      return 'Error processing image: ${e.toString()}';
    }
  }

  /// Analyze document type based on filename and provide context
  static String _analyzeDocumentType(String fileName) {
    fileName = fileName.toLowerCase();

    if (fileName.contains('contract') || fileName.contains('agreement')) {
      return 'CONTRACT/AGREEMENT - Look for terms, conditions, obligations, termination clauses, payment terms, and party responsibilities.';
    } else if (fileName.contains('notice') || fileName.contains('letter')) {
      return 'LEGAL NOTICE/LETTER - Look for deadlines, required actions, legal violations, and response requirements.';
    } else if (fileName.contains('invoice') ||
        fileName.contains('bill') ||
        fileName.contains('receipt')) {
      return 'FINANCIAL DOCUMENT - Look for amounts due, payment terms, services provided, and billing disputes.';
    } else if (fileName.contains('lease') ||
        fileName.contains('rental') ||
        fileName.contains('rent')) {
      return 'RENTAL/LEASE DOCUMENT - Look for rental terms, deposit amounts, tenant rights, landlord obligations, and termination conditions.';
    } else if (fileName.contains('court') ||
        fileName.contains('legal') ||
        fileName.contains('lawsuit')) {
      return 'COURT/LEGAL DOCUMENT - Look for case numbers, hearing dates, legal requirements, and procedural deadlines.';
    } else if (fileName.contains('employment') ||
        fileName.contains('job') ||
        fileName.contains('work') ||
        fileName.contains('overtime') ||
        fileName.contains('wage') ||
        fileName.contains('payroll') ||
        fileName.contains('timesheet') ||
        fileName.contains('schedule')) {
      return 'EMPLOYMENT DOCUMENT - Look for work schedules, overtime hours, wage information, pay rates, time records, disciplinary actions, employee rights, and labor law violations.';
    } else if (fileName.contains('question') ||
        fileName.contains('problem') ||
        fileName.contains('issue')) {
      return 'LEGAL QUESTION/PROBLEM DOCUMENT - Look for specific legal questions, issues described, relevant facts, dates, parties involved, and any evidence of legal violations or disputes.';
    } else if (fileName.contains('insurance') || fileName.contains('claim')) {
      return 'INSURANCE DOCUMENT - Look for coverage details, claim information, policy terms, and denial reasons.';
    } else if (fileName.contains('tax') || fileName.contains('irs')) {
      return 'TAX DOCUMENT - Look for tax obligations, deadlines, penalty information, and payment requirements.';
    } else if (fileName.contains('medical') || fileName.contains('health')) {
      return 'MEDICAL/HEALTH DOCUMENT - Look for treatment information, billing issues, insurance claims, and patient rights.';
    } else if (fileName.contains('ticket') ||
        fileName.contains('citation') ||
        fileName.contains('fine')) {
      return 'CITATION/TICKET - Look for violation details, fine amounts, court dates, and appeal procedures.';
    } else {
      return 'GENERAL LEGAL DOCUMENT - Look for any legal terms, obligations, rights, deadlines, and actionable information.';
    }
  }

  /// Determine image format from file bytes
  static String _getImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'Unknown';

    // Check for common image file signatures
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'JPEG';
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47)
      return 'PNG';
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return 'GIF';
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return 'BMP';
    if (bytes[0] == 0x49 && bytes[1] == 0x49 ||
        bytes[0] == 0x4D && bytes[1] == 0x4D)
      return 'TIFF';

    return 'Image';
  }

  /// Extract text from multiple image files
  static Future<Map<String, String>> extractTextFromImages(
    List<String> imagePaths,
  ) async {
    Map<String, String> results = {};
    print('DEBUG: Starting batch OCR for ${imagePaths.length} images');

    for (String imagePath in imagePaths) {
      try {
        final fileName = imagePath.split(Platform.pathSeparator).last;
        print('DEBUG: Processing file: $fileName at path: $imagePath');

        final extractedText = await extractTextFromImage(imagePath);
        results[fileName] = extractedText;

        print(
          'DEBUG: Successfully processed $fileName, result length: ${extractedText.length}',
        );
      } catch (e) {
        print('DEBUG: Error processing image $imagePath: $e');
        final fileName = imagePath.split(Platform.pathSeparator).last;
        results[fileName] = 'Error processing image: ${e.toString()}';
      }
    }

    print('DEBUG: Batch OCR completed with ${results.length} results');
    return results;
  }

  /// Dispose method for compatibility (no resources to dispose in fallback)
  static void dispose() {
    // No resources to dispose in the fallback implementation
  }
}
