import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:logging/logging.dart';

class CsvParser {
  static final Logger log = Logger('CsvParser');

  static List<String>? processCsv(Uint8List data) {
    String rawCsv;
    try {
      rawCsv = utf8.decode(data);
      log.info('CSV file decoded with UTF-8.');
    } on FormatException catch (fe) {
      log.warning('UTF-8 decoding failed, trying ISO-8859-1. Error: ${fe.message}');
      try {
        rawCsv = latin1.decode(data);
        log.info('CSV file decoded with ISO-8859-1.');
      } catch (e) {
        log.severe('Failed to decode CSV file: $e');
        throw "Failed to parse CSV: $e";
      }
    }

    List<List<dynamic>> rowsAsListOfValues;
    try {
      var detectedParams = CsvDelimiterDetector.detectDelimiterAndEol(rawCsv);
      rowsAsListOfValues = CsvToListConverter(
        fieldDelimiter: detectedParams['delimiter']!,
        eol: detectedParams['eol']!,
      ).convert(rawCsv);
      if (rowsAsListOfValues.isNotEmpty && rowsAsListOfValues.first.every((cell) => cell is String)) {
        log.info('CSV header row processed successfully.');
      } else {
        log.warning('Header row contains non-string values.');
      }
    } catch (e) {
      log.severe('Failed to process CSV data: $e');
      throw "Failed to process CSV data: $e";
    }

    var headers = rowsAsListOfValues.first.cast<String>();

    // check for duplicate headers
    if (_hasDuplicateHeaders(headers)) {
      throw "CSV file contains duplicate headers.";
    }

    return headers;
  }

  static bool _hasDuplicateHeaders(List<String> headers) {
    var headerSet = Set<String>();
    for (var header in headers) {
      if (headerSet.contains(header)) {
        return true;
      }
      headerSet.add(header);
    }
    return false;
  }
}


class CsvDelimiterDetector {
  static const List<String> commonDelimiters = [',', ';', '\t'];
  static const List<String> commonEOLs = ['\r\n', '\n'];

  static Map<String, String> detectDelimiterAndEol(String content) {
    String probableDelimiter = commonDelimiters.first;
    String probableEol = commonEOLs.first;

    int maxDelimiterCount = 0;
    for (var delimiter in commonDelimiters) {
      var count = _countOccurrences(content, delimiter);
      if (count > maxDelimiterCount) {
        maxDelimiterCount = count;
        probableDelimiter = delimiter;
      }
    }

    int maxEolCount = 0;
    for (var eol in commonEOLs) {
      var count = _countOccurrences(content, eol);
      if (count > maxEolCount) {
        maxEolCount = count;
        probableEol = eol;
      }
    }

    return {'delimiter': probableDelimiter, 'eol': probableEol};
  }

  static int _countOccurrences(String content, String pattern) {
    RegExp regExp = RegExp(pattern);
    return regExp.allMatches(content).length;
  }
}
