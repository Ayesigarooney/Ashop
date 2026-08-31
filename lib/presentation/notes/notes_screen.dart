import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../features/notes/data/models/note_model.dart';
import '../../features/notes/presentation/bloc/note_cubit.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'add_edit_note_screen.dart';
import 'note_utils.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'General', 'Todo', 'Supplier', 'Customer', 'Idea'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Business Notes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'About Notes',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search notes by title or content...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<NoteCubit>().searchNotes('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (v) {
                context.read<NoteCubit>().searchNotes(v);
                setState(() {});
              },
            ),
          ),

          // Categories Filter Row
          SizedBox(
            height: 50,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      context.read<NoteCubit>().filterByCategory(cat == 'All' ? null : cat);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppTheme.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppTheme.darkText : AppTheme.lightText),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // Notes List
          Expanded(
            child: BlocBuilder<NoteCubit, NoteState>(
              builder: (context, state) {
                if (state is NoteLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is NoteLoaded) {
                  final notes = state.filtered;

                  if (notes.isEmpty) {
                    return EmptyState(
                      icon: Icons.note_alt_outlined,
                      title: _searchCtrl.text.isNotEmpty || _selectedCategory != 'All'
                          ? 'No matching notes'
                          : 'No business notes yet',
                      subtitle: _searchCtrl.text.isNotEmpty || _selectedCategory != 'All'
                          ? 'Try changing your search terms or filter category'
                          : 'Keep record of key supplier negotiations, customer requests, or quick task checklists.',
                      actionLabel: _searchCtrl.text.isEmpty && _selectedCategory == 'All'
                          ? 'Create a Note'
                          : null,
                      onAction: _searchCtrl.text.isEmpty && _selectedCategory == 'All'
                          ? () => _openNoteEditor(context)
                          : null,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final note = notes[index];
                      final colors = NoteUtils.getNoteColors(note.colorIndex, isDark);

                      return Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (dir) => _confirmDelete(context, note),
                        onDismissed: (_) {
                          context.read<NoteCubit>().deleteNote(note.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Note "${note.title.isNotEmpty ? note.title : 'Untitled'}" deleted'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () => _openNoteEditor(context, note: note),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors['bg'],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors['border']!, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // Left side accent indicator bar
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: 5,
                                    child: Container(color: colors['accent']),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                note.title.isNotEmpty ? note.title : 'Untitled Note',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (note.isPinned)
                                              Icon(
                                                Icons.push_pin_rounded,
                                                color: colors['accent'],
                                                size: 16,
                                              ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => _showQuickOptions(context, note),
                                              child: Icon(
                                                Icons.more_vert_rounded,
                                                color: (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub)
                                                    .withValues(alpha: 0.6),
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          note.content.isNotEmpty ? note.content : 'No additional text...',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            height: 1.4,
                                            color: (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Category Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: colors['accent']!.withValues(alpha: isDark ? 0.2 : 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: colors['accent']!.withValues(alpha: 0.3),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                note.category,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? colors['accent'] : colors['accent']!.darken(),
                                                ),
                                              ),
                                            ),
                                            // Timestamp
                                            Text(
                                              _formatNoteDate(note.updatedAt),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub)
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (state is NoteError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'notes_fab',
        onPressed: () => _openNoteEditor(context),
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'New Note',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openNoteEditor(BuildContext context, {NoteModel? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<NoteCubit>(),
          child: AddEditNoteScreen(note: note),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, NoteModel note) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete "${note.title.isNotEmpty ? note.title : 'this note'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showQuickOptions(BuildContext context, NoteModel note) {
    final noteCubit = context.read<NoteCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
                onTap: () {
                  noteCubit.togglePin(note);
                  Navigator.pop(sheetCtx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.blue),
                title: const Text('Share / Export as Text (.txt)'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  NoteUtils.exportAsTxt(context, note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                title: const Text('Print / Export as PDF (.pdf)'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  NoteUtils.exportAsPdf(context, note);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerColor),
                title: const Text('Delete Note'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final confirm = await _confirmDelete(context, note);
                  if (confirm == true) {
                    noteCubit.deleteNote(note.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNoteDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Business Notepad', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'Keep your thoughts organized. Categorize daily business tasks, supplier contacts, and client requirements. Notes are stored securely and encrypted locally.',
          style: GoogleFonts.inter(height: 1.5, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
