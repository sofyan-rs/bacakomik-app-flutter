import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/migration/presentation/bloc/match_cubit.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// What the user chose in [showMatchSearchSheet]: a comic, or none to skip.
class MatchPick {
  const MatchPick(this.comic);

  final Comic? comic;
}

/// Searches the target source of [cubit], starting with [title], and lets
/// the user pick the match or skip. Null when dismissed.
Future<MatchPick?> showMatchSearchSheet(
  BuildContext context, {
  required MatchCubit cubit,
  required String title,
}) => showDotSheet<MatchPick>(
  context: context,
  builder: (_) => _MatchSearchSheet(cubit: cubit, title: title),
);

class _MatchSearchSheet extends StatefulWidget {
  const _MatchSearchSheet({required this.cubit, required this.title});

  final MatchCubit cubit;
  final String title;

  @override
  State<_MatchSearchSheet> createState() => _MatchSearchSheetState();
}

class _MatchSearchSheetState extends State<_MatchSearchSheet> {
  late final _query = TextEditingController(text: widget.title);
  List<Comic> _results = const [];
  String? _error;
  var _loading = false;

  /// Counts searches so an older one cannot overwrite a newer one.
  var _run = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) return;
    final run = ++_run;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.cubit.search(query);
    if (!mounted || run != _run) return;
    setState(() {
      _loading = false;
      result.fold((failure) {
        _error = failure.message;
        _results = const [];
      }, (comics) => _results = comics);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionSheetHeader(
            icon: LucideIcons300.search,
            title: AppText.pickMatch,
            subtitle: widget.title,
          ),
          const SizedBox(height: DotSpace.s4),
          SearchField(
            hint: AppText.searchHint,
            controller: _query,
            onSubmitted: (_) => _search(),
            onClear: _query.clear,
          ),
          const SizedBox(height: DotSpace.s3),
          Expanded(
            child: _loading
                ? const Center(child: DotLoader())
                : _error != null || _results.isEmpty
                ? Center(
                    child: Text(
                      _error ?? AppText.noResults,
                      style: DotlineText.body.copyWith(color: c.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, i) {
                      final comic = _results[i];
                      return ListRow(
                        leading: SizedBox(
                          width: 40,
                          child: ComicCover(imageUrl: comic.coverImg),
                        ),
                        title: comic.title,
                        subtitle: comic.latestChapter.isEmpty
                            ? null
                            : 'Ch. ${comic.latestChapter}',
                        onTap: () =>
                            Navigator.of(context).pop(MatchPick(comic)),
                      );
                    },
                  ),
          ),
          const SizedBox(height: DotSpace.s3),
          DotButton.outline(
            label: AppText.skip,
            onTap: () => Navigator.of(context).pop(const MatchPick(null)),
          ),
        ],
      ),
    );
  }
}
