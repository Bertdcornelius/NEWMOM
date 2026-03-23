import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/vaccine_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import 'package:intl/intl.dart';
import '../../widgets/premium_ui_components.dart';

class VaccineScreen extends StatefulWidget {
  const VaccineScreen({super.key});

  @override
  State<VaccineScreen> createState() => _VaccineScreenState();
}

class _VaccineScreenState extends State<VaccineScreen> {
  List<Vaccine> _vaccines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVaccines();
  }

  Future<void> _fetchVaccines() async {
    setState(() => _isLoading = true);

    final service = context.read<CareRepository>();
    final data = (await service.getVaccines()).data ?? [];
    setState(() {
      _vaccines = data.map((e) => Vaccine.fromJson(e)).toList();
      _isLoading = false;
    });
    // Note: Ad wall is handled by Dashboard navigation
  }

  Future<void> _addVaccine() async {
    final nameController = TextEditingController();
    DateTime? dueDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Add Vaccine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Vaccine Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(dueDate == null
                      ? 'No Due Date'
                      : 'Due: ${DateFormat('yyyy-MM-dd').format(dueDate!)}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      setStateDialog(() => dueDate = picked);
                    },
                    child: Text('Pick Date'),
                  )
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                final user = context.read<AuthRepository>().currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in'), backgroundColor: Colors.red));
                  return;
                }
                
                final newVaccine = Vaccine(
                  id: Uuid().v4(),
                  userId: user.id,
                  name: nameController.text,
                  dueDate: dueDate,
                  status: 'pending',
                  createdAt: DateTime.now(),
                );

                final service = context.read<CareRepository>();
                final result = await service.saveVaccine(newVaccine.toJson());
                if (result.isSuccess) {
                  _fetchVaccines();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vaccine saved!')));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save'), backgroundColor: Colors.red));
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsGiven(Vaccine vaccine) async {
    final service = context.read<CareRepository>();
    await service.updateVaccine(vaccine.id, {
      'status': 'given',
      'given_date': DateTime.now().toIso8601String(),
    });
    _fetchVaccines();
  }

  Future<void> _deleteVaccine(String id) async {
    await context.read<CareRepository>().deleteVaccine(id);
    _fetchVaccines();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }

  void _showOptions(Vaccine vaccine) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editVaccine(vaccine);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Vaccine'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(vaccine.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editVaccine(Vaccine vaccine) {
    final nameController = TextEditingController(text: vaccine.name);
    DateTime? dueDate = vaccine.dueDate;
    String status = vaccine.status; // pending, given, skipped

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Edit Vaccine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Vaccine Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(dueDate == null
                        ? 'No Due Date'
                        : 'Due: ${DateFormat('yyyy-MM-dd').format(dueDate!)}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setStateDialog(() => dueDate = picked);
                        }
                      },
                      child: Text('Pick Date'),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['pending', 'given', 'skipped']
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => status = val!),
                ),
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
                    'name': nameController.text,
                    'due_date': dueDate?.toIso8601String(),
                    'status': status,
                    'given_date': status == 'given' && vaccine.status != 'given'
                        ? DateTime.now().toIso8601String()
                        : (status != 'given'
                            ? null
                            : vaccine.givenDate?.toIso8601String()),
                  };
                  await context
                      .read<CareRepository>()
                      .updateVaccine(vaccine.id, updates);
                  _fetchVaccines();
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
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
        title: Text("Delete Vaccine"),
        content: Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteVaccine(id);
              },
              child: Text("Delete",
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.redAccent
                          : Colors.red))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumScaffold(
      appBar: AppBar(
        title:
            Text('Vaccination Tracker', style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: PremiumColors(context).sereneBlue))
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vaccines.length,
                itemBuilder: (context, index) {
                  final vaccine = _vaccines[index];
                  final isGiven = vaccine.status == 'given';
                  final isSkipped = vaccine.status == 'skipped';

                  Color cardColor = PremiumColors(context).surface;
                  if (isGiven) {
                    cardColor = isDark
                        ? const Color(0xFF1A2E20)
                        : const Color(0xFFF0FDF4); // very soft green
                  }
                  if (isSkipped) {
                    cardColor = isDark
                        ? const Color(0xFF2E2015)
                        : const Color(0xFFFFF7ED); // very soft orange
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: DataTile(
                      onTap: () => _showOptions(vaccine),
                      backgroundColor: cardColor,
                      child: Row(
                        children: [
                          PremiumBubbleIcon(
                            icon: isGiven
                                ? Icons.check_circle_rounded
                                : (isSkipped
                                    ? Icons.block_rounded
                                    : Icons.medical_services_rounded),
                            color: isGiven
                                ? Colors.green
                                : (isSkipped
                                    ? Colors.orange
                                    : PremiumColors(context).textSecondary),
                            size: 24,
                            padding: 12,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vaccine.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSkipped
                                        ? PremiumColors(context).textSecondary
                                        : PremiumColors(context).textPrimary,
                                    decoration: isGiven || isSkipped
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationThickness: 2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isGiven
                                      ? 'Given on ${_formatDate(vaccine.givenDate!)}'
                                      : isSkipped
                                          ? 'Skipped'
                                          : vaccine.dueDate != null
                                              ? 'Due: ${_formatDate(vaccine.dueDate!)}'
                                              : 'No due date',
                                  style: PremiumTypography(context).caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isGiven && !isSkipped)
                            TextButton(
                                onPressed: () => _markAsGiven(vaccine),
                                child: Text('Mark Given',
                                    style: TextStyle(
                                        color:
                                            PremiumColors(context).sereneBlue,
                                        fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVaccine,
        backgroundColor: PremiumColors(context).sereneBlue,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
