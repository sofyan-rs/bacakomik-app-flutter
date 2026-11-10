import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/source/extension_meta.dart';

void main() {
  test('the old public repo URL points at the renamed repo', () {
    expect(
      movedRepoUrl(
        'https://sofyan-rs.github.io/bacakomik-ext-public-source/index.json',
      ),
      'https://sofyan-rs.github.io/yoru-ext-public-source/index.json',
    );
  });

  test('other URLs stay as they are', () {
    const url = 'https://bacakomik-ext.kurodev.org/index.json';
    expect(movedRepoUrl(url), url);
    expect(movedRepoUrl(null), isNull);
  });

  test('a stored extension gets the moved repo URL', () {
    final meta = ExtensionMeta.fromJson({
      'id': 'x',
      'name': 'X',
      'version': '1.0.0',
      'file': 'x.v1.0.0.js',
      'sha256': '00',
      'icon': 'icon/x.png',
      'repoUrl':
          'https://sofyan-rs.github.io/bacakomik-ext-public-source/index.json',
    });
    expect(
      meta.iconUrl,
      'https://sofyan-rs.github.io/yoru-ext-public-source/icon/x.png',
    );
  });
}
