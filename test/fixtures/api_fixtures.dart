/// Sample bacakomik-api responses used by characterization tests.
const seriesListItem = <String, dynamic>{
  'title': 'Solo Leveling',
  'cover': 'https://cdn.example/solo.jpg',
  'slug': 'solo-leveling',
  'format': 'manhwa',
  'status': 'completed',
  'rating': 9.25,
  'totalChapters': 200,
};

const seriesListItemNulls = <String, dynamic>{
  'title': 'Unknown',
  'cover': null,
  'slug': 'unknown',
  'format': null,
  'status': 'ongoing',
  'rating': null,
  'totalChapters': null,
};

Map<String, dynamic> listResponse(List<Map<String, dynamic>> items) =>
    {'data': items};

const seriesDetail = <String, dynamic>{
  'title': 'Solo Leveling',
  'cover': 'https://cdn.example/solo.jpg',
  'slug': 'solo-leveling',
  'nativeTitle': null,
  'releaseDate': '2018',
  'status': 'completed',
  'author': 'Chugong',
  'format': 'manhwa',
  'rating': 9,
  'synopsis': '  Hunter story.  ',
  'genres': [
    {'id': 1, 'name': 'Action'},
    {'id': 7, 'name': 'Fantasy'},
  ],
};

const chapterList = <dynamic>[
  {'number': 2, 'createdAt': null},
  {'number': 1.5, 'createdAt': null},
];

const chapterDetail = <String, dynamic>{
  'number': 2,
  'title': null,
  'prev': 1.5,
  'next': null,
  'images': ['https://cdn.example/1.jpg', 'https://cdn.example/2.jpg'],
};
