import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/comic_detail/domain/usecases/get_comic_details.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'comic_details_bloc.freezed.dart';

/// [stored]: the library's copy, shown as is without a request (a
/// bookmarked comic opens from its bookmark; pull-to-refresh fetches).
final class ComicDetailsRequested {
  const ComicDetailsRequested(this.slug, {this.stored});

  final String slug;
  final ComicDetails? stored;
}

@freezed
sealed class ComicDetailsState with _$ComicDetailsState {
  const factory ComicDetailsState.initial() = ComicDetailsInitial;
  const factory ComicDetailsState.loading() = ComicDetailsLoading;

  /// [chaptersLoading]: the details came first; the chapter list is still
  /// loading ([comicDetails] has none yet). [stored]: [comicDetails] is the
  /// library's copy, not loaded from the source (asked for, or the request
  /// failed).
  const factory ComicDetailsState.loaded({
    required ComicDetails comicDetails,
    @Default(false) bool chaptersLoading,
    @Default(false) bool stored,
  }) = ComicDetailsLoaded;
  const factory ComicDetailsState.error({required String message}) =
      ComicDetailsError;
  const factory ComicDetailsState.noInternet() = ComicDetailsNoInternet;
}

@injectable
class ComicDetailsBloc extends Bloc<ComicDetailsRequested, ComicDetailsState> {
  ComicDetailsBloc(this._getComicDetails)
    : super(const ComicDetailsState.initial()) {
    on<ComicDetailsRequested>(_onRequested);
  }

  final GetComicDetails _getComicDetails;

  Future<void> _onRequested(
    ComicDetailsRequested event,
    Emitter<ComicDetailsState> emit,
  ) async {
    if (event.stored case final stored?) {
      return emit(ComicDetailsState.loaded(comicDetails: stored, stored: true));
    }
    emit(const ComicDetailsState.loading());
    final result = await _getComicDetails(
      event.slug,
      onSeries: (details) {
        if (!emit.isDone) {
          emit(
            ComicDetailsState.loaded(
              comicDetails: details,
              chaptersLoading: true,
            ),
          );
        }
      },
    );
    emit(
      result.fold(
        (failure) => switch (failure) {
          NetworkFailure() => const ComicDetailsState.noInternet(),
          _ => ComicDetailsState.error(message: failure.message),
        },
        (loaded) => ComicDetailsState.loaded(
          comicDetails: loaded.details,
          stored: loaded.stored,
        ),
      ),
    );
  }
}
