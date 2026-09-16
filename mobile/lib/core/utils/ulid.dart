import 'dart:math';

/// Generates lexicographically sortable ULIDs (lower-case) so records created
/// offline keep a stable identity when they are later pushed to the API.
abstract final class Ulid {
  static const _alphabet = '0123456789abcdefghjkmnpqrstvwxyz';
  static final _random = Random.secure();

  static String generate([DateTime? time]) {
    var millis = (time ?? DateTime.now()).millisecondsSinceEpoch;
    final chars = List.filled(26, '0');
    for (var i = 9; i >= 0; i--) {
      chars[i] = _alphabet[millis % 32];
      millis ~/= 32;
    }
    for (var i = 10; i < 26; i++) {
      chars[i] = _alphabet[_random.nextInt(32)];
    }
    return chars.join();
  }
}
