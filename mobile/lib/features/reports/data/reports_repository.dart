import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

const reportFormats = {
  'monthly': ['pdf', 'xlsx'],
  'transactions': ['csv', 'xlsx', 'pdf'],
  'budgets': ['pdf', 'xlsx', 'csv'],
  'income_expense': ['pdf', 'xlsx', 'csv'],
  'categories': ['pdf', 'xlsx', 'csv'],
};

class ReportsRepository {
  ReportsRepository(
    this._api, {
    Future<Directory> Function()? directory,
    this.pollInterval = const Duration(seconds: 1),
  }) : _directory = directory ?? getTemporaryDirectory;

  final ApiClient _api;
  final Future<Directory> Function() _directory;
  final Duration pollInterval;

  /// Requests an export, waits for the server to finish it, and saves the file locally.
  Future<File> generate({required String type, required String format, Map<String, Object?> options = const {}}) async {
    final created = await _api.post('/reports/exports', {'type': type, 'format': format, ...options});
    final id = (created['data'] as Map)['id'] as String;

    var export = created['data'] as Map;
    for (var attempt = 0; export['status'] != 'completed'; attempt++) {
      if (export['status'] == 'failed' || attempt > 90) {
        throw const ApiException(ApiErrorKind.server);
      }
      await Future<void>.delayed(pollInterval);
      export = (await _api.get('/reports/exports/$id'))['data'] as Map;
    }

    final bytes = await _api.download('/reports/exports/$id/download');
    final dir = await _directory();
    final file = File('${dir.path}/${export['file_name'] ?? '$id.$format'}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
