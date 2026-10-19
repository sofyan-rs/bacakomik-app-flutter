import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class FilterCubit extends Cubit<ExploreFilter> {
  FilterCubit() : super(const ExploreFilter());

  void setFilter({
    required String sortBy,
    required String type,
    required String status,
    required List<String> genres,
  }) {
    emit(ExploreFilter(
      sortBy: sortBy,
      type: type,
      status: status,
      genres: genres,
    ));
  }
}
