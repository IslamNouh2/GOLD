import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  File? _logFile;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_logs.txt');
      
      // Clear old logs on start if they get too big (> 1MB)
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > 1024 * 1024) {
          await _logFile!.writeAsString('--- LOGS RESET --- \n');
        }
      } else {
        await _logFile!.create();
      }
      
      log('Logger initialized at: ${_logFile!.path}');
    } catch (e) {
      debugPrint('Error initializing logger: $e');
    }
  }

  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    
    // Always print to console
    debugPrint(logMessage);

    // Write to file if available
    if (_logFile != null) {
      _logFile!.writeAsStringSync('$logMessage\n', mode: FileMode.append);
    }
  }

  Future<String> getLogs() async {
    if (_logFile == null) return 'No log file found.';
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }
}
