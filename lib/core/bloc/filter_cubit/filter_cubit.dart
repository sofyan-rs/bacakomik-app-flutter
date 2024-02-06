import 'package:flutter_bloc/flutter_bloc.dart';

part 'filter_state.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit()
      : super(
          FilterState(
            sortBy: 'update',
            type: 'all',
            status: 'all',
            genres: [],
          ),
        );

  void setFilter({
    required String sortBy,
    required String type,
    required String status,
    required List<String> genres,
  }) {
    emit(
      FilterState(
        sortBy: sortBy,
        type: type,
        status: status,
        genres: genres,
      ),
    );
  }
}
