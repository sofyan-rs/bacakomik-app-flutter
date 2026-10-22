import 'package:bacakomik_app/core/constants/filters.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/explore/domain/usecases/get_genres.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Genre options of the filter sheet. Starts with the bundled
/// [Filters.genreList] and swaps in GET /genres once, on app start; a failed
/// or empty fetch keeps the bundled list.
@injectable
class GenresCubit extends Cubit<List<FilterOption>> {
  GenresCubit(this._getGenres) : super(Filters.genreList);

  final GetGenres _getGenres;

  Future<void> load() async {
    final result = await _getGenres(const NoParams());
    result.fold(
      (failure) => debugPrint('GenresCubit: $failure'),
      (genres) {
        if (genres.isEmpty) return;
        emit([
          for (final g in genres) FilterOption(id: g.slug, name: g.name),
        ]);
      },
    );
  }
}
