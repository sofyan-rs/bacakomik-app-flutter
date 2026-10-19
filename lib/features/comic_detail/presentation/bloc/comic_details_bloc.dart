import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/comic_detail/domain/usecases/get_comic_details.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'comic_details_bloc.freezed.dart';

final class ComicDetailsRequested {
  const ComicDetailsRequested(this.slug);

  final String slug;
}

@freezed
sealed class ComicDetailsState with _$ComicDetailsState {
  const factory ComicDetailsState.initial() = ComicDetailsInitial;
  const factory ComicDetailsState.loading() = ComicDetailsLoading;
  const factory ComicDetailsState.loaded({
    required ComicDetails comicDetails,
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
    emit(const ComicDetailsState.loading());
    final result = await _getComicDetails(event.slug);
    emit(result.fold(
      (failure) => switch (failure) {
        NetworkFailure() => const ComicDetailsState.noInternet(),
        _ => ComicDetailsState.error(message: failure.message),
      },
      (details) => ComicDetailsState.loaded(comicDetails: details),
    ));
  }
}
