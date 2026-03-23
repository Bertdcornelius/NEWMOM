import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../core/result.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading && !_isFetchingMore && _hasMore) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final ss = context.read<CareRepository>();
    final data = (await ss.getGalleryPhotos(start: 0, limit: 15)).data ?? [];
    if (mounted) {
      setState(() {
        _photos = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
        _hasMore = data.length == 15;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isFetchingMore = true);
    final ss = context.read<CareRepository>();
    final data = (await ss.getGalleryPhotos(start: _photos.length, limit: 15)).data ?? [];
    if (mounted) {
      setState(() {
        _photos.addAll(List<Map<String, dynamic>>.from(data));
        _isFetchingMore = false;
        _hasMore = data.length == 15;
      });
    }
  }

  Future<void> _savePhoto(String url, String caption) async {
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in'), backgroundColor: Colors.red));
      return;
    }
    final ss = context.read<CareRepository>();
    final result = await ss.saveGalleryPhoto({
      'user_id': user.id,
      'image_url': url,
      'caption': caption,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (!result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save photo'), backgroundColor: Colors.red));
    }
    _loadData();
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
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
                    controller: _scrollController,
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
                        
                        if (_isFetchingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),

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
              if (photo['image_url'] != null)
                CachedNetworkImage(
                  imageUrl: photo['image_url'],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: colors.surfaceMuted, child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => Container(color: colors.surfaceMuted, child: const Icon(Icons.broken_image)),
                )
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
                    child: Text(caption!, style: PremiumTypography(context).bodyBold.copyWith(
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
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          bool isUploading = false; // Moved inside StatefulBuilder
          return AlertDialog(
            title: const Text('Add Caption'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUploading) const LinearProgressIndicator(),
                TextField(
                  controller: captionC,
                  enabled: !isUploading,
                  decoration: const InputDecoration(hintText: 'What\'s this moment? (optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () async {
                  setD(() => isUploading = true);
                  final ss = context.read<CareRepository>();
                  final bytes = await picked.readAsBytes();
                  final user = context.read<AuthRepository>().currentUser;
                  if (user == null) {
                    setD(() => isUploading = false);
                    return;
                  }
                  final uploadRes = await ss.uploadImage(user.id, picked.path, bytes);
                  
                  if (uploadRes is Success) {
                    await _savePhoto(uploadRes.data!, captionC.text);
                  }
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    _loadData();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showPhotoDetail(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photo['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: photo['image_url'],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 48),
                ),
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
                child: Text(photo['caption'], style: PremiumTypography(context).bodyBold.copyWith(
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
            onPressed: () async {
              final ss = context.read<CareRepository>();
              await ss.deleteGalleryPhoto(photo['id']);
              _loadData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
