import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';
import '../models/document.dart';
import '../models/entry.dart';
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

  @observable
  ObservableMap<int, ObservableList<Document>> entryDocuments = ObservableMap<int, ObservableList<Document>>();

  @observable
  SortField currentSortField = SortField.date;

  @observable
  SortOrder currentSortOrder = SortOrder.ascending;

  @observable
  Map<FilterField, dynamic> currentFilters = {};

  @action
  Future<void> loadDocumentsForEntry(int entryId) async {
    try {
      var docs = await _documentsRepository.getDocumentsByEntryId(entryId);
      entryDocuments[entryId] = ObservableList<Document>.of(docs);
    } catch (e) {
      _logger.severe('Failed to load documents for entry $entryId: $e');
    }
  }

  @action
  Future<Entry> createEntry(Entry newEntry) async {
    try {
      final createdEntry = await _entriesRepository.createEntry(newEntry.toJson());
      visibleEntries.add(createdEntry);
      return createdEntry;
    } catch (e) {
      _logger.severe('Failed to create entry: $e');
      throw Exception('Failed to create entry');
    }
  }

  ObservableList<Document> getDocumentsForEntry(int entryId) =>
      entryDocuments[entryId] != null ? entryDocuments[entryId]! : ObservableList<Document>.of([]);

  @action
  Future<void> loadEntries() async {
    try {
      allEntries = await _entriesRepository.getEntries();
    } catch (e) {
      _logger.severe('Failed to load entries: $e');
    }

    _applyFilterAndSort();
  }

  @action
  Future<void> createEntry(Entry entry) async {
    try {
      final newEntry = await _entriesRepository.createEntry(entry.toJson());
      visibleEntries.add(newEntry);
    } catch (e) {
      // Handle errors
    }
  }

  @action
  Future<Entry> updateEntry(Entry updatedEntry) async {
    int oldEntryId = updatedEntry.id;
    try {
      final entry = await _entriesRepository.updateEntry(updatedEntry.id, updatedEntry.toJson());
      final index = visibleEntries.indexWhere((e) => e.id == oldEntryId);
      if (index != -1) {
        visibleEntries.replaceRange(index, index + 1, [entry]);
        _applyFilterAndSort();
      }
      return entry;
    } catch (e) {
      _logger.severe('Failed to update entry: $e');
      throw Exception('Failed to update entry');
    }
  }

  @action
  Future<void> deleteEntry(int entryId) async {
    try {
      await _entriesRepository.deleteEntry(entryId);
      visibleEntries.removeWhere((entry) => entry.id == entryId);
    } catch (e) {
      // Handle errors
    }
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
        compare = (Entry a, Entry b) => a.amount.compareTo(b.amount);
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
      // TODO
      // filteredEntries = filteredEntries.where((entry) => entry.noInvoice && entry.documentId == null).toList();
      filteredEntries = filteredEntries.where((entry) => entry.noInvoice == false).toList();
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
}
