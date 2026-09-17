import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/error_text.dart';
import '../../planning/application/planning_providers.dart';
import '../data/reports_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _type = 'monthly';
  String _format = 'pdf';
  bool _busy = false;

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final file = await ref.read(reportsRepositoryProvider).generate(type: _type, format: _format);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], title: context.l10n.reportTypeLabel(_type)),
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formats = reportFormats[_type]!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.reportType, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _type,
            onChanged: (v) => setState(() {
              _type = v!;
              if (!reportFormats[_type]!.contains(_format)) _format = reportFormats[_type]!.first;
            }),
            child: Column(
              children: [
                for (final type in reportFormats.keys)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: type,
                    title: Text(l10n.reportTypeLabel(type)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.reportFormat, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              for (final f in formats) ButtonSegment(value: f, label: Text(f == 'xlsx' ? 'Excel' : f.toUpperCase())),
            ],
            selected: {_format},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _format = v.first),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_rounded),
            label: Text(_busy ? l10n.preparingReport : l10n.generateReport),
          ),
        ],
      ),
    );
  }
}
