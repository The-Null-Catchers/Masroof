import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../network/api_exception.dart';

String describeError(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is ApiException) {
    if (error.isNetwork) return l10n.networkError;
    if (error.fieldErrors.isNotEmpty) return error.fieldErrors.values.first.first;
    return error.message ?? l10n.genericError;
  }
  return l10n.genericError;
}

void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(describeError(context, error))));
}
