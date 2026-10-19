import 'package:bacakomik_app/features/settings/data/models/settings_model.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing fields fall back to the defaults', () {
    expect(SettingsModel.fromJson({}).toEntity(), const AppSettings());
  });

  test('settings round-trip', () {
    const settings = AppSettings(
      themeMode: AppThemeMode.dark,
      readingDirection: ReadingDirection.rightToLeft,
      pageFit: PageFit.height,
      keepScreenOn: false,
      pageGap: true,
    );
    final json = SettingsModel.fromEntity(settings).toJson();

    expect(json['themeMode'], 'dark');
    expect(SettingsModel.fromJson(json).toEntity(), settings);
  });

  test('unknown enum values fall back', () {
    final settings = SettingsModel.fromJson({
      'themeMode': 'sepia',
      'readingDirection': 'diagonal',
      'pageFit': 'stretch',
    }).toEntity();

    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.readingDirection, ReadingDirection.vertical);
    expect(settings.pageFit, PageFit.width);
  });
}
