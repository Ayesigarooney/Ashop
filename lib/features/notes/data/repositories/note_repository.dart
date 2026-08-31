import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';
import '../../../../core/config/constants.dart';

class NoteRepository {
  Box<dynamic> get _box => Hive.box<dynamic>(AppConstants.notesBox);

  List<NoteModel> getAllNotes() {
    try {
      final maps = _box.values.toList();
      return maps
          .whereType<Map>()
          .map((m) => NoteModel.fromMap(m))
          .toList()
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNote(NoteModel note) async {
    await _box.put(note.id, note.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
