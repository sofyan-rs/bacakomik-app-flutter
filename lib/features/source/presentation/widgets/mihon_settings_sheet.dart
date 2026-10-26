import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/mihon_source.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Settings of a Mihon extension's sources (`ConfigurableSource`): a
/// mirror, image quality, a language… An extension with several sources
/// asks which one first.
Future<void> showMihonSettings(
  BuildContext context,
  ExtensionMeta extension,
) async {
  final configurable = {
    for (final s in extension.mihonSources)
      if (s.configurable) '${ExtensionMeta.mihonPrefix}${s.id}',
  };
  final sources = [
    for (final s in getIt<ExtensionManager>().knownSources)
      if (s.extensionId == extension.id && configurable.contains(s.id)) s,
  ];
  if (sources.isEmpty) return;
  final source = sources.length == 1
      ? sources.single
      : await showDotSheet<ExtensionMeta>(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ActionSheetHeader(
                icon: LucideIcons300.settings2,
                title: '${extension.name} · ${AppText.sourceSettings}',
              ),
              const SizedBox(height: DotSpace.s4),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListGroup(
                      background: Dotline.of(context).bg,
                      children: [
                        for (final s in sources)
                          ListRow(
                            title: s.name,
                            subtitle: s.lang.toUpperCase(),
                            onTap: () => Navigator.of(context).pop(s),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  if (source == null || !context.mounted) return;
  await showDotSheet<void>(
    context: context,
    builder: (_) => _SettingsSheet(source: source),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.source});

  final ExtensionMeta source;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  MihonSource? _backend;
  List<_Pref>? _prefs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Fresh each time: a change reloads the extension (see _set).
      final backend = _backend = await getIt<ExtensionManager>().mihonSource(
        widget.source.id,
      );
      final prefs = await backend?.preferences() ?? const [];
      if (!mounted) return;
      setState(() {
        _prefs = [for (final p in prefs) _Pref(p)];
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _set(_Pref pref, Object? value) async {
    try {
      await _backend!.setPreference(pref.key, value);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      return;
    }
    // Every source of the extension, not just this one, reads its settings
    // again, and the filters shown are refreshed.
    getIt<ExtensionManager>().reload(widget.source.extensionId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final prefs = _prefs;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.settings2,
          title: '${widget.source.name} · ${AppText.sourceSettings}',
          subtitle: AppText.sourceSettingsHint,
        ),
        const SizedBox(height: DotSpace.s4),
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.only(bottom: DotSpace.s3),
            child: Text(
              error,
              style: DotlineText.bodyS.copyWith(color: c.accentText),
            ),
          ),
        if (prefs == null && _error == null)
          const Padding(
            padding: EdgeInsets.all(DotSpace.s6),
            child: Center(child: DotLoader()),
          )
        else if (prefs != null && prefs.isEmpty)
          Text(
            AppText.noSourceSettings,
            style: DotlineText.body.copyWith(color: c.inkMuted),
          )
        else if (prefs != null)
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListGroup(
                  background: Dotline.of(context).bg,
                  children: [for (final p in prefs) _row(p)],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _row(_Pref p) {
    final onTap = p.enabled ? () => _edit(p) : null;
    return switch (p.type) {
      'switch' => ListRow(
        title: p.title,
        subtitle: p.summary,
        onTap: p.enabled ? () => _set(p, !(p.value == true)) : null,
        trailing: DotSwitch(
          value: p.value == true,
          semanticLabel: p.title,
          onChanged: p.enabled ? (on) => _set(p, on) : null,
        ),
      ),
      'list' => ListRow(
        title: p.title,
        subtitle: p.summaryWith(p.labelOf('${p.value}')),
        onTap: onTap,
      ),
      'multiselect' => ListRow(
        title: p.title,
        subtitle: p.summaryWith(
          [for (final v in p.selected) p.labelOf(v)].join(', '),
        ),
        onTap: onTap,
      ),
      'text' => ListRow(
        title: p.title,
        subtitle: p.summaryWith('${p.value ?? ''}'),
        onTap: onTap,
      ),
      _ => ListRow(title: p.title, subtitle: p.summary),
    };
  }

  Future<void> _edit(_Pref p) async {
    final value = await showDotSheet<Object>(
      context: context,
      builder: (_) => switch (p.type) {
        'list' => _ListPicker(pref: p),
        'multiselect' => _MultiPicker(pref: p),
        _ => _TextEditor(pref: p),
      },
    );
    if (value != null) await _set(p, value);
  }
}

/// One preference as the host describes it.
class _Pref {
  _Pref(this.json);

  final Map<String, Object?> json;

  String get key => '${json['key']}';
  String get type => '${json['type']}';
  String get title => '${json['title'] ?? key}';
  String? get summary => json['summary'] as String?;
  bool get enabled => json['enabled'] != false;
  Object? get value => json['value'];

  List<String> get entries => [
    for (final e in (json['entries'] as List?) ?? const []) '$e',
  ];
  List<String> get values => [
    for (final v in (json['values'] as List?) ?? const []) '$v',
  ];
  List<String> get selected => [
    for (final v in value is List ? value as List : const []) '$v',
  ];

  String labelOf(String v) {
    final i = values.indexOf(v);
    return i >= 0 && i < entries.length ? entries[i] : v;
  }

  /// Android fills `%s` in a summary with the current value; without a
  /// summary the value is the subtitle.
  String? summaryWith(String current) {
    final s = summary;
    if (s == null || s.isEmpty) return current.isEmpty ? null : current;
    return s.contains('%s') ? s.replaceAll('%s', current) : s;
  }
}

class _ListPicker extends StatelessWidget {
  const _ListPicker({required this.pref});

  final _Pref pref;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(title: pref.title),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListGroup(
                background: Dotline.of(context).bg,
                children: [
                  for (final (i, v) in pref.values.indexed)
                    ListRow(
                      title: i < pref.entries.length ? pref.entries[i] : v,
                      trailing: '${pref.value}' == v
                          ? Icon(LucideIcons300.check, color: c.ink)
                          : null,
                      onTap: () => Navigator.of(context).pop(v),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiPicker extends StatefulWidget {
  const _MultiPicker({required this.pref});

  final _Pref pref;

  @override
  State<_MultiPicker> createState() => _MultiPickerState();
}

class _MultiPickerState extends State<_MultiPicker> {
  late final _on = {...widget.pref.selected};

  @override
  Widget build(BuildContext context) {
    final p = widget.pref;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(title: p.title),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListGroup(
                background: Dotline.of(context).bg,
                children: [
                  for (final (i, v) in p.values.indexed)
                    ListRow(
                      title: i < p.entries.length ? p.entries[i] : v,
                      onTap: () => setState(
                        () => _on.contains(v) ? _on.remove(v) : _on.add(v),
                      ),
                      trailing: DotSwitch(
                        value: _on.contains(v),
                        semanticLabel: v,
                        onChanged: (on) =>
                            setState(() => on ? _on.add(v) : _on.remove(v)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s4),
        DotButton(
          label: AppText.save,
          onTap: () => Navigator.of(context).pop([
            for (final v in p.values)
              if (_on.contains(v)) v,
          ]),
        ),
      ],
    );
  }
}

class _TextEditor extends StatefulWidget {
  const _TextEditor({required this.pref});

  final _Pref pref;

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final _text = TextEditingController(text: '${widget.pref.value ?? ''}');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(title: widget.pref.title),
        const SizedBox(height: DotSpace.s4),
        TextField(
          controller: _text,
          autofocus: true,
          autocorrect: false,
          style: DotlineText.body.copyWith(color: c.ink),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        const SizedBox(height: DotSpace.s4),
        DotButton(
          label: AppText.save,
          onTap: () => Navigator.of(context).pop(_text.text),
        ),
      ],
    );
  }
}
