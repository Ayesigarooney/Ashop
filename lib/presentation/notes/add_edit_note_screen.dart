import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../features/notes/data/models/note_model.dart';
import '../../features/notes/presentation/bloc/note_cubit.dart';
import 'note_utils.dart';

class AddEditNoteScreen extends StatefulWidget {
  final NoteModel? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = 'General';
  int _colorIndex = 0;
  bool _isPinned = false;

  final List<String> _categories = [
    'General',
    'Todo',
    'Supplier',
    'Customer',
    'Idea',
  ];
  final List<Color> _paletteColors = [
    AppTheme.primaryColor, // 0: Purple / General
    AppTheme.accentColor, // 1: Teal / Customer
    AppTheme.warningColor, // 2: Yellow / Todo
    AppTheme.dangerColor, // 3: Red / Idea
    const Color(0xFF7F8C8D), // 4: Slate / Supplier
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleCtrl.text = widget.note!.title;
      _contentCtrl.text = widget.note!.content;
      _category = widget.note!.category;
      _colorIndex = widget.note!.colorIndex;
      _isPinned = widget.note!.isPinned;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      context.read<NoteCubit>().addNote(
        title: title,
        content: content,
        category: _category,
        colorIndex: _colorIndex,
        isPinned: _isPinned,
      );
    } else {
      final updated = widget.note!.copyWith(
        title: title,
        content: content,
        category: _category,
        colorIndex: _colorIndex,
        isPinned: _isPinned,
      );
      context.read<NoteCubit>().updateNote(updated);
    }

    Navigator.pop(context);
  }

  void _deleteNote() {
    if (widget.note != null) {
      // Capture the messenger before popping so the SnackBar survives navigation
      final messenger = ScaffoldMessenger.of(context);
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<NoteCubit>().deleteNote(widget.note!.id);
                Navigator.pop(dialogCtx); // Dialog
                Navigator.pop(context); // Screen
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = NoteUtils.getNoteColors(_colorIndex, isDark);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: colors['bg'],
        appBar: AppBar(
          backgroundColor: colors['bg'],
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned
                    ? colors['accent']
                    : (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
              ),
              tooltip: _isPinned ? 'Unpin' : 'Pin',
              onPressed: () {
                setState(() => _isPinned = !_isPinned);
              },
            ),
            IconButton(
              icon: Icon(Icons.check_rounded, color: colors['accent']),
              tooltip: 'Save',
              onPressed: _saveNote,
            ),
            if (widget.note != null)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final currentNote = widget.note!.copyWith(
                    title: _titleCtrl.text.trim(),
                    content: _contentCtrl.text.trim(),
                    category: _category,
                    colorIndex: _colorIndex,
                    isPinned: _isPinned,
                  );

                  if (value == 'txt') {
                    await NoteUtils.exportAsTxt(context, currentNote);
                  } else if (value == 'pdf') {
                    await NoteUtils.exportAsPdf(context, currentNote);
                  } else if (value == 'delete') {
                    _deleteNote();
                  }
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'txt',
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Share as TXT'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text('Share / Print as PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.dangerColor,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete Note',
                          style: TextStyle(color: AppTheme.dangerColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Borderless Title Input
                    TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note Title',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color:
                              (isDark
                                      ? AppTheme.darkTextSub
                                      : AppTheme.lightTextSub)
                                  .withValues(alpha: 0.4),
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 12),

                    // Category selector bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _category == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _category = cat;
                                  // Update color index to match category
                                  if (cat == 'General') _colorIndex = 0;
                                  if (cat == 'Customer') _colorIndex = 1;
                                  if (cat == 'Todo') _colorIndex = 2;
                                  if (cat == 'Idea') _colorIndex = 3;
                                  if (cat == 'Supplier') _colorIndex = 4;
                                });
                              },
                              child: Chip(
                                label: Text(cat),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppTheme.darkTextSub
                                            : AppTheme.lightTextSub),
                                ),
                                backgroundColor: isSelected
                                    ? colors['accent']
                                    : (isDark
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : Colors.white.withValues(
                                              alpha: 0.5,
                                            )),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : colors['border']!.withValues(
                                          alpha: 0.5,
                                        ),
                                  width: 0.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Borderless Content Input
                    TextField(
                      controller: _contentCtrl,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        height: 1.5,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing your business notes here...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.5,
                          color:
                              (isDark
                                      ? AppTheme.darkTextSub
                                      : AppTheme.lightTextSub)
                                  .withValues(alpha: 0.4),
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      autofocus: widget.note == null && _titleCtrl.text.isEmpty,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Style Palette bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.45),
                border: Border(
                  top: BorderSide(
                    color: colors['border']!.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Note Style:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextSub
                          : AppTheme.lightTextSub,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _paletteColors.length,
                        itemBuilder: (context, index) {
                          final color = _paletteColors[index];
                          final isSelected = _colorIndex == index;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _colorIndex = index);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : colors['border']!,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
