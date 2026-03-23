import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../services/baby_data_repository.dart';
import '../../widgets/premium_ui_components.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final Set<String> _selectedTypes = {'feeds', 'sleep', 'diapers', 'milestones'};
  String? _exportPreview;
  bool _isExporting = false;

  final exportTypes = [
    {'id': 'feeds', 'name': 'Feeds', 'emoji': '🍼', 'color': Colors.orange},
    {'id': 'sleep', 'name': 'Sleep Logs', 'emoji': '😴', 'color': Colors.blue},
    {'id': 'diapers', 'name': 'Diapers', 'emoji': '🧷', 'color': Colors.brown},
    {'id': 'milestones', 'name': 'Milestones', 'emoji': '🌟', 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
  }


  Future<void> _generateExport() async {
    setState(() => _isExporting = true);
    final service = context.read<BabyDataRepository>();
    final buffer = StringBuffer();
    buffer.writeln('Neo Baby Tracker - Data Export');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('${'=' * 50}\n');

    if (_selectedTypes.contains('feeds')) {
      final feeds = await service.getFeeds();
      buffer.writeln('FEEDS (${feeds.length} entries)');
      buffer.writeln('Date,Type,Amount(ml),Duration(min)');
      for (final f in feeds) {
        try {
          final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(f['created_at']).toLocal());
          buffer.writeln('$date,${f['type']},${f['amount_ml'] ?? ''},${f['duration_min'] ?? ''}');
        } catch (_) {}
      }
      buffer.writeln('');
    }

    if (_selectedTypes.contains('sleep')) {
      final logs = await service.getSleepLogs();
      buffer.writeln('SLEEP LOGS (${logs.length} entries)');
      buffer.writeln('Start,End,Duration(min)');
      for (final l in logs) {
        try {
          final start = DateTime.parse(l['start_time']).toLocal();
          final end = l['end_time'] != null ? DateTime.parse(l['end_time']).toLocal() : null;
          final dur = end != null ? end.difference(start).inMinutes : 0;
          buffer.writeln('${DateFormat('yyyy-MM-dd HH:mm').format(start)},${end != null ? DateFormat('yyyy-MM-dd HH:mm').format(end) : 'ongoing'},$dur');
        } catch (_) {}
      }
      buffer.writeln('');
    }

    if (_selectedTypes.contains('diapers')) {
      final diapers = await service.getDiaperLogs();
      buffer.writeln('DIAPERS (${diapers.length} entries)');
      buffer.writeln('Date,Type');
      for (final d in diapers) {
        try {
          final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(d['created_at']).toLocal());
          buffer.writeln('$date,${d['type']}');
        } catch (_) {}
      }
      buffer.writeln('');
    }

    if (_selectedTypes.contains('milestones')) {
      final milestones = await service.getMilestones();
      buffer.writeln('MILESTONES (${milestones.length} entries)');
      buffer.writeln('Title,Date,Category');
      for (final m in milestones) {
        buffer.writeln('${m['title']},${m['achieved_date'] ?? ''},${m['category'] ?? ''}');
      }
    }

    if (mounted) {
      setState(() {
        _exportPreview = buffer.toString();
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Data Export', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Data Types
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Data to Export', style: typo.title),
                        const SizedBox(height: 16),
                        ...exportTypes.map((t) {
                          final id = t['id'] as String;
                          final isSelected = _selectedTypes.contains(id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedTypes.remove(id);
                                } else {
                                  _selectedTypes.add(id);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected ? (t['color'] as Color).withValues(alpha: 0.1) : colors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? (t['color'] as Color) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(t['emoji'] as String, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(t['name'] as String, style: typo.bodyBold)),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected ? (t['color'] as Color) : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? (t['color'] as Color) : colors.textMuted,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: PremiumActionButton(
                      label: _isExporting ? 'Generating...' : 'Generate Export',
                      icon: Icons.download_rounded,
                      color: colors.sereneBlue,
                      onTap: _selectedTypes.isEmpty || _isExporting ? () {} : () { _generateExport(); },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preview
                  if (_exportPreview != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Preview', style: typo.h2),
                        TextButton.icon(
                          onPressed: _shareExport,
                          icon: Icon(Icons.share_rounded, color: colors.sageGreen, size: 18),
                          label: Text('Share', style: typo.bodyBold.copyWith(color: colors.sageGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _exportPreview!,
                        style: GoogleFonts.sourceCodePro(fontSize: 11, color: colors.textSecondary),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareExport() async {
    if (_exportPreview != null) {
      try {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            build: (pw.Context context) {
              return [
                pw.Text(
                  _exportPreview!,
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                ),
              ];
            },
          ),
        );
        
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/neo_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        
        Share.shareXFiles([XFile(file.path)], subject: 'Neo Baby Tracker - Data Export PDF');
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF')));
      }
    }
  }
}
