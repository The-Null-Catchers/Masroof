import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

/// Server-side OCR result for an uploaded receipt photo.
class ReceiptScan {
  const ReceiptScan({
    required this.id,
    required this.status,
    this.error,
    this.merchant,
    this.total,
    this.currency,
    this.date,
    this.suggestedCategoryId,
    this.confidence = 0,
    this.displayTotal,
  });

  factory ReceiptScan.fromJson(Map<String, dynamic> json) {
    final x = json['extracted'] as Map<String, dynamic>?;
    return ReceiptScan(
      id: json['id'] as String,
      status: json['status'] as String,
      error: json['error'] as String?,
      merchant: x?['merchant'] as String?,
      total: x?['total'] as String?,
      currency: x?['currency'] as String?,
      date: x?['date'] == null ? null : DateTime.tryParse(x!['date'] as String),
      suggestedCategoryId: x?['suggested_category_id'] as String?,
      confidence: (x?['confidence'] as num?)?.toDouble() ?? 0,
      displayTotal: x?['display_total'] as String?,
    );
  }

  final String id;
  final String status;
  final String? error;
  final String? merchant;
  final String? total;
  final String? currency;
  final DateTime? date;
  final String? suggestedCategoryId;
  final double confidence;
  final String? displayTotal;

  bool get isDone => status == 'processed' || status == 'failed';
  bool get failed => status == 'failed';
}

class ReceiptsRepository {
  ReceiptsRepository(this._api);

  final ApiClient _api;

  Future<ReceiptScan> upload(String filePath) async =>
      ReceiptScan.fromJson((await _api.upload('/receipts', filePath))['data'] as Map<String, dynamic>);

  Future<ReceiptScan> fetch(String id) async =>
      ReceiptScan.fromJson((await _api.get('/receipts/$id'))['data'] as Map<String, dynamic>);

  /// Uploads and polls until OCR (a queued job) finishes.
  Future<ReceiptScan> scan(
    String filePath, {
    Duration interval = const Duration(milliseconds: 1500),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    var receipt = await upload(filePath);
    final deadline = DateTime.now().add(timeout);
    while (!receipt.isDone) {
      if (DateTime.now().isAfter(deadline)) throw TimeoutException('Receipt OCR timed out');
      await Future<void>.delayed(interval);
      receipt = await fetch(receipt.id);
    }
    return receipt;
  }

  Future<void> discard(String id) => _api.delete('/receipts/$id');
}

final receiptsRepositoryProvider = Provider<ReceiptsRepository>(
  (ref) => ReceiptsRepository(ref.watch(apiClientProvider)),
);
