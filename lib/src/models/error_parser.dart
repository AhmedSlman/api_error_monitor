import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class to parse error messages and extract information
class ErrorParser {
  /// Parse exception to extract key, expected type, and received type
  static ApiErrorInfo parseError(dynamic error, String errorMessage) {
    print('🚀 ErrorParser.parseError called');
    print(
      '📝 Error message (first 200 chars): ${errorMessage.length > 200 ? errorMessage.substring(0, 200) + "..." : errorMessage}',
    );

    String? key;
    String? expectedType;
    String? receivedType;

    // FIRST: Extract types from error message (before trying to extract key)
    // This helps us filter out type names when extracting keys
    final typeCastPattern = RegExp(
      r"type '([^']+)' is not a subtype of type '([^']+)'",
      caseSensitive: false,
    );
    final typeCastMatch = typeCastPattern.firstMatch(errorMessage);
    if (typeCastMatch != null) {
      receivedType = _cleanType(typeCastMatch.group(1));
      expectedType = _cleanType(typeCastMatch.group(2));
      print(
        '📊 Extracted types - Received: $receivedType, Expected: $expectedType',
      );
    } else {
      print('⚠️ No type cast pattern found in error message');
    }

    // Build list of type names to exclude (including the types from error message)
    final typeNames = <String>[
      'int',
      'String',
      'double',
      'bool',
      'num',
      'List',
      'Map',
      'dynamic',
      'null',
      'Null',
    ];
    if (receivedType != null && !typeNames.contains(receivedType)) {
      typeNames.add(receivedType);
    }
    if (expectedType != null && !typeNames.contains(expectedType)) {
      typeNames.add(expectedType);
    }

    print('🔍 Starting key extraction...');
    print('📋 Type names to exclude: $typeNames');

    // SECOND: Try to extract key from stack trace first (works everywhere)
    // This is the most portable method that works in production
    key = _extractKeyFromStackTrace(errorMessage, typeNames);

    // THIRD: If not found and in debug mode, try reading source file
    // This is more reliable but only works in development
    if (key == null && kDebugMode) {
      print('🔍 Debug mode: Trying to read source file...');
      key = _extractKeyFromSourceFile(errorMessage, typeNames);
    }

    print('🔑 Key after source file/stack trace extraction: ${key ?? "null"}');

    // THIRD: If not found, try to extract key from fromJson patterns in all lines
    // But exclude type names from error message
    if (key == null) {
      print('🔍 Trying fromJson pattern extraction...');
      final fromJsonPattern = RegExp(
        r"json\s*\[\s*[']([^']+)[']\s*\]",
        caseSensitive: false,
        multiLine: true,
      );
      final fromJsonMatches = fromJsonPattern.allMatches(errorMessage);
      print('📝 Found ${fromJsonMatches.length} fromJson matches');
      for (final match in fromJsonMatches) {
        if (match.groupCount > 0) {
          final potentialKey = match.group(1)?.trim();
          print('🔍 Checking potential key: $potentialKey');
          if (potentialKey != null &&
              potentialKey.isNotEmpty &&
              potentialKey.length > 1 &&
              !typeNames.contains(potentialKey) &&
              !potentialKey.contains('type') &&
              !potentialKey.contains('subtype') &&
              !potentialKey.contains('cast')) {
            print('✅ Using key from fromJson pattern: $potentialKey');
            key = potentialKey;
            break; // Use first valid key found
          } else {
            print('⚠️ Rejected key: $potentialKey (excluded or invalid)');
          }
        }
      }
    }

    // Types already extracted above, skip this section

    // Pattern 2: Invalid argument(s): key not found: "keyName"
    final keyNotFoundPattern = RegExp(
      'key not found[:\\s]+["\']?([^"\']+)["\']?',
      caseSensitive: false,
    );
    final keyNotFoundMatch = keyNotFoundPattern.firstMatch(errorMessage);
    if (keyNotFoundMatch != null && keyNotFoundMatch.groupCount > 0) {
      key = keyNotFoundMatch.group(1);
    }

    // Pattern 3: type 'Null' is not a subtype of type 'String' (or other types)
    final nullPattern = RegExp(
      r"type 'null' is not a subtype of type '([^']+)'",
      caseSensitive: false,
    );
    final nullMatch = nullPattern.firstMatch(errorMessage);
    if (nullMatch != null) {
      receivedType = 'null';
      expectedType = _cleanType(nullMatch.group(1));
    }

    // Pattern 4: CastError - type 'X' is not a subtype of type 'Y' in type cast
    final castErrorPattern = RegExp(
      r"type '([^']+)' is not a subtype of type '([^']+)' in type cast",
      caseSensitive: false,
    );
    final castErrorMatch = castErrorPattern.firstMatch(errorMessage);
    if (castErrorMatch != null) {
      receivedType = _cleanType(castErrorMatch.group(1));
      expectedType = _cleanType(castErrorMatch.group(2));
    }

    // Pattern 5: FormatException or similar - DISABLED
    // This pattern was extracting type names (like "String") from error messages
    // We rely on _extractKeyFromExceptionLine and other patterns instead
    // This pattern is disabled to prevent false positives like extracting "String" from error messages

    // Pattern 6: Try to extract key from stack trace (e.g., data['price'], json['id'])
    // Look for patterns like: data['keyName'], json['keyName'], map['keyName']
    // But exclude common type names (int, String, double, bool, etc.)
    if (key == null) {
      print('🔍 Trying Pattern 6: stack trace json[key] extraction...');
      // More flexible pattern: matches data['key'], json['key'], map['key'], response['key']
      // Also matches multi-line patterns
      final stackTracePattern = RegExp(
        r"(?:data|json|map|response)\s*\[\s*[']([^']+)[']\s*\]",
        caseSensitive: false,
        multiLine: true,
      );
      final matches = stackTracePattern.allMatches(errorMessage);
      print('📝 Found ${matches.length} stack trace matches');
      for (final match in matches) {
        if (match.groupCount > 0) {
          final potentialKey = match.group(1)?.trim();
          print('🔍 Checking potential key: $potentialKey');
          // Only use it if it's not a type name and not empty
          if (potentialKey != null &&
              potentialKey.isNotEmpty &&
              !typeNames.contains(potentialKey) &&
              !potentialKey.contains('type') &&
              !potentialKey.contains('subtype') &&
              !potentialKey.contains('cast') &&
              potentialKey.length > 1) {
            // Keys are usually longer than 1 character
            print('✅ Using key from Pattern 6: $potentialKey');
            key = potentialKey;
            break; // Use the first valid key found
          } else {
            print('⚠️ Rejected key: $potentialKey (excluded or invalid)');
          }
        }
      }
    }

    // Pattern 7: Try to extract from patterns like: data["keyName"], json["keyName"]
    if (key == null) {
      // More flexible pattern with multi-line support
      final doubleQuotePattern = RegExp(
        r'(?:data|json|map|response)\s*\[\s*"([^"]+)"\s*\]',
        caseSensitive: false,
        multiLine: true,
      );
      final matches = doubleQuotePattern.allMatches(errorMessage);
      for (final match in matches) {
        if (match.groupCount > 0) {
          final potentialKey = match.group(1)?.trim();
          // Only use it if it's not a type name and not empty
          if (potentialKey != null &&
              potentialKey.isNotEmpty &&
              !typeNames.contains(potentialKey) &&
              !potentialKey.contains('type') &&
              !potentialKey.contains('subtype') &&
              !potentialKey.contains('cast') &&
              potentialKey.length > 1) {
            // Keys are usually longer than 1 character
            key = potentialKey;
            break; // Use the first valid key found
          }
        }
      }
    }

    // Pattern 8: Try to extract key from variable names in stack trace
    // Look for patterns like: final price = data['price'], var id = json['id']
    if (key == null) {
      final variablePattern = RegExp(
        r"(?:final|var|const)\s+\w+\s*=\s*(?:data|json|map|response)\s*\[\s*[']([^']+)[']\s*\]",
        caseSensitive: false,
        multiLine: true,
      );
      final matches = variablePattern.allMatches(errorMessage);
      for (final match in matches) {
        if (match.groupCount > 0) {
          final potentialKey = match.group(1)?.trim();
          if (potentialKey != null &&
              potentialKey.isNotEmpty &&
              potentialKey.length > 1 &&
              !typeNames.contains(potentialKey) &&
              !potentialKey.contains('type') &&
              !potentialKey.contains('subtype') &&
              !potentialKey.contains('cast')) {
            key = potentialKey;
            break;
          }
        }
      }
    }

    // Try to get type information from the error object itself
    if (error is TypeError) {
      final typeErrorString = error.toString();
      if (receivedType == null || expectedType == null) {
        final errorMatch = typeCastPattern.firstMatch(typeErrorString);
        if (errorMatch != null) {
          receivedType ??= _cleanType(errorMatch.group(1));
          expectedType ??= _cleanType(errorMatch.group(2));
        }
      }
    }

    print('🎯 Final extracted key: ${key ?? "null"}');
    print('🎯 Final expected type: ${expectedType ?? "null"}');
    print('🎯 Final received type: ${receivedType ?? "null"}');

    return ApiErrorInfo(
      key: key,
      expectedType: expectedType,
      receivedType: receivedType,
    );
  }

