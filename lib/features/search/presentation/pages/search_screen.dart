import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/search/presentation/bloc/search_bloc.dart';
import 'package:bacakomik_app/features/search/presentation/widgets/search_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Search, laid out like Jelajah: back button + search pill, then the same
/// cover grid.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _input = TextEditingController();
  final _resultKey = GlobalKey<SearchResultState>();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _search() {
    final keyword = _input.text.trim();
    if (keyword.isEmpty) return;
    _resultKey.currentState?.resetPaging();
    context.read<SearchBloc>().add(SearchRequested(keyword: keyword));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DotSpace.s4,
                DotSpace.s2,
                DotSpace.s4,
                DotSpace.s4,
              ),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: LucideIcons300.chevronLeft,
                    semanticLabel: 'Kembali',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: DotSpace.s3),
                  Expanded(
                    child: SearchField(
                      hint: AppText.exploreSearchHint,
                      controller: _input,
                      autofocus: true,
                      onSubmitted: (_) => _search(),
                      onClear: _input.clear,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SearchResult(
                key: _resultKey,
                keyword: () => _input.text.trim(),
                onRefresh: _search,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
