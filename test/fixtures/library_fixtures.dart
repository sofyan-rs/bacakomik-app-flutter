import 'package:bacakomik_app/core/domain/entities/comic_details.dart';

/// A small comic used by library, history and backup tests.
const sampleComicDetails = ComicDetails(
  title: 'Solo Leveling',
  coverImg: 'https://cdn.example/solo.jpg',
  alternativeTitle: '-',
  released: '2018',
  status: 'Completed',
  totalChapter: '2',
  author: 'Chugong',
  type: 'Manhwa',
  rating: '9',
  synopsis: 'Hunter story.',
  genres: [Genre(name: 'Action', slug: '1')],
  chapters: [
    Chapter(number: '2', slug: 'solo-leveling/2', date: '-'),
    Chapter(number: '1', slug: 'solo-leveling/1', date: '-'),
  ],
);