  /// Clean type string to make it more readable
  static String _cleanType(String? type) {
    if (type == null) return 'Unknown';
    return type
        .replaceAll('dart.core.', '')
        .replaceAll('dart.collection.', '')
        .replaceAll('<dynamic>', '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
  }

  /// Extract key directly from stack trace - fastest and most reliable method
  /// Strategy: Search for json['key'] patterns near error lines (.dart:line_number)
  static String? _extractKeyFromStackTrace(
    String errorMessage,
    List<String> typeNames,
  ) {
    print('🔍 _extractKeyFromStackTrace called');
    final lines = errorMessage.split('\n');

    // Priority 1: Search for json['key'] patterns in the entire stack trace
    // This is the most reliable method that works everywhere
    print('🔍 Priority 1: Searching for json[key] patterns...');
    for (final line in lines) {
      final extractedKey = _extractKeyFromLine(line, typeNames);
      if (extractedKey != null) {
        print('✅ Extracted key from stack trace line: $extractedKey');
        return extractedKey;
      }
    }

    // Priority 2: Find error lines and search nearby
    print('🔍 Priority 2: Searching near error lines...');
    final errorLineIndices = <int>[];
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('.dart:') &&
          RegExp(r'\.dart:\d+').hasMatch(lines[i])) {
        errorLineIndices.add(i);
        print('📍 Found error line at index $i: ${lines[i].trim()}');
      }
    }

