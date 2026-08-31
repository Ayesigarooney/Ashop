import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';
import '../../../../core/config/constants.dart';

const _uuid = Uuid();

// States
abstract class NoteState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {}

class NoteLoading extends NoteState {}

class NoteLoaded extends NoteState {
  final List<NoteModel> notes;
  final List<NoteModel> filtered;
  final String searchQuery;
  final String? selectedCategory;

  NoteLoaded({
    required this.notes,
    List<NoteModel>? filtered,
    this.searchQuery = '',
    this.selectedCategory,
  }) : filtered = filtered ?? notes;

  NoteLoaded copyWith({
    List<NoteModel>? notes,
    List<NoteModel>? filtered,
    String? searchQuery,
    Object? selectedCategory = _sentinel,
  }) {
    return NoteLoaded(
      notes: notes ?? this.notes,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: identical(selectedCategory, _sentinel)
          ? this.selectedCategory
          : selectedCategory as String?,
    );
  }

  @override
  List<Object?> get props => [notes, filtered, searchQuery, selectedCategory];

  static const Object _sentinel = Object();
}

class NoteError extends NoteState {
  final String message;
  NoteError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class NoteCubit extends Cubit<NoteState> {
  final NoteRepository _repository;
  late final VoidCallback _boxListener;

  NoteCubit(this._repository) : super(NoteInitial()) {
    _boxListener = _onBoxChanged;
    Hive.box<dynamic>(
      AppConstants.notesBox,
    ).listenable().addListener(_boxListener);
  }

  void _onBoxChanged() {
    if (state is NoteLoaded) {
      try {
        final notes = _repository.getAllNotes();
        final current = state as NoteLoaded;
        _filterAndEmit(notes, current.searchQuery, current.selectedCategory);
      } catch (_) {
        // Reload instead of failing silently so the UI never shows stale data
        loadNotes();
      }
    } else {
      loadNotes();
    }
  }

  @override
  Future<void> close() {
    // Must use the same box type as registration, otherwise removeListener is a no-op
    // and the listener leaks on every close().
    Hive.box<dynamic>(
      AppConstants.notesBox,
    ).listenable().removeListener(_boxListener);
    return super.close();
  }

  void loadNotes() {
    emit(NoteLoading());
    try {
      final notes = _repository.getAllNotes();
      emit(NoteLoaded(notes: notes));
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  void searchNotes(String query) {
    if (state is NoteLoaded) {
      final current = state as NoteLoaded;
      _filterAndEmit(current.notes, query, current.selectedCategory);
    }
  }

  void filterByCategory(String? category) {
    if (state is NoteLoaded) {
      final current = state as NoteLoaded;
      _filterAndEmit(current.notes, current.searchQuery, category);
    }
  }

  void _filterAndEmit(
    List<NoteModel> allNotes,
    String searchQuery,
    String? category,
  ) {
    List<NoteModel> filtered = allNotes;

    // Filter by category
    if (category != null && category != 'All') {
      filtered = filtered
          .where((n) => n.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (n) =>
                n.title.toLowerCase().contains(q) ||
                n.content.toLowerCase().contains(q),
          )
          .toList();
    }

    emit(
      NoteLoaded(
        notes: allNotes,
        filtered: filtered,
        searchQuery: searchQuery,
        selectedCategory: category,
      ),
    );
  }

  Future<void> addNote({
    required String title,
    required String content,
    required String category,
    required int colorIndex,
    bool isPinned = false,
  }) async {
    try {
      final now = DateTime.now();
      final note = NoteModel(
        id: _uuid.v4(),
        title: title,
        content: content,
        category: category,
        colorIndex: colorIndex,
        createdAt: now,
        updatedAt: now,
        isPinned: isPinned,
      );
      await _repository.saveNote(note);
      loadNotes();
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      final updated = note.copyWith(updatedAt: DateTime.now());
      await _repository.saveNote(updated);
      loadNotes();
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> togglePin(NoteModel note) async {
    try {
      final updated = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      await _repository.saveNote(updated);
      loadNotes();
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      loadNotes();
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }
}
