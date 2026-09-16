import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';

final categoriesProvider = StreamProvider.family<List<CategoryEntity>, String?>(
  (ref, type) => ref.watch(categoriesRepositoryProvider).watchAll(type: type),
);
