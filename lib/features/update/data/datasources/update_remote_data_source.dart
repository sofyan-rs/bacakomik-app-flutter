import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/network/api_client.dart';
import 'package:bacakomik_app/features/update/data/models/github_release_model.dart';
import 'package:injectable/injectable.dart';

abstract interface class UpdateRemoteDataSource {
  Future<GitHubReleaseModel> latestRelease();
}

@LazySingleton(as: UpdateRemoteDataSource)
class UpdateRemoteDataSourceImpl implements UpdateRemoteDataSource {
  const UpdateRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<GitHubReleaseModel> latestRelease() async =>
      GitHubReleaseModel.fromJson(
        await _client.get(AppVariables.latestReleaseApi),
      );
}
