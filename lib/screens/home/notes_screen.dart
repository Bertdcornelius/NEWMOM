import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../services/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/premium_ui_components.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  List<MomNote> _notes = [];
  List<MomNote> _filteredNotes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);

    final service = context.read<SupabaseService>();
    final data = await service.getNotes();
    
    if (mounted) {
      setState(() {
        _notes = data.map((e) => MomNote.fromJson(e)).toList();
        _filteredNotes = _notes;
        _isLoading = false;
      });
    }
    // Note: Ad wall is handled by Dashboard navigation
  }

  void _addNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
              ),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                  final authService = context.read<SupabaseService>();
                  final user = authService.currentUser;
                  if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No user logged in")));
                      return;
                  }

                  final newNote = MomNote(
                    id: Uuid().v4(),
                    userId: user.id,
                    title: titleController.text.isEmpty ? "Untitled Note" : titleController.text,
                    content: contentController.text,
                    tags: tagsController.text.split(',').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toList(),
                    createdAt: DateTime.now(),
                  );

                  await authService.saveNote(newNote.toJson());
                  
                  if (context.mounted) {
                      _fetchNotes();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note Saved!")));
                  }
              } catch (e) {
                  if (context.mounted) {
                      print("Save Error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
                  }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _filterNotes(String query) {
    if (query.isEmpty) {
      setState(() => _filteredNotes = _notes);
      return;
    }

    setState(() {
      _filteredNotes = _notes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(query.toLowerCase());
        final contentMatch = note.content.toLowerCase().contains(query.toLowerCase());
        final tagsMatch = note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        return titleMatch || contentMatch || tagsMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      
      appBar: AppBar(
        title: Text("Mom's Brain", style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search notes, tags...',
                labelStyle: PremiumTypography(context).body,
                prefixIcon: Icon(Icons.search_rounded, color: PremiumColors(context).textSecondary),
                filled: true,
                fillColor: PremiumColors(context).surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: _filterNotes,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: PremiumColors(context).gentlePurple))
                : _filteredNotes.isEmpty
                    ? Center(child: Text("No notes found. Add one!", style: PremiumTypography(context).body))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: DataTile(
                              onTap: () => _showOptions(note),
                              backgroundColor: PremiumColors(context).surface,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PremiumBubbleIcon(icon: Icons.psychology_rounded, color: PremiumColors(context).gentlePurple, size: 24, padding: 12),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(note.title, style: PremiumTypography(context).title),
                                        const SizedBox(height: 4),
                                        Text(note.content, style: PremiumTypography(context).body, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        if (note.tags.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              children: note.tags.map((t) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: PremiumColors(context).gentlePurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                                child: Text(t, style: TextStyle(fontSize: 10, color: PremiumColors(context).gentlePurple, fontWeight: FontWeight.bold)),
                                              )).toList(),
                                            )
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: PremiumColors(context).gentlePurple,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showOptions(MomNote note) {
      showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      ListTile(
                          leading: Icon(Icons.edit, color: Theme.of(context).brightness == Brightness.dark ? Colors.lightBlue : Colors.blue),
                          title: Text('Edit'),
                          onTap: () {
                              Navigator.pop(context);
                              _editNote(note);
                          },
                      ),
                      ListTile(
                          leading: Icon(Icons.delete, color: Theme.of(context).brightness == Brightness.dark ? Colors.redAccent : Colors.red),
                          title: Text('Delete Note'),
                          onTap: () {
                              Navigator.pop(context);
                              _confirmDelete(note.id);
                          },
                      ),
                  ],
              ),
          ),
      );
  }

  void _editNote(MomNote note) {
      final titleController = TextEditingController(text: note.title);
      final contentController = TextEditingController(text: note.content);
      final tagsController = TextEditingController(text: note.tags.join(', '));

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text('Edit Note'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                          TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
                          TextField(controller: tagsController, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
                      ],
                  ),
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                  TextButton(
                      onPressed: () async {
                          final authService = context.read<SupabaseService>();
                          if (titleController.text.isNotEmpty) {
                              final updates = {
                                  'title': titleController.text,
                                  'content': contentController.text,
                                  'tags': tagsController.text.split(',').map((e) => e.trim()).toList(),
                              };
                              await authService.updateNote(note.id, updates);
                              
                              if (mounted) {
                                  _fetchNotes();
                                  Navigator.pop(context);
                              }
                          }
                      }, 
                      child: Text('Save'),
                  ),
              ],
          ),
      );
  }

  void _confirmDelete(String id) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text("Delete Note"),
              content: Text("Are you sure?"),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                  TextButton(
                      onPressed: () async {
                          final authService = context.read<SupabaseService>();
                          await authService.deleteNote(id);
                          if (mounted) {
                              Navigator.pop(context);
                              _fetchNotes();
                          }
                      }, 
                      child: Text("Delete", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.redAccent : Colors.red))
                  ),
              ],
          ),
      );
  }
}
