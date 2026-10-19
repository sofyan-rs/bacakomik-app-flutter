part of 'home_bloc.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({
    required Home home,
    @Default(false) bool isRefetch,
  }) = HomeLoaded;
  const factory HomeState.error({required String message}) = HomeError;
  const factory HomeState.noInternet() = HomeNoInternet;
}
