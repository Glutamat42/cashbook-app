import 'package:cashbook/repositories/export_repository.dart';
import 'package:cashbook/services/locator.dart';
import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';

part 'export_store.g.dart';

class ExportStore = _ExportStore with _$ExportStore;

abstract class _ExportStore with Store {
  final Logger _log = Logger('_ExportStore');
  final ExportRepository _exportRepository = locator<ExportRepository>();

  Future<void> createExport(bool exportDocuments, bool convertToJpeg) async {
    return await _exportRepository.createExport(exportDocuments, convertToJpeg);
  }
}
