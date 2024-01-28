import 'dart:typed_data';

import 'package:cashbook/screens/csv_import_screen.dart';
import 'package:mobx/mobx.dart';

part 'csv_import_store.g.dart';

class CsvImportStore = _CsvImportStore with _$CsvImportStore;

abstract class _CsvImportStore with Store {
  @observable
  Map<String, String?> fieldMappings = {};

  @observable
  Map<String, MergeStrategy> mergeStrategy = {};

  @observable
  String? selectedFileName;

  @observable
  Uint8List? csvData;

  @action
  void init() {
    fieldMappings = {};
    mergeStrategy = {
      "description": MergeStrategy.fillEmpty,
      "recipientSender": MergeStrategy.fillEmpty,
      "date": MergeStrategy.fillEmpty,
      "paymentMethod": MergeStrategy.fillEmpty,
      "category": MergeStrategy.fillEmpty,
      "category_default": MergeStrategy.fillEmpty,
      "amount": MergeStrategy.fillEmpty,
      "isIncome": MergeStrategy.fillEmpty,
    };
    selectedFileName = null;
    csvData = null;
  }
}
