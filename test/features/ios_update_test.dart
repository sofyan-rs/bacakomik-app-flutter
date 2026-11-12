import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/features/update/data/datasources/app_installer.dart';
import 'package:yoru/features/update/domain/entities/app_release.dart';
import 'package:yoru/features/update/domain/entities/update_progress.dart';

void main() {
  const asset = ReleaseAsset(
    name: 'Yoru-2.22.0-ios.ipa',
    url: 'https://github.com/o/r/releases/download/v2.22.0/Yoru-2.22.0-ios.ipa',
  );

  IosAppInstaller installer({
    Set<String> installed = const {},
    bool opens = true,
    required List<Uri> launched,
  }) => IosAppInstaller(
    canLaunch: (uri) async => installed.contains(uri.scheme),
    launch: (uri) async {
      launched.add(uri);
      return opens;
    },
  );

  test('takes the iOS IPA', () async {
    expect(await IosAppInstaller().assetSuffixes(), ['ios.ipa']);
  });

  test('hands the IPA to AltStore when it is installed', () async {
    final launched = <Uri>[];
    final progress = await installer(
      installed: {'altstore', 'sidestore'},
      launched: launched,
    ).install(asset).toList();
    expect(
      launched.single.toString(),
      'altstore://install?url=${Uri.encodeQueryComponent(asset.url)}',
    );
    expect(progress.single, isA<UpdateInstalling>());
  });

  test('falls back to SideStore, then to the IPA itself', () async {
    final viaSideStore = <Uri>[];
    await installer(
      installed: {'sidestore'},
      launched: viaSideStore,
    ).install(asset).toList();
    expect(viaSideStore.single.scheme, 'sidestore');

    final direct = <Uri>[];
    await installer(launched: direct).install(asset).toList();
    expect(direct.single.toString(), asset.url);
  });

  test('fails when nothing opens it', () async {
    final progress = await installer(
      opens: false,
      launched: [],
    ).install(asset).toList();
    expect(progress.single, isA<UpdateInstallFailed>());
  });
}
