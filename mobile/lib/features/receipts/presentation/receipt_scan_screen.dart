import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/error_text.dart';
import '../data/receipts_repository.dart';

/// Photo → server OCR → user reviews the extracted values in the transaction form.
class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  String? _path;
  ReceiptScan? _receipt;
  bool _busy = false;
  bool _handedOff = false;
  // Captured up front: ref must not be used during dispose.
  late final ReceiptsRepository _repository = ref.read(receiptsRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _repository;
  }

  Future<void> _pick(ImageSource source) async {
    final l10n = context.l10n;
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: source, maxWidth: 2400, imageQuality: 85);
    } catch (_) {
      if (mounted) showMessageSnack(context, l10n.receiptPickFailed);
      return;
    }
    if (file == null || !mounted) return;
    setState(() {
      _path = file!.path;
      _receipt = null;
      _busy = true;
    });
    try {
      final receipt = await _repository.scan(file.path);
      if (mounted) setState(() => _receipt = receipt);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _path = null);
      e.isNetwork ? showMessageSnack(context, l10n.receiptNeedsInternet) : showErrorSnack(context, e);
    } on TimeoutException {
      if (mounted) showMessageSnack(context, l10n.receiptFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _review() {
    _handedOff = true;
    context.pushReplacement('/transactions/new', extra: _receipt);
  }

  @override
  void dispose() {
    // A scan the user abandoned is removed from the server.
    final receipt = _receipt;
    if (receipt != null && !_handedOff) {
      unawaited(_repository.discard(receipt.id).catchError((_) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final receipt = _receipt;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanReceipt)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.receiptScanIntro, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  key: const Key('receipt-camera'),
                  icon: Icons.photo_camera_outlined,
                  label: l10n.takePhoto,
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_outlined,
                  label: l10n.chooseFromGallery,
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (_path != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_path!), height: 260, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            if (_busy)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text(l10n.readingReceipt),
                ],
              )
            else if (receipt != null) ...[
              if (receipt.failed)
                Text(receipt.error ?? l10n.receiptFailed, style: TextStyle(color: theme.colorScheme.error))
              else
                Card(
                  child: Column(
                    children: [
                      _ResultRow(label: l10n.merchant, value: receipt.merchant),
                      _ResultRow(label: l10n.amount, value: receipt.displayTotal),
                      _ResultRow(
                        label: l10n.date,
                        value: receipt.date == null ? null : DateFormat.yMMMd(context.localeCode).format(receipt.date!),
                      ),
                      if (receipt.confidence < 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(l10n.receiptPartial, style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('receipt-review'),
                onPressed: _review,
                child: Text(receipt.failed ? l10n.enterManually : l10n.reviewAndSave),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
      onPressed: onPressed,
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Text(label, style: TextStyle(color: theme.hintColor)),
      trailing: Text(
        value ?? context.l10n.notFound,
        style: theme.textTheme.titleSmall?.copyWith(color: value == null ? theme.hintColor : null),
      ),
    );
  }
}
