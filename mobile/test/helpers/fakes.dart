import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:masroof/core/database/app_database.dart';
import 'package:masroof/core/network/api_client.dart';
import 'package:masroof/core/network/api_exception.dart';

AppDatabase memoryDatabase() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

typedef Handler = Map<String, dynamic> Function(String method, String path, Object? body, Map<String, dynamic>? query);

/// Records requests and answers them with [handler].
class FakeApiClient implements ApiClient {
  FakeApiClient(this.handler);

  Handler handler;
  final requests = <(String, String, Object?)>[];

  Future<Map<String, dynamic>> _call(String method, String path, Object? body, [Map<String, dynamic>? query]) async {
    requests.add((method, path, body));
    return handler(method, path, body, query);
  }

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) => _call('GET', path, null, query);

  @override
  Future<Map<String, dynamic>> post(String path, [Object? body]) => _call('POST', path, body);

  @override
  Future<Map<String, dynamic>> patch(String path, [Object? body]) => _call('PATCH', path, body);

  @override
  Future<Map<String, dynamic>> put(String path, [Object? body]) => _call('PUT', path, body);

  @override
  Future<Map<String, dynamic>> delete(String path, [Object? body]) => _call('DELETE', path, body);
}

const offline = ApiException(ApiErrorKind.network);

Map<String, dynamic> emptySync(String serverTime) => {
  'server_time': serverTime,
  'has_more': false,
  'accounts': {'upserted': <Object>[], 'deleted': <Object>[]},
  'categories': {'upserted': <Object>[], 'deleted': <Object>[]},
  'transactions': {'upserted': <Object>[], 'deleted': <Object>[]},
};
