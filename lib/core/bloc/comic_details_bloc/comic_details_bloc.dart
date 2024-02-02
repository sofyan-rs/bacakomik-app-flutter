import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/utils/connectivity_check.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'comic_details_event.dart';
part 'comic_details_state.dart';

class ComicDetailsBloc extends Bloc<ComicDetailsEvent, ComicDetailsState> {
  final ComicDetailsRepository comicDetailsRepository;
  final _connectivityCheck = ConnectivityCheck();

  ComicDetailsBloc(
    this.comicDetailsRepository,
  ) : super(ComicDetailsInitial()) {
    on<GetComicDetails>(_getComicDetails);
  }

  @override
  void onChange(Change<ComicDetailsState> change) {
    print(change);
    super.onChange(change);
  }

  @override
  void onTransition(
      Transition<ComicDetailsEvent, ComicDetailsState> transition) {
    print(transition);
    super.onTransition(transition);
  }

  void _getComicDetails(
    ComicDetailsEvent event,
    Emitter<ComicDetailsState> emit,
  ) async {
    bool isConnected = await _connectivityCheck.checkStatus();
    if (!isConnected) {
      emit(NoInternet());
      return;
    }
    emit(ComicDetailsLoading());
    try {
      final slug = (event as GetComicDetails).slug;
      final comicDetails = await comicDetailsRepository.getComicDetails(slug);
      emit(ComicDetailsLoaded(comicDetails: comicDetails));
    } catch (e) {
      emit(ComicDetailsError(message: e.toString()));
    }
  }
}
