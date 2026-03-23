import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/baby_data_repository.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;

  int _feedCount = 0;
  int _sleepSessions = 0;
  double _totalSleepHours = 0;
  int _diaperCount = 0;
  int _milestoneCount = 0;
  String _babyName = 'Baby';

  // Previous week data for comparison
  int _prevFeedCount = 0;
  int _prevDiaperCount = 0;
  double _prevSleepHours = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    final service = context.read<BabyDataRepository>();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));

    final results = await Future.wait([
      service.getFeeds(),
      service.getSleepLogs(),
      service.getDiaperLogs(),
      service.getMilestones(),
      service.getProfile(),
    ]);

    final feeds = results[0] as List<Map<String, dynamic>>;
    final sleeps = results[1] as List<Map<String, dynamic>>;
    final diapers = results[2] as List<Map<String, dynamic>>;
    final milestones = results[3] as List<Map<String, dynamic>>;
    final profile = results[4] as Map<String, dynamic>?;

    // This week stats
    final thisWeekFeeds = feeds.where((f) => _isThisWeek(f['created_at'], weekStart, now)).toList();
    final thisWeekDiapers = diapers.where((d) => _isThisWeek(d['created_at'], weekStart, now)).toList();
    double thisWeekSleep = 0;
    int sleepCount = 0;
    for (final s in sleeps) {
      if (s['end_time'] == null) continue;
      if (_isThisWeek(s['start_time'], weekStart, now)) {
        try {
          final start = DateTime.parse(s['start_time']).toLocal();
          final end = DateTime.parse(s['end_time']).toLocal();
          thisWeekSleep += end.difference(start).inMinutes / 60.0;
          sleepCount++;
        } catch (_) {}
      }
    }

    // Previous week
    final prevWeekEnd = weekStart;
    final prevFeeds = feeds.where((f) => _isThisWeek(f['created_at'], prevWeekStart, prevWeekEnd)).length;
    final prevDiapers = diapers.where((d) => _isThisWeek(d['created_at'], prevWeekStart, prevWeekEnd)).length;
    double prevSleep = 0;
    for (final s in sleeps) {
      if (s['end_time'] == null) continue;
      if (_isThisWeek(s['start_time'], prevWeekStart, prevWeekEnd)) {
        try {
          final start = DateTime.parse(s['start_time']).toLocal();
          final end = DateTime.parse(s['end_time']).toLocal();
          prevSleep += end.difference(start).inMinutes / 60.0;
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _feedCount = thisWeekFeeds.length;
        _sleepSessions = sleepCount;
        _totalSleepHours = thisWeekSleep;
        _diaperCount = thisWeekDiapers.length;
        _milestoneCount = milestones.length;
        _babyName = profile?['baby_name'] ?? 'Baby';
        _prevFeedCount = prevFeeds;
        _prevDiaperCount = prevDiapers;
        _prevSleepHours = prevSleep;
        _isLoading = false;
      });
    }
  }

  bool _isThisWeek(String? dateStr, DateTime start, DateTime end) {
    if (dateStr == null) return false;
    try {
      final d = DateTime.parse(dateStr).toLocal();
      return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end.add(const Duration(days: 1)));
    } catch (_) { return false; }
  }

  String _trend(int current, int previous) {
    if (previous == 0) return current > 0 ? '↑ New' : '—';
    final diff = current - previous;
    final pct = ((diff / previous) * 100).round();
    if (diff > 0) return '↑ $pct%';
    if (diff < 0) return '↓ ${pct.abs()}%';
    return '→ Same';
  }

  String _trendHours(double current, double previous) {
    if (previous == 0) return current > 0 ? '↑ New' : '—';
    final diff = current - previous;
    final pct = ((diff / previous) * 100).round();
    if (diff > 0) return '↑ $pct%';
    if (diff < 0) return '↓ ${pct.abs()}%';
    return '→ Same';
  }

  Color _trendColor(int current, int previous) {
    if (current > previous) return Colors.green;
    if (current < previous) return Colors.red;
    return Colors.grey;
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final now = DateTime.now();
    final weekLabel = 'Week of ${DateFormat('MMM d').format(now.subtract(Duration(days: now.weekday - 1)))}';

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Weekly Report', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.sageGreen))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        PremiumCard(
                          child: Column(
                            children: [
                              Text('📊', style: const TextStyle(fontSize: 36)),
                              const SizedBox(height: 8),
                              Text('$_babyName\'s $weekLabel', style: typo.h2.copyWith(fontSize: 18)),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats Grid
                        Row(
                          children: [
                            _reportCard('🍼', 'Feeds', '$_feedCount', _trend(_feedCount, _prevFeedCount),
                                _trendColor(_feedCount, _prevFeedCount), colors),
                            const SizedBox(width: 12),
                            _reportCard('😴', 'Sleep', '${_totalSleepHours.toStringAsFixed(1)}h',
                                _trendHours(_totalSleepHours, _prevSleepHours),
                                _trendColor(_totalSleepHours.round(), _prevSleepHours.round()), colors),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _reportCard('🧷', 'Diapers', '$_diaperCount', _trend(_diaperCount, _prevDiaperCount),
                                _trendColor(_diaperCount, _prevDiaperCount), colors),
                            const SizedBox(width: 12),
                            _reportCard('🌟', 'Milestones', '$_milestoneCount', 'Total',
                                colors.softAmber, colors),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Summary Text
                        PremiumCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  PremiumBubbleIcon(icon: Icons.auto_awesome_rounded, color: colors.softAmber, size: 20, padding: 10),
                                  const SizedBox(width: 12),
                                  Text('Summary', style: typo.title),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(_generateSummary(), style: typo.body),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Share Button
                        SizedBox(
                          width: double.infinity,
                          child: PremiumActionButton(
                            label: 'Share Summary Text',
                            icon: Icons.share_rounded,
                            color: colors.sageGreen,
                            onTap: _shareReport,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // PDF Export Button
                        SizedBox(
                          width: double.infinity,
                          child: PremiumActionButton(
                            label: 'Export Pediatrician PDF',
                            icon: Icons.picture_as_pdf_rounded,
                            color: colors.sereneBlue,
                            onTap: () => _exportPDF(context),
                          ),
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

  Widget _reportCard(String emoji, String label, String value, String trend, Color trendColor, PremiumColors colors) {
    return Expanded(
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(label, style: PremiumTypography(context).caption),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(trend, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: trendColor)),
            ),
          ],
        ),
      ),
    );
  }

  String _generateSummary() {
    final lines = <String>[];
    lines.add('This week, $_babyName had $_feedCount feeds');
    if (_totalSleepHours > 0) {
      lines.add('and slept ${_totalSleepHours.toStringAsFixed(1)} hours across $_sleepSessions sessions.');
    } else {
      lines.add('.');
    }
    lines.add('$_diaperCount diapers were changed.');
    if (_feedCount > _prevFeedCount) {
      lines.add('Feeding frequency increased compared to last week. 📈');
    } else if (_feedCount < _prevFeedCount) {
      lines.add('Fewer feeds than last week — this may be normal as baby grows. 📉');
    }
    return lines.join(' ');
  }

  void _shareReport() {
    final text = '📊 $_babyName\'s Weekly Report\n\n${_generateSummary()}\n\n— Sent from Neo Baby Tracker';
    Share.share(text, subject: '$_babyName\'s Weekly Report');
  }

  Future<void> _exportPDF(BuildContext context) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final sanitizedName = _babyName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('$_babyName - Clinical Summary', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text('NEO', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey300)),
                  ]
                )
              ),
              pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 32),
              
              pw.Text('7-Day Activity Averages & Totals', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
              pw.SizedBox(height: 12),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                     _pdfStat('Feeds', '$_feedCount', PdfColors.blue600),
                     _pdfStat('Sleep', '${_totalSleepHours.toStringAsFixed(1)}h', PdfColors.purple600),
                     _pdfStat('Diapers', '$_diaperCount', PdfColors.green600),
                     _pdfStat('Milestones', '$_milestoneCount', PdfColors.orange600),
                  ]
                )
              ),
              
              pw.SizedBox(height: 32),
              pw.Text('Context & Notes', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
              pw.SizedBox(height: 12),
              pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.blue200, width: 4))),
                  child: pw.Text(_generateSummary(), style: const pw.TextStyle(fontSize: 14, lineSpacing: 1.5, color: PdfColors.grey800)),
              ),
              
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.center,
                 children: [
                    pw.Text('Auto-generated clinical report from the Neo Baby Tracker App', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                 ]
              )
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), 
        filename: '${sanitizedName}_Clinical_Report.pdf'
    );
  }

  pw.Widget _pdfStat(String label, String value, PdfColor color) {
     return pw.Column(
        children: [
           pw.Text(value, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: color)),
           pw.SizedBox(height: 6),
           pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        ]
     );
  }
}
