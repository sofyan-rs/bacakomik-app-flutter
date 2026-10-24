import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/pages/extensions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Health of the active source, from the last load of the screen showing it.
enum SourceStatus { connecting, online, offline, error }

/// `voratoon.co · ● Online` under a source title.
class SourceSubtitle extends StatelessWidget {
  const SourceSubtitle({super.key, required this.source, required this.status});

  final ExtensionMeta? source;
  final SourceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final (label, color) = switch (status) {
      SourceStatus.connecting => (AppText.sourceConnecting, c.inkFaint),
      SourceStatus.online => (AppText.sourceOnline, c.positive),
      SourceStatus.offline => (AppText.sourceOffline, c.inkFaint),
      SourceStatus.error => (AppText.sourceError, c.accentText),
    };
    final style = DotlineText.data.copyWith(color: c.inkFaint);
    if (source == null) return Text(AppText.noSourceShort, style: style);
    return Row(
      children: [
        Flexible(
          child: Text(
            source!.domain,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(' · ', style: style),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: DotSpace.s1),
        Text(label, style: style.copyWith(color: color)),
      ],
    );
  }
}

/// Opens the source picker. The pick applies on its "Open" button.
Future<void> showSourcePicker(BuildContext context) {
  final cubit = context.read<SourcesCubit>();
  return showDotSheet(
    context: context,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const SourcePickerSheet()),
  );
}

/// "Change source": installed sources with a radio each, links to manage
/// and add extensions, and a button that opens the picked source.
class SourcePickerSheet extends StatefulWidget {
  const SourcePickerSheet({super.key});

  @override
  State<SourcePickerSheet> createState() => _SourcePickerSheetState();
}

class _SourcePickerSheetState extends State<SourcePickerSheet> {
  late String? _picked = context.read<SourcesCubit>().state.activeId;

  void _open() {
    final id = _picked;
    if (id != null) context.read<SourcesCubit>().select(id);
    Navigator.of(context).pop();
  }

  void _manage({bool available = false}) {
    Navigator.of(context).pop();
    ExtensionsScreen.open(context, showAvailable: available);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final state = context.watch<SourcesCubit>().state;
    final picked = state.installed.where((e) => e.id == _picked).firstOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppText.changeSource,
                style: DotlineText.title.copyWith(color: c.ink),
              ),
            ),
            Pressable(
              semanticLabel: AppText.manage,
              onTap: _manage,
              child: Padding(
                padding: const EdgeInsets.all(DotSpace.s3),
                child: Text(
                  AppText.manage,
                  style: DotlineText.body.copyWith(color: c.inkMuted),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (state.installed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: DotSpace.s5),
                  child: Text(
                    AppText.noSourceShort,
                    style: DotlineText.body.copyWith(color: c.inkMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final source in state.installed) ...[
                _SourceCard(
                  source: source,
                  selected: source.id == _picked,
                  onTap: () => setState(() => _picked = source.id),
                ),
                const SizedBox(height: DotSpace.s2),
              ],
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.addSource,
          leading: LucideIcons300.plus,
          onTap: () => _manage(available: true),
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton(
          label: picked == null
              ? AppText.openSource
              : '${AppText.openSource} ${picked.name}',
          onTap: picked == null ? null : _open,
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final ExtensionMeta source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Pressable(
      semanticLabel: source.name,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DotSpace.s4,
          vertical: DotSpace.s3,
        ),
        decoration: BoxDecoration(
          color: selected ? c.surfaceRaised : null,
          borderRadius: BorderRadius.circular(DotRadius.m),
          border: Border.all(
            color: selected ? c.surfaceRaised : c.line,
            width: DotSize.stroke,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.name,
                    style: DotlineText.headline.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    extensionLine(source),
                    style: DotlineText.data.copyWith(color: c.inkFaint),
                  ),
                ],
              ),
            ),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// `voratoon.co · ID · v1`.
String extensionLine(ExtensionMeta meta) =>
    '${meta.domain} · ${meta.lang.toUpperCase()} · v${meta.version}';

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.ink : null,
        border: Border.all(color: c.ink, width: DotSize.stroke),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
            )
          : null,
    );
  }
}