    // For each error line, search nearby lines for json['key'] patterns
    for (final errorIndex in errorLineIndices) {
      // Search in a wider window: 5 lines before to 2 lines after
      final startIndex = errorIndex > 5 ? errorIndex - 5 : 0;
      final endIndex = errorIndex + 2 < lines.length
          ? errorIndex + 2
          : lines.length;

      for (int j = startIndex; j <= endIndex; j++) {
        final line = lines[j];
        final extractedKey = _extractKeyFromLine(line, typeNames);
        if (extractedKey != null) {
          print('🔍 Found error at: ${lines[errorIndex].trim()}');
          print('✅ Extracted key from nearby line: $extractedKey');
          return extractedKey;
        }
      }
    }

    // Priority 3: Try to extract from variable assignments in stack trace
    // Look for patterns like: title: json['title'], name = json['name']
    print('🔍 Priority 3: Searching for variable assignments...');
    for (final line in lines) {
      // Look for patterns like: fieldName: json['fieldName'] or fieldName = json['fieldName']
      final assignmentPatterns = [
        RegExp(
          r"(\w+)\s*:\s*(?:json|data|map)\s*\[\s*[']([^']+)[']\s*\]",
          caseSensitive: false,
        ),
        RegExp(
          r"(\w+)\s*=\s*(?:json|data|map)\s*\[\s*[']([^']+)[']\s*\]",
          caseSensitive: false,
        ),
      ];

      for (final pattern in assignmentPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.groupCount >= 2) {
          final fieldName = match.group(1)?.trim();
          final jsonKey = match.group(2)?.trim();

          print(
            '📝 Found assignment - fieldName: $fieldName, jsonKey: $jsonKey',
          );

          // Prefer jsonKey if valid
          if (jsonKey != null &&
              jsonKey.isNotEmpty &&
              jsonKey.length > 1 &&
              !typeNames.contains(jsonKey) &&
              !jsonKey.contains('type') &&
              !jsonKey.contains('subtype') &&
              !jsonKey.contains('cast')) {
            print('✅ Using jsonKey from assignment: $jsonKey');
            return jsonKey;
          }

          // Otherwise use fieldName if valid
          if (fieldName != null &&
              fieldName.isNotEmpty &&
              fieldName.length > 1 &&
              !typeNames.contains(fieldName) &&
              !fieldName.contains('type') &&
              !fieldName.contains('subtype') &&
              !fieldName.contains('cast')) {
            print('✅ Using fieldName from assignment: $fieldName');
            return fieldName;
          }
        }
      }
    }

    // Priority 4: Removed heuristic approach - it was unreliable
    // The heuristic was matching words like "type" from error messages
    // In Production, if key cannot be extracted from stack trace,
    // it will be null and user can pass it manually if needed

    print('⚠️ Could not extract key from stack trace');
    print(
      '💡 Tip: In Production, you can pass the key manually to capture() method',
    );
    return null;
  }

  /// Read the actual source file from stack trace and extract key from error line
  /// This is the most reliable method - reads the exact line where error occurred
  static String? _extractKeyFromSourceFile(
    String errorMessage,
    List<String> typeNames,
  ) {
    try {
      final lines = errorMessage.split('\n');

      // Find the first line that contains .dart:line_number
      // Format: package:api_error_monitor_example/models/product_model.dart:22:18
      // Or: #0      new ProductModel.fromJson (package:api_error_monitor_example/models/product_model.dart:22:18)
      for (final line in lines) {
        // Match pattern: .dart:22:18 or .dart:22
        // Handle both formats: package:... and (package:...
        final fileMatch = RegExp(
          r'(?:\(|package:|file://)?([^\s()]+\.dart):(\d+)(?::(\d+))?',
        ).firstMatch(line);

        if (fileMatch != null) {
          final filePath = fileMatch.group(1);
          final lineNumberStr = fileMatch.group(2);

          if (filePath != null && lineNumberStr != null) {
            final lineNumber = int.tryParse(lineNumberStr);
            if (lineNumber != null && lineNumber > 0) {
              // Resolve file path - try multiple strategies
              print('🔍 Attempting to resolve file path: $filePath');
              final resolvedPath = _resolveFilePath(filePath);
              print('📍 Resolved path: ${resolvedPath ?? "null"}');

              if (resolvedPath != null) {
                try {
                  final file = File(resolvedPath);
                  if (file.existsSync()) {
                    final fileLines = file.readAsLinesSync();
                    if (lineNumber <= fileLines.length) {
                      final sourceLine = fileLines[lineNumber - 1]; // 1-based

                      print('🔍 Reading file: ${resolvedPath.split('/').last}');
                      print('📄 Line $lineNumber: $sourceLine');

                      // Extract key from this line
                      final extractedKey = _extractKeyFromLine(
                        sourceLine,
                        typeNames,
                      );
                      if (extractedKey != null) {
                        print(
                          '✅ Extracted key from source file: $extractedKey',
                        );
                        return extractedKey;
                      } else {
                        print(
                          '⚠️ Could not extract key from line: $sourceLine',
                        );
                      }
                    } else {
                      print(
                        '⚠️ Line number $lineNumber exceeds file length ${fileLines.length}',
                      );
                    }
                  } else {
                    print('⚠️ File not found: $resolvedPath');
                  }
                } catch (e) {
                  print('⚠️ Error reading file: $e');
                }
              } else {
                print('⚠️ Could not resolve file path: $filePath');
              }

              // Fallback: Try to extract key from nearby lines in stack trace
              // Look for json['key'] patterns in lines near the error line
              final lineIndex = lines.indexOf(line);
              if (lineIndex >= 0) {
                // Search 5 lines before and after the error line
                final startIndex = lineIndex > 5 ? lineIndex - 5 : 0;
                final endIndex = lineIndex + 5 < lines.length
                    ? lineIndex + 5
                    : lines.length;

                for (int i = startIndex; i <= endIndex; i++) {
                  final nearbyLine = lines[i];
                  final extractedKey = _extractKeyFromLine(
                    nearbyLine,
                    typeNames,
                  );
                  if (extractedKey != null) {
                    print(
                      '✅ Extracted key from nearby stack trace line: $extractedKey',
                    );
                    return extractedKey;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error in _extractKeyFromSourceFile: $e');
    }

    return null;
  }

  /// Resolve file path from package URI to actual file system path
  static String? _resolveFilePath(String filePath) {
    String packagePath = filePath;

    // Remove package: prefix if exists
    if (packagePath.startsWith('package:')) {
      packagePath = packagePath.replaceFirst('package:', '');
    }

    print('🔍 Resolving path: $packagePath');

    // Get workspace path - try multiple methods
    String? workspacePath;
    try {
      // Method 1: Try to get from environment variable or current directory
      workspacePath = Directory.current.path;

      // Method 2: If current directory is root (/), try common project locations
      if (workspacePath == '/' || workspacePath.isEmpty) {
        // Try to find api_logger directory
        final user =
            Platform.environment['USER'] ??
            Platform.environment['HOME']?.split('/').last ??
            '';
        final home = Platform.environment['HOME'] ?? '/Users/$user';
        final possiblePaths = [
          '$home/Documents/api_logger',
          '$home/api_logger',
          '/Users/$user/Documents/api_logger',
          '/Users/$user/api_logger',
        ];

        for (final path in possiblePaths) {
          final dir = Directory(path);
          if (dir.existsSync()) {
            final pubspec = File('$path/pubspec.yaml');
            if (pubspec.existsSync()) {
              workspacePath = path;
              break;
            }
          }
        }
      }

      print('📁 Resolved workspace path: $workspacePath');

      // If workspace path is still root, try to find project by searching common locations
      if (workspacePath == null ||
          workspacePath == '/' ||
          workspacePath.isEmpty) {
        final user =
            Platform.environment['USER'] ??
            Platform.environment['HOME']?.split('/').last ??
            '';
        final home = Platform.environment['HOME'] ?? '/Users/$user';

        // Search in common project locations for api_logger directory
        final searchPaths = [
          '$home/Documents',
          '$home',
          '/Users/$user/Documents',
          '/Users/$user',
        ];

        print('🔍 Searching for api_logger directory...');
        print('📋 User: $user, Home: $home');

        for (final basePath in searchPaths) {
          try {
            print('🔍 Searching in: $basePath');
            final dir = Directory(basePath);
            if (dir.existsSync()) {
              print('✅ Directory exists: $basePath');
              // Search for api_logger directory
              final entries = dir.listSync(recursive: false);
              print('📁 Found ${entries.length} entries in $basePath');
              for (final entry in entries) {
                if (entry is Directory) {
                  print('📂 Checking directory: ${entry.path}');
                  if (entry.path.endsWith('api_logger')) {
                    print('✅ Found api_logger directory: ${entry.path}');
                    final pubspec = File('${entry.path}/pubspec.yaml');
                    if (pubspec.existsSync()) {
                      workspacePath = entry.path;
                      print('✅ Found workspace by searching: $workspacePath');
                      break;
                    } else {
                      print('⚠️ pubspec.yaml not found in: ${entry.path}');
                    }
                  }
                }
              }
              if (workspacePath != null &&
                  workspacePath != '/' &&
                  workspacePath.isNotEmpty) {
                break;
              }
            } else {
              print('⚠️ Directory does not exist: $basePath');
            }
          } catch (e) {
            print('⚠️ Error searching in $basePath: $e');
            // Continue searching in next location
          }
        }

        // If still not found, try direct path check
        if (workspacePath == null ||
            workspacePath == '/' ||
            workspacePath.isEmpty) {
          final directPath = '/Users/macbookaairm2/Documents/api_logger';
          final directDir = Directory(directPath);
          if (directDir.existsSync()) {
            final pubspec = File('$directPath/pubspec.yaml');
            if (pubspec.existsSync()) {
              workspacePath = directPath;
              print('✅ Found workspace using direct path: $workspacePath');
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Could not get workspace path: $e');
    }

    // Handle package names like: api_error_monitor_example/models/product_model.dart
    // Extract the relative path (skip package name)
    if (packagePath.contains('/models/') ||
        packagePath.contains('/repositories/') ||
        packagePath.contains('/viewmodels/') ||
        packagePath.contains('/views/')) {
      final parts = packagePath.split('/');
      if (parts.length > 1) {
        final relativePath = parts.sublist(1).join('/');
        print('📂 Relative path: $relativePath');

        // Try absolute paths first
        if (workspacePath != null &&
            workspacePath != '/' &&
            workspacePath.isNotEmpty) {
          final exampleLibPath = '$workspacePath/example/lib/$relativePath';
          print('🔍 Trying absolute path: $exampleLibPath');
          final file = File(exampleLibPath);
          if (file.existsSync()) {
            print('✅ Found file: $exampleLibPath');
            return file.absolute.path;
          }
        }

        // Try relative paths from current directory
        final exampleLibPath = 'example/lib/$relativePath';
        print('🔍 Trying relative path: $exampleLibPath');
        final file = File(exampleLibPath);
        if (file.existsSync()) {
          print('✅ Found file: $exampleLibPath');
          return file.absolute.path;
        }

        // Try from parent directory (if running from example folder)
        final parentExampleLibPath = '../example/lib/$relativePath';
        print('🔍 Trying parent relative path: $parentExampleLibPath');
        final parentFile = File(parentExampleLibPath);
        if (parentFile.existsSync()) {
          print('✅ Found file: $parentExampleLibPath');
          return parentFile.absolute.path;
        }
      }
    }

    // Try common locations (absolute paths first)
    if (workspacePath != null) {
      final absolutePaths = [
        '$workspacePath/example/lib/$packagePath',
        '$workspacePath/example/$packagePath',
        '$workspacePath/lib/$packagePath',
        '$workspacePath/$packagePath',
      ];

      for (final path in absolutePaths) {
        print('🔍 Trying: $path');
        final file = File(path);
        if (file.existsSync()) {
          print('✅ Found file: $path');
          return file.absolute.path;
        }
      }
    }

    // Try relative paths
    final relativePaths = [
      'example/lib/$packagePath',
      'example/$packagePath',
      'lib/$packagePath',
      packagePath,
    ];

    for (final path in relativePaths) {
      print('🔍 Trying: $path');
      final file = File(path);
      if (file.existsSync()) {
        print('✅ Found file: $path');
        return file.absolute.path;
      }
    }

    // Handle file:// URIs
    if (filePath.startsWith('file://')) {
      final resolved = filePath.replaceFirst('file://', '');
      print('🔍 Trying file:// URI: $resolved');
      return resolved;
    }

    print('❌ Could not resolve file path: $filePath');
    return null;
  }

  /// Extract key from a source code line
  static String? _extractKeyFromLine(String line, List<String> typeNames) {
    print('🔍 Extracting key from line: $line');
    print('🚫 Excluding type names: $typeNames');

    // Priority 1: Find patterns like: title: json['title'] or title = json['title']
    final assignmentPatterns = [
      RegExp(
        r"(\w+)\s*:\s*(?:json|data|map)\s*\[\s*[']([^']+)[']\s*\]",
        caseSensitive: false,
      ),
      RegExp(
        r"(\w+)\s*=\s*(?:json|data|map)\s*\[\s*[']([^']+)[']\s*\]",
        caseSensitive: false,
      ),
      RegExp(
        r'(\w+)\s*:\s*(?:json|data|map)\s*\[\s*"([^"]+)"\s*\]',
        caseSensitive: false,
      ),
    ];

    for (final pattern in assignmentPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null && match.groupCount >= 2) {
        final fieldName = match.group(1)?.trim();
        final jsonKey = match.group(2)?.trim();

        print('📝 Found match - fieldName: $fieldName, jsonKey: $jsonKey');

        // Prefer the json key if it's valid
        if (jsonKey != null &&
            jsonKey.isNotEmpty &&
            jsonKey.length > 1 &&
            !typeNames.contains(jsonKey) &&
            !jsonKey.contains('type') &&
            !jsonKey.contains('subtype') &&
            !jsonKey.contains('cast')) {
          print('✅ Returning jsonKey: $jsonKey');
          return jsonKey;
        }
        // Otherwise use field name if valid
        if (fieldName != null &&
            fieldName.isNotEmpty &&
            fieldName.length > 1 &&
            !typeNames.contains(fieldName) &&
            !fieldName.contains('type') &&
            !fieldName.contains('subtype') &&
            !fieldName.contains('cast')) {
          print('✅ Returning fieldName: $fieldName');
          return fieldName;
        }

        print('⚠️ Both fieldName and jsonKey are invalid or excluded');
      }
    }

    // Priority 2: Find json['key'] patterns (without assignment)
    final jsonPatterns = [
      RegExp(r"json\s*\[\s*[']([^']+)[']\s*\]", caseSensitive: false),
      RegExp(r'json\s*\[\s*"([^"]+)"\s*\]', caseSensitive: false),
      RegExp(r"data\s*\[\s*[']([^']+)[']\s*\]", caseSensitive: false),
      RegExp(r'data\s*\[\s*"([^"]+)"\s*\]', caseSensitive: false),
      RegExp(r"map\s*\[\s*[']([^']+)[']\s*\]", caseSensitive: false),
      RegExp(r'map\s*\[\s*"([^"]+)"\s*\]', caseSensitive: false),
    ];

    for (final pattern in jsonPatterns) {
      final matches = pattern.allMatches(line);
      for (final match in matches) {
        if (match.groupCount > 0) {
          final potentialKey = match.group(1)?.trim();
          if (potentialKey != null &&
              potentialKey.isNotEmpty &&
              potentialKey.length > 1 &&
              !typeNames.contains(potentialKey) &&
              !potentialKey.contains('type') &&
              !potentialKey.contains('subtype') &&
              !potentialKey.contains('cast')) {
            return potentialKey;
          }
        }
      }
    }

    return null;
  }
}

/// Information extracted from an error
class ApiErrorInfo {
  final String? key;
  final String? expectedType;
  final String? receivedType;

  ApiErrorInfo({this.key, this.expectedType, this.receivedType});
}
