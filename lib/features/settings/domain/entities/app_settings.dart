import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// One of [AppText.system], [AppText.light] or [AppText.dark].
    @Default(AppText.system) String darkMode,
  }) = _AppSettings;
}
