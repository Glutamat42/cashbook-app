import 'dart:convert';
import 'dart:typed_data';
import 'package:cashbook/models/entry.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/category_store.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class CsvParser {
  static final Logger log = Logger('CsvParser');

  static String determineDateFormat(List<String> dates) {
    if (dates.isEmpty) {
      throw "The date list is empty.";
    }

    final RegExp separatorExp = RegExp(r'(\D)');
    final separatorMatch = separatorExp.firstMatch(dates.first);

    if (separatorMatch == null) {
      throw "Unsupported or missing separation symbol in dates.";
    }

    String separationSymbol = separatorMatch.group(1)!;
    List<String> firstDateParts = dates.first.split(separationSymbol);
    if (firstDateParts.length != 3) {
      throw "Invalid date format, ${dates.first} does not contain 3 parts.";
    }

    // get year index
    int yearIndex = firstDateParts.indexWhere((part) => part.length == 4);
    if (yearIndex == -1) {
      log.warning("Could not find year with 4 digits, falling back to default.");
      yearIndex = 2;
    }

    // set defaults for month and day based on year index and separation symbol
    int monthIndex = (yearIndex + 1) % 3;
    int dayIndex = (yearIndex + 2) % 3;
    if (yearIndex == 2 && separationSymbol != "-") {
      monthIndex = 1;
      dayIndex = 0;
    }

    // use heuristics to determine correct month and day index
    for (String date in dates) {
      bool done = false;
      List<String> dateParts = date.split(separationSymbol);
      if (dateParts.length != 3) {
        throw "Invalid date format, $date does not contain 3 parts.";
      }
      for (int index in [monthIndex, dayIndex]) {
        if (dateParts[index].length > 2) {
          throw "Invalid date format, $date contains more than 2 digits where the day or month is expected.";
        }
        if (int.parse(dateParts[index]) > 12) {
          dayIndex = index;
          monthIndex = 3 - yearIndex - dayIndex;
          done = true;
          log.info("Found day index by value > 12");
          break;
        }
      }
      if (done) {
        break;
      }
    }

    String dateFormat = "";
    for (int i = 0; i < 3; i++) {
      if (i == yearIndex) {
        dateFormat += "yyyy";
      } else if (i == monthIndex) {
        dateFormat += "MM";
      } else if (i == dayIndex) {
        dateFormat += "dd";
      } else {
        throw "Invalid date format";
      }
      if (i < 2) {
        dateFormat += separationSymbol;
      }
    }

    log.info("Detected date format: $dateFormat");
    return dateFormat;
  }

  static List<Entry> loadEntriesFromCsv(Uint8List data, Map<String, String?> fieldMappings) {
    CategoryStore categoryStore = locator<CategoryStore>();
    var (headers, dataRows) = processCsv(data, includeData: true);
    var entries = <Entry>[];

    // get column indices
    int descriptionIndex = headers.indexOf(fieldMappings['description']!);
    int recipientSenderIndex = headers.indexOf(fieldMappings['recipientSender']!);
    int dateIndex = headers.indexOf(fieldMappings['date']!);
    int? categoryIndex = fieldMappings['category'] != null ? headers.indexOf(fieldMappings['category']!) : null;
    int amountIndex = headers.indexOf(fieldMappings['amount']!);

    // parse date by trying multiple formats
    String dateFormatString = determineDateFormat(dataRows!.map((row) => row[dateIndex]).toList());

    for (var row in dataRows) {
      DateTime date = DateFormat(dateFormatString).parse(row[dateIndex]);
      bool isIncome = (fieldMappings['isIncome'] == "Positive amount as Income" && !row[amountIndex].startsWith('-')) ||
          (fieldMappings['isIncome'] == "Negative amount as Income" && row[amountIndex].startsWith('-'));

      int categoryId = -1;
      if (categoryIndex != null && row[categoryIndex].isNotEmpty) {
        if (categoryStore.getCategoryIdByName(row[categoryIndex]) == null) {
          log.warning('Category "${row[categoryIndex]}" does not exist, falling back to default category.');
          // categoryStore.createCategory(row[categoryIndex]);
        } else {
          categoryId = categoryStore.getCategoryIdByName(row[categoryIndex])!;
        }
      } else {
        log.info('Using default category.');
        if (categoryStore.getCategoryIdByName(fieldMappings['category_default']!) == null) {
          throw "Default category does not exist.";
        }
        categoryId = categoryStore.getCategoryIdByName(fieldMappings['category_default']!)!;
      }

      entries.add(Entry(
          description: row[descriptionIndex],
          recipientSender: row[recipientSenderIndex],
          date: date,
          paymentMethod: fieldMappings['paymentMethod_default']!,
          categoryId: categoryId,
          amount: (double.parse(row[amountIndex].replaceAll(',', '.')) * 100).toInt().abs(),
          isIncome: isIncome));
    }
    return entries;
  }

  static (List<String>, List<List<String>>?) processCsv(Uint8List data, {includeData = false}) {
    String rawCsv;
    try {
      rawCsv = utf8.decode(data);
      log.info('CSV file decoded with UTF-8.');
    } on FormatException catch (fe) {
      log.info('UTF-8 decoding failed, trying ISO-8859-1. Error: ${fe.message}');
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

    if (rowsAsListOfValues.length < 2) {
      throw "invalid CSV file: less than 2 rows (header + at least 1 data row).";
    }

    List<String> headers = rowsAsListOfValues.first.cast<String>();

    // check for duplicate headers
    if (_hasDuplicateHeaders(headers)) {
      throw "CSV file contains duplicate headers.";
    }

    List<List<String>>? dataRows;
    if (includeData) {
      dataRows = rowsAsListOfValues.sublist(1).map((row) => row.cast<String>()).toList();
    }

    return (headers, dataRows);
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
