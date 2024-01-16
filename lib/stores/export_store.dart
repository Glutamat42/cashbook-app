import 'package:cashbook/models/export.dart';
import 'package:cashbook/repositories/export_repository.dart';
import 'package:cashbook/services/locator.dart';
import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';

part 'export_store.g.dart';

class ExportStore = _ExportStore with _$ExportStore;

abstract class _ExportStore with Store {
  final Logger _log = Logger('_ExportStore');
  final ExportRepository _exportRepository = locator<ExportRepository>();

  @observable
  List<Export>? exports;

  Future<void> createExport(bool exportDocuments, bool convertToJpeg) async {
    return await _exportRepository.createExport(exportDocuments, convertToJpeg);
  }

  /// Fetches the list of exports from the server.
  ///
  /// @param refresh If true, the list will be cleared initially and re-fetched from the server. Otherwise the list will be kept until the response from the server is received.
  @action
  Future<void> fetchExports({bool refresh = false}) async {
    if (refresh) {
      exports = null;
    }
    _log.fine('Fetching exports');
    List<Export> loadedExports = await _exportRepository.fetchExports();
    loadedExports.sort((a, b) => b.createdTimestamp.compareTo(a.createdTimestamp));
    exports = ObservableList<Export>.of(loadedExports);
  }
}
