import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';
import '../models/entry.dart';
import '../repositories/entries_repository.dart';
import '../services/locator.dart';

part 'entry_store.g.dart';

class EntryStore = _EntryStore with _$EntryStore;

abstract class _EntryStore with Store {
  final Logger _logger = Logger('EntryStore');
  final EntriesRepository _entriesRepository = locator<EntriesRepository>();

  @observable
  ObservableList<Entry> entries = ObservableList<Entry>();

  @action
  Future<void> loadEntries() async {
    try {
      final fetchedEntries = await _entriesRepository.getEntries();
      entries = ObservableList<Entry>.of(fetchedEntries);
    } catch (e) {
      _logger.severe('Failed to load entries: $e');
    }
  }

  @action
  Future<void> createEntry(Entry entry) async {
    try {
      final newEntry = await _entriesRepository.createEntry(entry.toJson());
      entries.add(newEntry);
    } catch (e) {
      // Handle errors
    }
  }

  @action
  Future<void> updateEntry(Entry updatedEntry) async {
    try {
      final entry = await _entriesRepository.updateEntry(updatedEntry.id, updatedEntry.toJson());
      final index = entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        entries[index] = entry;
      }
    } catch (e) {
      // Handle errors
    }
  }

  @action
  Future<void> deleteEntry(int entryId) async {
    try {
      await _entriesRepository.deleteEntry(entryId);
      entries.removeWhere((entry) => entry.id == entryId);
    } catch (e) {
      // Handle errors
    }
  }
}
