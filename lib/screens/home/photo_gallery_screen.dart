import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/premium_ui_components.dart';
import 'dart:io';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<Map<String, dynamic>> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadData() {
    final ls = context.read<LocalStorageService>();
    final raw = ls.getString('photo_gallery');
    if (raw != null) _photos = List<Map<String, dynamic>>.from(jsonDecode(raw));
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    await context.read<LocalStorageService>().saveString('photo_gallery', jsonEncode(_photos));
  }

  // Group photos by month
  Map<String, List<Map<String, dynamic>>> get _groupedPhotos {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final photo in _photos) {
      try {
        final date = DateTime.parse(photo['timestamp']);
        final key = DateFormat('MMMM yyyy').format(date);
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(photo);
      } catch (_) {}
    }
    return grouped;
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final grouped = _groupedPhotos;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Photo Gallery', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        backgroundColor: colors.gentlePurple,
        child: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _photos.isEmpty
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_rounded, size: 64, color: colors.textMuted),
                      const SizedBox(height: 16),
                      Text('No photos yet', style: typo.h2),
                      const SizedBox(height: 8),
                      Text('Tap + to capture a moment', style: typo.body),
                    ],
                  ))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo count header
                        Row(
                          children: [
                            PremiumBubbleIcon(icon: Icons.photo_camera_rounded, color: colors.gentlePurple, size: 20, padding: 10),
                            const SizedBox(width: 12),
                            Text('${_photos.length} Memories', style: typo.h2),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Grouped by month
                        ...grouped.entries.toList().asMap().entries.map((entry) {
                          final monthLabel = entry.value.key;
                          final monthPhotos = entry.value.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(monthLabel, style: typo.title),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: monthPhotos.length,
                                itemBuilder: (ctx, i) => _buildPhotoTile(monthPhotos[i], colors),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(Map<String, dynamic> photo, PremiumColors colors) {
    final path = photo['path'] as String?;
    final caption = photo['caption'] as String?;

    return GestureDetector(
      onTap: () => _showPhotoDetail(photo),
      onLongPress: () => _deletePhoto(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colors.surfaceMuted,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (path != null && File(path).existsSync())
                Image.file(File(path), fit: BoxFit.cover)
              else
                Container(
                  color: colors.gentlePurple.withValues(alpha: 0.15),
                  child: Icon(Icons.photo_rounded, color: colors.gentlePurple, size: 32),
                ),
              if (caption?.isNotEmpty == true)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      ),
                    ),
                    child: Text(caption!, style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final captionC = TextEditingController();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Caption'),
        content: TextField(
          controller: captionC,
          decoration: const InputDecoration(hintText: 'What\'s this moment? (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _photos.insert(0, {
                'path': picked.path,
                'caption': captionC.text,
                'timestamp': DateTime.now().toIso8601String(),
              });
              _saveData();
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPhotoDetail(Map<String, dynamic> photo) {
    final path = photo['path'] as String?;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (path != null && File(path).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(path), fit: BoxFit.contain),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: PremiumColors(context).surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Icon(Icons.broken_image, size: 48)),
              ),
            if (photo['caption']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(photo['caption'], style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                )),
              ),
          ],
        ),
      ),
    );
  }

  void _deletePhoto(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _photos.remove(photo);
              _saveData();
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
