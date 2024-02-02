import 'package:bacakomik_app/core/utils/connectivity_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/core/models/chapter_read_model.dart';
import 'package:bacakomik_app/data/repository/chapter_read_repository.dart';

part 'chapter_read_event.dart';
part 'chapter_read_state.dart';

class ChapterReadBloc extends Bloc<ChapterReadEvent, ChapterReadState> {
  final ChapterReadRepository chapterReadRepository;
  final _connectivityCheck = ConnectivityCheck();

  ChapterReadBloc(
    this.chapterReadRepository,
  ) : super(ChapterReadInitial()) {
    on<ChapterReadEvent>(_getChapterRead);
  }

  @override
  void onChange(Change<ChapterReadState> change) {
    print(change);
    super.onChange(change);
  }

  @override
  void onTransition(Transition<ChapterReadEvent, ChapterReadState> transition) {
    print(transition);
    super.onTransition(transition);
  }

  void _getChapterRead(
    ChapterReadEvent event,
    Emitter<ChapterReadState> emit,
  ) async {
    bool isConnected = await _connectivityCheck.checkStatus();
    if (!isConnected) {
      emit(NoInternet());
      return;
    }
    emit(ChapterReadLoading());
    try {
      final slug = (event as GetChapterRead).slug;
      final chapterRead = await chapterReadRepository.getChapterRead(slug);
      emit(ChapterReadLoaded(chapterRead: chapterRead));
    } catch (e) {
      emit(ChapterReadError(message: e.toString()));
    }
  }
}
