import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/features/settings/data/models/settings_model.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings stored by older versions load with reader defaults', () {
    final settings = SettingsModel.fromJson({'darkMode': AppText.dark})
        .toEntity();

    expect(
      settings,
      const AppSettings(
        darkMode: AppText.dark,
        readingDirection: ReadingDirection.vertical,
        pageFit: PageFit.width,
        keepScreenOn: true,
        pageGap: false,
      ),
    );
  });

  test('reader settings round-trip', () {
    const settings = AppSettings(
      darkMode: AppText.light,
      readingDirection: ReadingDirection.rightToLeft,
      pageFit: PageFit.height,
      keepScreenOn: false,
      pageGap: true,
    );
    final json = SettingsModel.fromEntity(settings).toJson();

    expect(json['darkMode'], AppText.light);
    expect(SettingsModel.fromJson(json).toEntity(), settings);
  });

  test('unknown enum values from a newer version fall back', () {
    final settings = SettingsModel.fromJson({
      'darkMode': AppText.system,
      'readingDirection': 'diagonal',
      'pageFit': 'stretch',
    }).toEntity();

    expect(settings.readingDirection, ReadingDirection.vertical);
    expect(settings.pageFit, PageFit.width);
  });
}
