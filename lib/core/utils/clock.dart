import 'package:injectable/injectable.dart';

/// Current time source, injectable so tests can pin "now".
@lazySingleton
class Clock {
  DateTime now() => DateTime.now();
}
