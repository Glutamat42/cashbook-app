import 'dart:io';

import 'package:cashbook/models/remote_document.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';
import 'package:path_provider/path_provider.dart';
import '../models/document.dart';
import '../models/entry.dart';
import '../models/local_document.dart';
import '../repositories/documents_repository.dart';
import '../repositories/entries_repository.dart';
import '../services/locator.dart';

part 'entry_store.g.dart';

enum SortField { date, amount, recipient }

enum SortOrder { ascending, descending }

enum FilterField { category, invoiceMissing, searchText }

class EntryStore = _EntryStore with _$EntryStore;

abstract class _EntryStore with Store {
  final Logger _logger = Logger('EntryStore');
  final EntriesRepository _entriesRepository = locator<EntriesRepository>();
  final DocumentsRepository _documentsRepository = locator<DocumentsRepository>();

  @observable
  ObservableList<Entry> visibleEntries = ObservableList<Entry>();

  List<Entry> allEntries = <Entry>[];

  List<LocalDocument>? intentDocuments;

  @observable
  ObservableMap<int, ObservableList<Document>> entryDocuments = ObservableMap<int, ObservableList<Document>>();

  @observable
  SortField currentSortField = SortField.date;

  @observable
  SortOrder currentSortOrder = SortOrder.ascending;

  @observable
  Map<FilterField, dynamic> currentFilters = {};

  @action
  Future<ObservableList<Document>> loadDocumentsForEntry(int entryId) async {
    try {
      List<RemoteDocument> docs = await _documentsRepository.getDocumentsByEntryId(entryId);
      entryDocuments[entryId] = ObservableList<Document>.of(docs.reversed);
    } catch (e) {
      _logger.severe('Failed to load documents for entry $entryId: $e');
      entryDocuments[entryId] = ObservableList<Document>.of([]);
    }
    return entryDocuments[entryId]!;
  }

  /// Same as loadDocumentsForEntry but deletes all documents (including local) before loading
  @action
  Future<ObservableList<Document>> refreshDocumentsForEntry(int entryId) async {
    entryDocuments[entryId] = ObservableList<Document>.of([]);
    return loadDocumentsForEntry(entryId);
  }

  @action
  Future<Entry> createEntry(Entry newEntry, List<Document> documents) async {
    try {
      final createdEntry = await _entriesRepository.createEntry(newEntry, documents);
      allEntries.add(createdEntry);
      visibleEntries.add(createdEntry);
      _applyFilterAndSort();
      return createdEntry;
    } on DioException catch (e) {
      _logger.warning('Failed to create entry: ${e.message}');
      throw Exception('Failed to create entry');
    } on Exception catch (e) {
      _logger.warning('Non Dio Error occured, likely failed to process response: ${e.toString()}';
      throw Exception('Failed processing entry, possibly the entry was created but received an invalid response');
    }
  }

  @action
  Future<Entry> updateEntry(Entry updatedEntry, List<Document> documents) async {
    try {
      final entry = await _entriesRepository.updateEntry(updatedEntry.id!, updatedEntry, documents);
      final index = visibleEntries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        allEntries.replaceRange(index, index + 1, [entry]);
        visibleEntries.replaceRange(index, index + 1, [entry]);
      }
      _applyFilterAndSort();
      _cleanupDocumentCache(entryId: entry.id);
      return entry;
    } catch (e) {
      _logger.severe('Failed to update entry: $e');
      throw Exception('Failed to update entry');
    }
  }

  ObservableList<Document> getDocumentsForEntry(int entryId) =>
      entryDocuments[entryId] != null ? entryDocuments[entryId]! : ObservableList<Document>.of([]);

  @action
  Future<void> loadDocuments() async {
    try {
      final docs = await _documentsRepository.getAll();
      entryDocuments = ObservableMap<int, ObservableList<Document>>.of({
        for (var d in docs.reversed) d.entryId!: ObservableList<Document>.of([d])
      });

      _cleanupDocumentCache();
    } catch (e) {
      _logger.severe('Failed to load documents: $e');
    }
  }

  _cleanupDocumentCache({int? entryId}) async {
    if (!kIsWeb) {
      // Only clean up the document cache on mobile
      _logger.info('Cleaning up document cache');
      try {
        // Obtain the temporary directory
        final tempDir = await getApplicationCacheDirectory();
        final documentCacheDir = Directory('${tempDir.path}/documents');

        if (!documentCacheDir.existsSync()) {
          return; // If the cache directory doesn't exist, nothing to clean
        }

        // For all entries
        final cacheDirList = Directory('${documentCacheDir.path}/').listSync();
        final existingEntryIds = allEntries.map((entry) => entry.id).toSet();
        for (var dir in cacheDirList) {
          if (dir is Directory) {
            final dirName = dir.path.split('/').last;
            final dirEntryId = int.tryParse(dirName);

            if (dirEntryId == null) {
              _logger.warning('Found invalid directory in document cache: $dirName, deleting it');
              dir.delete(recursive: true);
              continue;
            }
            if (dirEntryId != entryId) {
              // Cleanup only for specific entryId, this is not it
              continue;
            }
            if (!existingEntryIds.contains(dirEntryId)) {
              _logger.info('Found orphaned directory in document cache: $dirName, deleting it');
              dir.delete(recursive: true);
              continue;
            }
            // now the only case left is that the entry still exists and it's cache content has to be cleaned up
            _cleanupDocumentsForEntry(dirEntryId, dir);
          } else {
            // not a dir, should not be here -> delete
            await dir.delete();
          }
        }
      } catch (e) {
        _logger.severe('Failed to cleanup document cache: $e');
      }
    } else {
      _logger.info('Skipping document cache cleanup on web');
    }
  }

