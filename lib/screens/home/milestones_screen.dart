import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/milestone_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../core/result.dart';
import 'package:intl/intl.dart';
import '../../widgets/premium_ui_components.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  List<Milestone> _milestones = [];
  bool _isLoading = false;

  // Predefined suggestions
  final List<String> _suggestions = [
    "First Smile",
    "Rolled Over",
    "Sat Up",
    "First Tooth",
    "Crawled",
    "First Step",
    "First Word",
  ];

  @override
  void initState() {
    super.initState();
    _fetchMilestones();
  }

  Future<void> _fetchMilestones() async {
    setState(() => _isLoading = true);

    final service = context.read<CareRepository>();
    final data = (await service.getMilestones()).data ?? [];

    if (mounted) {
      setState(() {
        _milestones = data.map((e) => Milestone.fromJson(e)).toList();
        _isLoading = false;
      });
    }
    // Note: Ad wall is handled by Dashboard navigation
  }

  void _addMilestone() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;
    String? selectedImageUrl;
    bool isUploadingPhoto = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: PremiumColors(context).surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('New Milestone', style: PremiumTypography(context).h2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Milestone Title',
                    labelStyle: PremiumTypography(context).body,
                    filled: true,
                    fillColor: PremiumColors(context).surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                    child: Text('Suggestions:',
                        style: PremiumTypography(context).body)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _suggestions
                      .map((s) => ActionChip(
                            label: Text(s,
                                style: PremiumTypography(context).bodyBold),
                            backgroundColor: PremiumColors(context)
                                .softAmber
                                .withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide.none),
                            onPressed: () =>
                                setDialogState(() => titleController.text = s),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text("Date: ${_formatDate(selectedDate)}",
                        style: PremiumTypography(context).title),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Text('Change',
                          style: PremiumTypography(context).bodyBold.copyWith(
                              color: PremiumColors(context).sereneBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Photo Section
                DataTile(
                  onTap: isUploadingPhoto
                      ? null
                      : () async {
                          setDialogState(() => isUploadingPhoto = true);
                          try {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              // Upload image
                              final service = context.read<CareRepository>();
                              final authService = context.read<AuthRepository>();
                              final user = authService.currentUser;
                              if (user != null) {
                                final bytes = await image.readAsBytes();
                                final uploadRes = await service.uploadImage(
                                    user.id, image.name, bytes);
                                if (uploadRes is Success) {
                                  setDialogState(() => selectedImageUrl = uploadRes.data);
                                }
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Failed to pick/upload photo')));
                            }
                          } finally {
                            setDialogState(() => isUploadingPhoto = false);
                          }
                        },
                  child: Row(
                    children: [
                      PremiumBubbleIcon(
                          icon: Icons.photo_camera_rounded,
                          color: selectedImageUrl != null
                              ? Colors.green
                              : PremiumColors(context).softAmber,
                          size: 24,
                          padding: 12),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                selectedImageUrl == null
                                    ? "Add Photo"
                                    : "Photo Selected ✓",
                                style: PremiumTypography(context).title),
                          ])),
                      if (isUploadingPhoto)
                        SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: PremiumColors(context).softAmber,
                                strokeWidth: 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: Text('Cancel',
                    style: PremiumTypography(context).bodyBold.copyWith(
                        color: PremiumColors(context).textSecondary))),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final authService = context.read<AuthRepository>();
                      final repo = context.read<CareRepository>();
                      final user = authService.currentUser;
                      if (user == null) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in. Please sign in first.'), backgroundColor: Colors.red));
                        return;
                      }

                      final titleStr = titleController.text.trim();
                      if (titleStr.isEmpty) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a milestone title.')));
                        return;
                      }
                      if (titleStr.length > 50) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title cannot exceed 50 characters.')));
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        final newItem = Milestone(
                          id: const Uuid().v4(),
                          userId: user.id,
                          title: titleStr,
                          date: selectedDate,
                          imageUrl: selectedImageUrl,
                          createdAt: DateTime.now(),
                        );

                        await repo.saveMilestone(newItem.toJson());

                        if (mounted) {
                          await _fetchMilestones();
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        // Suppress print in production
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PremiumColors(context).softAmber))
                  : Text('Save',
                      style: PremiumTypography(context)
                          .bodyBold
                          .copyWith(color: PremiumColors(context).softAmber)),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumColors(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Using Milestones", style: PremiumTypography(context).h2),
        content: Text(
            "Track your baby's big moments here!\n\nExamples: First smile, first step, first word. You can look back at these memories later.",
            style: PremiumTypography(context).body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Got it",
                  style: PremiumTypography(context)
                      .bodyBold
                      .copyWith(color: PremiumColors(context).softAmber)))
        ],
      ),
    );
  }

  Future<void> _deleteMilestone(String id) async {
    await context.read<CareRepository>().deleteMilestone(id);
    setState(() {
      _milestones.removeWhere((item) => item.id == id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }

  void _showOptions(Milestone item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
            color: PremiumColors(context).surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(3)),
                margin: const EdgeInsets.only(bottom: 16),
              )),
              ListTile(
                leading: PremiumBubbleIcon(
                    icon: Icons.edit_rounded,
                    color: PremiumColors(context).sereneBlue,
                    size: 20,
                    padding: 10),
                title: Text('Edit', style: PremiumTypography(context).title),
                onTap: () {
                  Navigator.pop(context);
                  _editMilestone(item);
                },
              ),
              ListTile(
                leading: PremiumBubbleIcon(
                    icon: Icons.delete_rounded,
                    color: PremiumColors(context).warmPeach,
                    size: 20,
                    padding: 10),
                title: Text('Delete Milestone',
                    style: PremiumTypography(context)
                        .title
                        .copyWith(color: PremiumColors(context).warmPeach)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(item.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editMilestone(Milestone item) {
    final titleController = TextEditingController(text: item.title);
    DateTime selectedDate = item.date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: PremiumColors(context).surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Edit Milestone', style: PremiumTypography(context).h2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'Milestone Title'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text("Date: ${_formatDate(selectedDate)}",
                        style: PremiumTypography(context).title),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedDate = picked);
                        }
                      },
                      child: Text('Change',
                          style: PremiumTypography(context).bodyBold.copyWith(
                              color: PremiumColors(context).sereneBlue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: PremiumTypography(context).bodyBold.copyWith(
                        color: PremiumColors(context).textSecondary))),
            TextButton(
              onPressed: () async {
                final repo = context.read<CareRepository>();
                if (titleController.text.isNotEmpty) {
                  final updates = {
                    'title': titleController.text,
                    'date': selectedDate.toIso8601String(),
                  };
                  await repo.updateMilestone(item.id, updates);

                  if (context.mounted) {
                    await _fetchMilestones();
                    Navigator.pop(context);
                  }
                }
              },
              child: Text('Save',
                  style: PremiumTypography(context)
                      .bodyBold
                      .copyWith(color: PremiumColors(context).softAmber)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumColors(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Delete Milestone", style: PremiumTypography(context).h2),
        content: Text("Are you sure? This cannot be undone.",
            style: PremiumTypography(context).body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: PremiumTypography(context)
                      .bodyBold
                      .copyWith(color: PremiumColors(context).textSecondary))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMilestone(id);
              },
              child: Text("Delete",
                  style: PremiumTypography(context)
                      .bodyBold
                      .copyWith(color: PremiumColors(context).warmPeach))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String suffix = 'th';
    final day = date.day;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
          break;
      }
    }
    return "${DateFormat('d').format(date)}$suffix ${DateFormat('MMM y').format(date)}";
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(
        title: const Hero(tag: 'milestones_title', child: Text('Milestones')),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: _showInfo,
              icon: Icon(Icons.info_outline_rounded,
                  color: PremiumColors(context).textSecondary))
        ],
      ),
      body: Hero(
        tag: 'milestones_card',
        child: Material(
          color: Colors.transparent,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: PremiumColors(context).softAmber))
              : TweenAnimationBuilder<double>(
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
                  child: _milestones.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_rounded, size: 80, color: PremiumColors(context).surfaceMuted),
                              const SizedBox(height: 16),
                              Text("No Milestones Yet", style: PremiumTypography(context).h2),
                              const SizedBox(height: 8),
                              Text("Tap + to add your first memory", style: PremiumTypography(context).body),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 100),
                          itemCount: _milestones.length,
                          itemBuilder: (context, index) {
                            final item = _milestones[index];
                            final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: GestureDetector(
                                onTap: () => _showOptions(item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: PremiumColors(context).surface,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (hasImage)
                                        AspectRatio(
                                          aspectRatio: 4 / 3,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.network(
                                                item.imageUrl!,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return Center(child: CircularProgressIndicator(color: PremiumColors(context).softAmber));
                                                },
                                                errorBuilder: (context, error, stackTrace) => Container(color: PremiumColors(context).surfaceMuted, child: const Icon(Icons.broken_image_rounded)),
                                              ),
                                              Positioned.fill(
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                                                        stops: const [0.6, 1.0],
                                                      ),
                                                    ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 16,
                                                left: 20,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                                                      child: Text(_formatDate(item.date), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            if (!hasImage) ...[
                                              PremiumBubbleIcon(icon: Icons.star_rounded, color: PremiumColors(context).softAmber, size: 28, padding: 14),
                                              const SizedBox(width: 16),
                                            ],
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.title, style: PremiumTypography(context).h2.copyWith(fontSize: 22)),
                                                  if (!hasImage) ...[
                                                      const SizedBox(height: 4),
                                                      Text(_formatDate(item.date), style: PremiumTypography(context).body, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.more_horiz_rounded, color: PremiumColors(context).textSecondary),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMilestone,
        backgroundColor: PremiumColors(context).softAmber,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
