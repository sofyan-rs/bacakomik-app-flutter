import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'chapter_read_event.dart';
part 'chapter_read_state.dart';

class ChapterReadBloc extends Bloc<ChapterReadEvent, ChapterReadState> {
  ChapterReadBloc() : super(ChapterReadInitial()) {
    on<ChapterReadEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