  Future<void> _cleanupDocumentsForEntry(int entryId, Directory documentCacheDir) async {
    final existingDocumentIds = entryDocuments[entryId]?.map((doc) => doc.id).toSet() ?? <int>{};
    final cachedFiles = Directory('${documentCacheDir.path}/documents/$entryId').listSync();

    for (var dir in cachedFiles) {
      final dirName = dir.path.split('/').last;
      final cachedDocumentId = int.tryParse(dirName);

      if (!existingDocumentIds.contains(cachedDocumentId)) {
        await dir.delete(recursive: true);
      }
    }
  }

  @action
  Future<void> loadEntries() async {
    Future loadDocumentFuture = loadDocuments();
    try {
      allEntries = await _entriesRepository.getEntries();
    } catch (e) {
      _logger.severe('Failed to load entries: $e');
    }

    _applyFilterAndSort();
    await loadDocumentFuture;
  }

  @action
  Future<void> deleteEntry(int entryId) async {
    await _entriesRepository.deleteEntry(entryId);
    allEntries.removeWhere((entry) => entry.id == entryId);
    visibleEntries.removeWhere((entry) => entry.id == entryId);
    _cleanupDocumentCache(entryId: entryId);
  }

  @action
  void sortEntries(SortField field, SortOrder order) {
    List<Entry> sortedList = _sortEntries(allEntries, field, order);

    visibleEntries = ObservableList<Entry>.of(sortedList); // resorting is enough here

    currentSortField = field;
    currentSortOrder = order;
  }

  @action
  void applyFilters([Map<FilterField, dynamic>? newFilters]) {
    if (newFilters != null) {
      currentFilters = newFilters;
    }

    _applyFilterAndSort(); // as new filters are applied and therefore new items might be visible, we need to resort
  }

  @action
  _applyFilterAndSort() {
    List<Entry> filteredEntries = _applyFilters(allEntries, currentFilters);
    List<Entry> sortedEntries = _sortEntries(filteredEntries, currentSortField, currentSortOrder);
    visibleEntries = ObservableList<Entry>.of(sortedEntries);
  }

  List<Entry> _sortEntries(List<Entry> sourceList, SortField field, SortOrder order) {
    int Function(Entry, Entry) compare;

    switch (field) {
      case SortField.date:
        compare = (Entry a, Entry b) => a.date.compareTo(b.date);
        break;
      case SortField.amount:
        compare = (Entry a, Entry b) => (a.amount ?? 0).compareTo(b.amount ?? 0);
        break;
      case SortField.recipient:
        compare = (Entry a, Entry b) => a.recipientSender.compareTo(b.recipientSender);
        break;
    }

    if (order == SortOrder.descending) {
      sourceList.sort((a, b) => compare(b, a));
    } else {
      sourceList.sort(compare);
    }

    return sourceList;
  }

  List<Entry> _applyFilters(List<Entry> sourceList, Map<FilterField, dynamic>? newFilters) {
    var filteredEntries = sourceList; // Assuming this holds all entries

    // Filter by Category
    if (currentFilters.containsKey(FilterField.category)) {
      if (currentFilters[FilterField.category] == null) {
        filteredEntries = filteredEntries;
      } else {
        int categoryId = currentFilters[FilterField.category];
        filteredEntries = filteredEntries.where((entry) => entry.categoryId == categoryId).toList();
      }
    }

    // Filter for missing invoice
    if (currentFilters.containsKey(FilterField.invoiceMissing) && currentFilters[FilterField.invoiceMissing]) {
      // Filter for: where noInvoice == false and no documents exist (in entryDocuments)
      List<Entry> entriesRequiringDocuments = filteredEntries.where((entry) => !entry.noInvoice).toList();
      filteredEntries = entriesRequiringDocuments
          .where((entry) => entryDocuments[entry.id] == null || entryDocuments[entry.id]!.isEmpty)
          .toList();
    }

    // Filter by search text
    if (currentFilters.containsKey(FilterField.searchText) && currentFilters[FilterField.searchText] != null) {
      String searchText = currentFilters[FilterField.searchText].toLowerCase();
      filteredEntries = filteredEntries
          .where((entry) =>
              entry.recipientSender.toLowerCase().contains(searchText) ||
              entry.description.toLowerCase().contains(searchText))
          .toList();
    }

    return filteredEntries;
  }

  @action
  Future<void> onLogout() async {
    allEntries.clear();
    visibleEntries.clear();
    entryDocuments.clear;
  }
}
