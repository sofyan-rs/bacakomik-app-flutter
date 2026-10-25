import 'dart:convert';

/// Reading progress imported from another app for one comic, waiting for
/// the comic's chapter list to load. Chapters are matched by number.
class PendingRead {
  PendingRead({this.upTo, this.chapters = const {}});

  /// Every chapter numbered up to [number] is read: what the Comix.to
  /// export knows, and the only form stored before exact chapters were.
  PendingRead.upTo(String number) : this(upTo: number);

  /// Every chapter numbered up to this one is read; null when not known.
  final String? upTo;

  /// Exact chapters read, by number (`10.5`), with when they were read.
  final Map<String, DateTime> chapters;

  bool get isEmpty => upTo == null && chapters.isEmpty;

  /// Whether the chapter numbered [number] is read.
  bool covers(String number) {
    final n = num.tryParse(number);
    if (n == null) return chapters.containsKey(number);
    if (num.tryParse(upTo ?? '') case final limit? when n <= limit) {
      return true;
    }
    return _numbers.containsKey(n) || chapters.containsKey(number);
  }

  /// When the chapter numbered [number] was read, when known.
  DateTime? readDateOf(String number) =>
      chapters[number] ?? _numbers[num.tryParse(number)];

  late final Map<num, DateTime> _numbers = {
    for (final MapEntry(:key, :value) in chapters.entries)
      ?num.tryParse(key): value,
  };

  /// Both together: the higher [upTo], every chapter of both, a chapter in
  /// both keeping its later date.
  PendingRead merge(PendingRead other) => PendingRead(
    upTo: _higher(upTo, other.upTo),
    chapters: {
      ...chapters,
      for (final MapEntry(:key, :value) in other.chapters.entries)
        key: switch (chapters[key]) {
          final mine? when mine.isAfter(value) => mine,
          _ => value,
        },
    },
  );

  static String? _higher(String? a, String? b) {
    if (a == null) return b;
    if (b == null) return a;
    final (x, y) = (num.tryParse(a), num.tryParse(b));
    return x != null && y != null && x > y ? a : b;
  }

  /// Stored form. Only [upTo]: the bare number, as stored before exact
  /// chapters were. Otherwise JSON: `{"upTo": "7", "read": {"9": <ms>}}`.
  String encode() {
    if (chapters.isEmpty && upTo != null) return upTo!;
    return jsonEncode({
      'upTo': ?upTo,
      'read': {
        for (final MapEntry(:key, :value) in chapters.entries)
          key: value.millisecondsSinceEpoch,
      },
    });
  }

  /// Reads [encode]'s output, including the bare number of older versions.
  static PendingRead decode(String value) {
    if (!value.trimLeft().startsWith('{')) return PendingRead.upTo(value);
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final read = json['read'];
      return PendingRead(
        upTo: json['upTo'] as String?,
        chapters: {
          if (read is Map)
            for (final MapEntry(:key, :value) in read.entries)
              if (value is int)
                '$key': DateTime.fromMillisecondsSinceEpoch(value),
        },
      );
    } on Object {
      return PendingRead();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PendingRead &&
      other.upTo == upTo &&
      other.chapters.length == chapters.length &&
      chapters.entries.every((e) => other.chapters[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    upTo,
    Object.hashAllUnordered([
      for (final MapEntry(:key, :value) in chapters.entries)
        Object.hash(key, value),
    ]),
  );

  @override
  String toString() => 'PendingRead(${encode()})';
}
