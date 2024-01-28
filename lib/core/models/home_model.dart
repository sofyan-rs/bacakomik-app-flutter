import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bacakomik_app/core/models/latest_model.dart';
import 'package:bacakomik_app/core/models/popular_model.dart';

class HomeModel {
  final List<PopularModel> popular;
  final List<LatestModel> latest;
  HomeModel({
    required this.popular,
    required this.latest,
  });

  HomeModel copyWith({
    List<PopularModel>? popular,
    List<LatestModel>? latest,
  }) {
    return HomeModel(
      popular: popular ?? this.popular,
      latest: latest ?? this.latest,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'popular': popular.map((x) => x.toMap()).toList(),
      'latest': latest.map((x) => x.toMap()).toList(),
    };
  }

  factory HomeModel.fromMap(Map<String, dynamic> map) {
    return HomeModel(
      popular: List<PopularModel>.from(
        (map['popular'] as List<dynamic>).map<PopularModel>(
          (x) => PopularModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      latest: List<LatestModel>.from(
        (map['latest'] as List<dynamic>).map<LatestModel>(
          (x) => LatestModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory HomeModel.fromJson(String source) =>
      HomeModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'HomeModel(popular: $popular, latest: $latest)';

  @override
  bool operator ==(covariant HomeModel other) {
    if (identical(this, other)) return true;

    return listEquals(other.popular, popular) &&
        listEquals(other.latest, latest);
  }

  @override
  int get hashCode => popular.hashCode ^ latest.hashCode;
}
