import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

/// Installs an empty in-memory [HydratedBloc.storage] for cubit tests.
void mockHydratedStorage() {
  final storage = MockStorage();
  when(() => storage.read(any())).thenReturn(null);
  when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
  HydratedBloc.storage = storage;
}
