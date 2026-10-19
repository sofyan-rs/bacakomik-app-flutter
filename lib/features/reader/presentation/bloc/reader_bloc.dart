import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/domain/usecases/get_chapter_content.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'reader_bloc.freezed.dart';

final class ChapterRequested {
  const ChapterRequested(this.slug);

  final String slug;
}

@freezed
sealed class ReaderState with _$ReaderState {
  const factory ReaderState.initial() = ReaderInitial;
  const factory ReaderState.loading() = ReaderLoading;
  const factory ReaderState.loaded({required ChapterContent chapter}) =
      ReaderLoaded;
  const factory ReaderState.error({required String message}) = ReaderError;
  const factory ReaderState.noInternet() = ReaderNoInternet;
}

@injectable
class ReaderBloc extends Bloc<ChapterRequested, ReaderState> {
  ReaderBloc(this._getChapter) : super(const ReaderState.initial()) {
    on<ChapterRequested>(_onRequested);
  }

  final GetChapterContent _getChapter;

  Future<void> _onRequested(
    ChapterRequested event,
    Emitter<ReaderState> emit,
  ) async {
    emit(const ReaderState.loading());
    final result = await _getChapter(event.slug);
    emit(result.fold(
      (failure) => switch (failure) {
        NetworkFailure() => const ReaderState.noInternet(),
        _ => ReaderState.error(message: failure.message),
      },
      (chapter) => ReaderState.loaded(chapter: chapter),
    ));
  }
}
