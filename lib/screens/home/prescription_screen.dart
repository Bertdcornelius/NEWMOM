import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/prescription_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Prescription> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);

    final service = context.read<CareRepository>();
    final data = (await service.getPrescriptions()).data ?? [];
    setState(() {
      _items = data.map((e) => Prescription.fromJson(e)).toList();
      _isLoading = false;
    });
    // Note: Ad wall is handled by Dashboard navigation
  }

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final freqController = TextEditingController();
    Uint8List? imageBytes;
    String? imageName;

    await showDialog(
      context: context,
      builder: (context) {
        bool isValuesSaving = false; // Local state for dialog

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('Add Prescription'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Medicine Name')),
                  TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                          labelText: 'Dosage (e.g. 5ml)')),
                  TextField(
                      controller: freqController,
                      decoration: const InputDecoration(
                          labelText: 'Frequency (e.g. 2x Daily)')),
                  const SizedBox(height: 16),
                  if (imageBytes != null)
                    Text('Image selected: $imageName',
                        style: const TextStyle(color: Colors.green)),
                  TextButton.icon(
                    onPressed: () async {
                      final authService = context.read<AuthRepository>();
                      final isPremium = await authService.isPremiumUser();

                      if (!isPremium) {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Premium Feature'),
                              content: Text(
                                  'Attaching photos is a Premium Feature. Upgrade to attach prescriptions!'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('OK'))
                              ],
                            ),
                          );
                        }
                        return;
                      }

                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setStateDialog(() {
                          imageBytes = bytes;
                          imageName = image.name;
                        });
                      }
                    },
                    icon: Icon(Icons.camera_alt),
                    label: Text('Attach Photo'),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isValuesSaving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final dosage = dosageController.text.trim();
                        final freq = freqController.text.trim();

                        if (name.isEmpty) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine name is required.')));
                            return;
                        }
                        
                        if (name.length > 100 || dosage.length > 50 || freq.length > 50) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text inputs exceed max length.')));
                            return;
                        }

                        setStateDialog(
                            () => isValuesSaving = true); // Lock button

                        try {
                          final service = context.read<CareRepository>();
                          final authService = context.read<AuthRepository>();
                          final user = authService.currentUser;
                          if (user == null) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in. Please sign in first.'), backgroundColor: Colors.red));
                            return;
                          }

                          String? imageUrl;
                          if (imageBytes != null && imageName != null) {
                            final res = await service.uploadImage(
                                user.id, imageName!, imageBytes!);
                            imageUrl = res.data;
                          }

                          final newItem = Prescription(
                            id: Uuid().v4(),
                            userId: user.id,
                            medicineName: name,
                            dosage: dosage,
                            frequency: freq,
                            imageUrl: imageUrl,
                            createdAt: DateTime.now().toUtc(), // Fix Timezone
                          );

                          await service.savePrescription(newItem.toJson());
                          _fetchItems();
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setStateDialog(
                              () => isValuesSaving = false); // Unlock if error
                        }
                      },
                child: isValuesSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(
            imageUrl: url, 
            placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            errorWidget: (context, url, error) => const SizedBox(height: 200, child: Icon(Icons.broken_image, size: 48)),
        ),
      ),
    );
  }

  Future<void> _deletePrescription(String id) async {
    await context.read<CareRepository>().deletePrescription(id);
    _fetchItems();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }

  void _showOptions(Prescription item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit,
                  color: isDark ? Colors.lightBlue : Colors.blue),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editPrescription(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete,
                  color: isDark ? Colors.redAccent : Colors.red),
              title: Text('Delete Prescription'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editPrescription(Prescription item) {
    final nameController = TextEditingController(text: item.medicineName);
    final dosageController = TextEditingController(text: item.dosage);
    final freqController = TextEditingController(text: item.frequency);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Prescription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Medicine Name')),
              TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage')),
              TextField(
                  controller: freqController,
                  decoration: const InputDecoration(labelText: 'Frequency')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updates = {
                  'medicine_name': nameController.text,
                  'dosage': dosageController.text,
                  'frequency': freqController.text,
                };
                await context
                    .read<CareRepository>()
                    .updatePrescription(item.id, updates);
                _fetchItems();
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Prescription"),
        content: Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deletePrescription(id);
              },
              child: Text("Delete",
                  style: TextStyle(
                      color: isDark ? Colors.redAccent : Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Prescriptions', style: PremiumTypography(context).h2),
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
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: PremiumColors(context).sereneBlue))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return PremiumCard(
                          child: InkWell(
                            onTap: item.imageUrl != null
                                ? () => _showImage(item.imageUrl!)
                                : null,
                            onLongPress: () => _showOptions(item),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.imageUrl != null)
                                    PremiumBubbleIcon(
                                        icon: Icons.image_rounded,
                                        color: Colors.green,
                                        size: 28,
                                        padding: 12)
                                  else
                                    PremiumBubbleIcon(
                                        icon: Icons.medication_rounded,
                                        color:
                                            PremiumColors(context).sereneBlue,
                                        size: 28,
                                        padding: 12),
                                  const Spacer(),
                                  Text(
                                    item.medicineName,
                                    style: PremiumTypography(context).title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.dosage ?? '',
                                      style: PremiumTypography(context).body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(item.frequency ?? '',
                                      style: PremiumTypography(context).caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
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
        onPressed: _addItem,
        backgroundColor: PremiumColors(context).sereneBlue,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
